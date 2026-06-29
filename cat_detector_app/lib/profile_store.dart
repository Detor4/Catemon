import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'achievements.dart';
import 'app_strings.dart';
import 'cat_photo_store.dart';

/// Profil statistikasi — mushuklar kolleksiyasidan hisoblanadi.
class ProfileStats {
  const ProfileStats({
    required this.totalCats,
    required this.countsByLevel,
    required this.totalPower,
    required this.level,
    required this.levelProgress,
    required this.powerInLevel,
    required this.powerForNextLevel,
    required this.streak,
    required this.bestStreak,
  });

  final int totalCats;
  final Map<int, int> countsByLevel;
  final int totalPower;
  final int level;
  final double levelProgress; // 0..1
  final int powerInLevel;
  final int powerForNextLevel;
  final int streak;
  final int bestStreak;

  int countAtLevel(int lvl) => countsByLevel[lvl] ?? 0;

  int get legendaryCount => countAtLevel(6);
  int get mythicCount => countAtLevel(7);
}

class ProfileStore extends ChangeNotifier {
  ProfileStore._();

  static final ProfileStore instance = ProfileStore._();

  static const _fileName = 'profile.json';

  // Persisted holatlar
  String _name = 'Player';
  String? _avatarPath;
  String? _showcaseCatPath;
  AppLang _lang = AppLang.uz;
  int _streak = 0;
  int _bestStreak = 0;
  String? _lastLoginYmd;
  final Set<String> _earnedAchievements = {};
  String? _activeTitleId;

  bool _loaded = false;

  // ── Getterlar ──
  String get name => _name;
  String? get avatarPath => _avatarPath;
  String? get showcaseCatPath => _showcaseCatPath;
  AppLang get lang => _lang;
  int get streak => _streak;
  int get bestStreak => _bestStreak;
  Set<String> get earnedAchievements => Set.unmodifiable(_earnedAchievements);
  String? get activeTitleId => _activeTitleId;

  /// Daraja kuchi: yuqori rarity ko'proq ball beradi.
  /// 1 ta Legendary (60) > 3 ta Epic (48).
  static const Map<int, int> powerPerLevel = {
    1: 1, // Common
    2: 2, // Common+
    3: 4, // Uncommon
    4: 8, // Rare
    5: 16, // Epic
    6: 60, // Legendary
    7: 150, // Mythic
  };

  ProfileStats get stats => _computeStats();

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    try {
      final file = await _file();
      if (await file.exists()) {
        final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        _name = raw['name'] as String? ?? 'Player';
        _avatarPath = raw['avatarPath'] as String?;
        _showcaseCatPath = raw['showcaseCatPath'] as String?;
        _lang = AppLangX.fromCode(raw['lang'] as String?);
        _streak = (raw['streak'] as num?)?.toInt() ?? 0;
        _bestStreak = (raw['bestStreak'] as num?)?.toInt() ?? 0;
        _lastLoginYmd = raw['lastLoginYmd'] as String?;
        _activeTitleId = raw['activeTitleId'] as String?;
        final earned = raw['earned'];
        if (earned is List) {
          _earnedAchievements.addAll(earned.cast<String>());
        }
      }
    } catch (_) {
      // ignore corrupt profile
    }

    // Kolleksiya o'zgarsa — qayta baholash.
    CatPhotoStore.instance.addListener(_onCatsChanged);
    _evaluateAchievements();
    notifyListeners();
  }

  void _onCatsChanged() {
    _evaluateAchievements();
    notifyListeners();
  }

  /// Har kuni o'yinga kirishni qayd qiladi (streak).
  Future<void> registerLogin() async {
    final today = _ymd(DateTime.now());
    if (_lastLoginYmd == today) return;

    final yesterday = _ymd(DateTime.now().subtract(const Duration(days: 1)));
    if (_lastLoginYmd == yesterday) {
      _streak += 1;
    } else {
      _streak = 1;
    }
    if (_streak > _bestStreak) _bestStreak = _streak;
    _lastLoginYmd = today;

    _evaluateAchievements();
    await _save();
    notifyListeners();
  }

  Future<void> setName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _name = trimmed;
    await _save();
    notifyListeners();
  }

  Future<void> setAvatar(String? path) async {
    _avatarPath = path;
    await _save();
    notifyListeners();
  }

  Future<void> setShowcaseCat(String? path) async {
    _showcaseCatPath = path;
    await _save();
    notifyListeners();
  }

  Future<void> setLang(AppLang lang) async {
    if (_lang == lang) return;
    _lang = lang;
    await _save();
    notifyListeners();
  }

  Future<void> setActiveTitle(String? achievementId) async {
    if (achievementId != null && !_earnedAchievements.contains(achievementId)) {
      return;
    }
    _activeTitleId = achievementId;
    await _save();
    notifyListeners();
  }

  // ── Internal ──
  ProfileStats _computeStats() {
    final photos = CatPhotoStore.instance.photos;
    final counts = <int, int>{};
    var power = 0;
    for (final p in photos) {
      final lvl = p.grade?.level ?? 1;
      counts[lvl] = (counts[lvl] ?? 0) + 1;
      power += powerPerLevel[lvl] ?? 1;
    }

    // Daraja hisoblash
    var level = 1;
    var need = 100;
    var remaining = power;
    while (remaining >= need) {
      remaining -= need;
      level += 1;
      need = (need * 1.35).round();
    }

    return ProfileStats(
      totalCats: photos.length,
      countsByLevel: counts,
      totalPower: power,
      level: level,
      levelProgress: need == 0 ? 0 : (remaining / need).clamp(0.0, 1.0),
      powerInLevel: remaining,
      powerForNextLevel: need,
      streak: _streak,
      bestStreak: _bestStreak,
    );
  }

  void _evaluateAchievements() {
    final stats = _computeStats();
    var changed = false;
    for (final ach in Achievements.all) {
      if (_earnedAchievements.contains(ach.id)) continue;
      if (ach.isEarned(stats)) {
        _earnedAchievements.add(ach.id);
        changed = true;
      }
    }
    if (changed) {
      // Saqlash fon rejimida.
      _save();
    }
  }

  Future<void> _save() async {
    try {
      final file = await _file();
      final payload = {
        'name': _name,
        'avatarPath': _avatarPath,
        'showcaseCatPath': _showcaseCatPath,
        'lang': _lang.code,
        'streak': _streak,
        'bestStreak': _bestStreak,
        'lastLoginYmd': _lastLoginYmd,
        'activeTitleId': _activeTitleId,
        'earned': _earnedAchievements.toList(),
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (_) {
      // ignore
    }
  }

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
