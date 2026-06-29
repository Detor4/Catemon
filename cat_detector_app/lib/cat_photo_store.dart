import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'cat_grade.dart';
import 'cat_upgrade.dart';

class CatPhoto {
  const CatPhoto({
    required this.path,
    this.grade,
  });

  final String path;
  final CatGrade? grade;

  CatPhoto copyWith({CatGrade? grade}) {
    return CatPhoto(path: path, grade: grade ?? this.grade);
  }
}

class CatPhotoStore extends ChangeNotifier {
  CatPhotoStore._();

  static final CatPhotoStore instance = CatPhotoStore._();

  static const _subdir = 'cat_gallery';
  static const _metaFile = 'grades.json';

  List<CatPhoto> _photos = [];
  Map<String, CatGrade> _grades = {};

  List<CatPhoto> get photos => List.unmodifiable(_photos);

  int get count => _photos.length;

  CatGrade? gradeFor(String path) => _grades[path];

  Future<void> load() async {
    final dir = await _galleryDir();
    await _loadGrades(dir);

    if (!await dir.exists()) {
      await dir.create(recursive: true);
      _photos = [];
      notifyListeners();
      return;
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .where((file) => _isImage(file.path))
        .toList()
      ..sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );

    _photos = files
        .map(
          (file) => CatPhoto(
            path: file.path,
            grade: _grades[file.path],
          ),
        )
        .toList();

    await _backfillMissingGrades();
    notifyListeners();
  }

  Future<CatPhoto> saveCutoutBytes(
    Uint8List pngBytes, {
    required CatGrade grade,
  }) async {
    final dir = await _galleryDir();
    await dir.create(recursive: true);

    final name = 'cat_${DateTime.now().millisecondsSinceEpoch}.png';
    final dest = File('${dir.path}/$name');
    await dest.writeAsBytes(pngBytes, flush: true);

    _grades[dest.path] = grade;
    await _saveGrades(dir);

    final photo = CatPhoto(path: dest.path, grade: grade);
    _photos.insert(0, photo);
    notifyListeners();
    return photo;
  }

  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    _grades.remove(path);
    _photos.removeWhere((photo) => photo.path == path);
    await _saveGrades(await _galleryDir());
    notifyListeners();
  }

  int countAtLevel(int level) {
    return _photos.where((p) => p.grade?.level == level).length;
  }

  List<CatPhoto> photosAtLevel(int level) {
    return _photos.where((p) => p.grade?.level == level).toList();
  }

  /// Tanlangan mushukni qurbanlar yordamida keyingi darajaga ko'taradi.
  /// [targetPath] saqlanadi va yangi daraja beriladi; qurbanlar o'chiriladi.
  Future<CatPhoto> upgrade({
    required String targetPath,
    required List<String> sacrificePaths,
    required CatUpgradeRule rule,
  }) async {
    if (sacrificePaths.contains(targetPath)) {
      throw StateError('Asosiy mushuk qurban sifatida ishlatilmaydi');
    }
    if (sacrificePaths.length != rule.requiredCount) {
      throw StateError(
        '${rule.requiredCount} ta qurban (${rule.fromTier.rarity}) kerak',
      );
    }

    final target = _photos.firstWhere(
      (p) => p.path == targetPath,
      orElse: () => throw StateError('Asosiy mushuk topilmadi'),
    );
    if (target.grade?.level != rule.fromLevel) {
      throw StateError(
        'Asosiy mushuk ${rule.fromTier.rarity} bo\'lishi kerak',
      );
    }

    for (final path in sacrificePaths) {
      final photo = _photos.firstWhere(
        (p) => p.path == path,
        orElse: () => throw StateError('Qurban mushuk topilmadi'),
      );
      if (photo.grade?.level != rule.fromLevel) {
        throw StateError(
          'Barcha qurbanlar ${rule.fromTier.rarity} bo\'lishi kerak',
        );
      }
    }

    for (final path in sacrificePaths) {
      final file = File(path);
      if (await file.exists()) await file.delete();
      _grades.remove(path);
      _photos.removeWhere((p) => p.path == path);
    }

    final targetGrade = target.grade!;
    final newGrade = CatGrade(
      tier: rule.toTier,
      qualityScore: targetGrade.qualityScore,
      confidenceScore: targetGrade.confidenceScore,
      colorKey: CatUpgradeCatalog.colorKeyForLevel(rule.toLevel),
    );

    _grades[targetPath] = newGrade;
    final idx = _photos.indexWhere((p) => p.path == targetPath);
    if (idx >= 0) {
      _photos[idx] = CatPhoto(path: targetPath, grade: newGrade);
    }

    await _saveGrades(await _galleryDir());
    notifyListeners();
    return _photos.firstWhere((p) => p.path == targetPath);
  }

  Future<void> _backfillMissingGrades() async {
    var changed = false;
    for (var i = 0; i < _photos.length; i++) {
      final photo = _photos[i];
      if (photo.grade != null) continue;

      final bytes = await File(photo.path).readAsBytes();
      final grade = CatGrader.gradeFromBytes(
        Uint8List.fromList(bytes),
        confidence: 0.85,
      );
      _grades[photo.path] = grade;
      _photos[i] = photo.copyWith(grade: grade);
      changed = true;
    }
    if (changed) {
      await _saveGrades(await _galleryDir());
    }
  }

  Future<void> _loadGrades(Directory dir) async {
    _grades = {};
    final meta = File('${dir.path}/$_metaFile');
    if (!await meta.exists()) return;

    try {
      final raw = jsonDecode(await meta.readAsString()) as Map<String, dynamic>;
      raw.forEach((path, value) {
        if (value is Map<String, dynamic>) {
          _grades[path] = CatGrade.fromJson(value);
        }
      });
    } catch (_) {
      _grades = {};
    }
  }

  Future<void> _saveGrades(Directory dir) async {
    final meta = File('${dir.path}/$_metaFile');
    final payload = _grades.map((path, grade) => MapEntry(path, grade.toJson()));
    await meta.writeAsString(jsonEncode(payload));
  }

  Future<Directory> _galleryDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/$_subdir');
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }
}
