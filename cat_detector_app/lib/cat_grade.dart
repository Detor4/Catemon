import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Mushuk rarity darajasi (1 = Common … 7 = Mythic).
class CatGradeTier {
  const CatGradeTier({
    required this.level,
    required this.emoji,
    required this.nameUz,
    required this.nameEn,
    required this.rarity,
    required this.accentArgb,
    required this.frequencyHint,
  });

  final int level;
  final String emoji;
  final String nameUz;
  final String nameEn;
  final String rarity;
  final int accentArgb;
  final String frequencyHint;

  Color get accentColor => Color(accentArgb);

  String get stars => '⭐' * level;

  String get badgeLabel => '$emoji $rarity';

  static const List<CatGradeTier> all = [
    CatGradeTier(
      level: 1,
      emoji: '🟤',
      nameUz: 'Yo\'l-yo\'l jigarrang',
      nameEn: 'Brown Tabby',
      rarity: 'Common',
      accentArgb: 0xFF78522D,
      frequencyHint: 'Juda ko\'p uchraydi',
    ),
    CatGradeTier(
      level: 2,
      emoji: '🟠',
      nameUz: 'To\'q sariq (Ginger)',
      nameEn: 'Orange',
      rarity: 'Common+',
      accentArgb: 0xFFDC8C3C,
      frequencyHint: 'Ko\'p uchraydi',
    ),
    CatGradeTier(
      level: 3,
      emoji: '⚫',
      nameUz: 'Qora',
      nameEn: 'Black',
      rarity: 'Uncommon',
      accentArgb: 0xFF191919,
      frequencyHint: 'O\'rtacha',
    ),
    CatGradeTier(
      level: 4,
      emoji: '🔘',
      nameUz: 'Kulrang (Blue)',
      nameEn: 'Gray',
      rarity: 'Rare',
      accentArgb: 0xFF828791,
      frequencyHint: 'Kamroq',
    ),
    CatGradeTier(
      level: 5,
      emoji: '⚪',
      nameUz: 'Toza oq',
      nameEn: 'Pure White',
      rarity: 'Epic',
      accentArgb: 0xFFF5F5F5,
      frequencyHint: 'Ancha kam',
    ),
    CatGradeTier(
      level: 6,
      emoji: '🟧⬛',
      nameUz: 'Kaliko (oq + to\'q sariq + qora)',
      nameEn: 'Calico',
      rarity: 'Legendary',
      accentArgb: 0xFFDC8C3C,
      frequencyHint: 'Juda kam',
    ),
    CatGradeTier(
      level: 7,
      emoji: '🟫⬛',
      nameUz: 'Toshbaqa (qora + jigarrang + to\'q sariq)',
      nameEn: 'Tortoiseshell',
      rarity: 'Mythic',
      accentArgb: 0xFFCD6E2D,
      frequencyHint: 'Juda noyob',
    ),
  ];

  static CatGradeTier forLevel(int level) {
    return all[(level.clamp(1, all.length)) - 1];
  }
}

class CatGrade {
  const CatGrade({
    required this.tier,
    required this.qualityScore,
    required this.confidenceScore,
    required this.colorKey,
  });

  final CatGradeTier tier;
  final double qualityScore;
  final double confidenceScore;
  final String colorKey;

  int get level => tier.level;

  Map<String, dynamic> toJson() => {
        'level': tier.level,
        'qualityScore': qualityScore,
        'confidenceScore': confidenceScore,
        'colorKey': colorKey,
      };

  factory CatGrade.fromJson(Map<String, dynamic> json) {
    final level = (json['level'] as num?)?.toInt() ?? 1;
    return CatGrade(
      tier: CatGradeTier.forLevel(level),
      qualityScore: (json['qualityScore'] as num?)?.toDouble() ?? 0,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble() ?? 0,
      colorKey: json['colorKey'] as String? ?? 'brown_tabby',
    );
  }
}

class _Rgb {
  const _Rgb(this.r, this.g, this.b);

  final int r;
  final int g;
  final int b;
}

class CatGrader {
  const CatGrader._();

  static const _brownTabby = _Rgb(120, 82, 45);
  static const _orange = _Rgb(220, 140, 60);
  static const _black = _Rgb(25, 25, 25);
  static const _gray = _Rgb(130, 135, 145);
  static const _white = _Rgb(245, 245, 245);

  static const _calicoWhite = _Rgb(245, 245, 235);
  static const _calicoOrange = _Rgb(220, 140, 60);
  static const _calicoBlack = _Rgb(30, 30, 30);

  static const _tortoDark = _Rgb(35, 30, 28);
  static const _tortoBrown = _Rgb(125, 75, 40);
  static const _tortoOrange = _Rgb(205, 110, 45);

  static const _singleRefs = {
    'brown_tabby': _brownTabby,
    'orange': _orange,
    'black': _black,
    'gray': _gray,
    'white': _white,
  };

  static CatGrade grade(img.Image cutout, {required double confidence}) {
    final quality = _qualityScore(cutout);
    final colorAnalysis = _analyzeColors(cutout);
    final baseTier = _baseTierFromColor(colorAnalysis);
    final finalLevel = _applyModifiers(
      baseTier: baseTier,
      quality: quality,
      confidence: confidence,
    );

    return CatGrade(
      tier: CatGradeTier.forLevel(finalLevel),
      qualityScore: quality,
      confidenceScore: confidence,
      colorKey: colorAnalysis.dominantKey,
    );
  }

  static CatGrade gradeFromBytes(Uint8List pngBytes, {required double confidence}) {
    final image = img.decodeImage(pngBytes);
    if (image == null) {
      return CatGrade(
        tier: CatGradeTier.all.first,
        qualityScore: 0,
        confidenceScore: confidence,
        colorKey: 'brown_tabby',
      );
    }
    return grade(image, confidence: confidence);
  }

  static int _applyModifiers({
    required int baseTier,
    required double quality,
    required double confidence,
  }) {
    var level = baseTier;

    if (quality >= 0.78 && confidence >= 0.90 && baseTier >= 3) {
      level += 1;
    } else if (quality < 0.35 || confidence < 0.80) {
      level -= 1;
    }

    // Common ranglar osongina yuqori tierga o'tmasin.
    if (baseTier <= 2 && level > baseTier) {
      level = baseTier;
    }

    // Legendary/Mythic kam tushsin.
    if (baseTier >= 6 && level < baseTier) {
      level = baseTier;
    }

    return level.clamp(1, CatGradeTier.all.length);
  }

  static int _baseTierFromColor(_ColorAnalysis analysis) {
    if (analysis.isCalico) return 6;
    if (analysis.isTortoiseshell) return 7;

    switch (analysis.dominantKey) {
      case 'orange':
        return 2;
      case 'black':
        return 3;
      case 'gray':
        return 4;
      case 'white':
        return 5;
      case 'brown_tabby':
      default:
        return 1;
    }
  }

  static double _qualityScore(img.Image image) {
    final w = image.width;
    final h = image.height;
    if (w == 0 || h == 0) return 0;

    final step = math.max(1, math.max(w, h) ~/ 160);
    var edgeSum = 0.0;
    var edgeCount = 0;
    var opaqueCount = 0;
    var totalSampled = 0;

    for (int y = 0; y < h; y += step) {
      for (int x = 0; x < w; x += step) {
        totalSampled++;
        final a = image.getPixel(x, y).a;
        if (a < 40) continue;
        opaqueCount++;

        if (x > 0 && x < w - 1 && y > 0 && y < h - 1) {
          final c = _luminance(image.getPixel(x, y));
          final lx = _luminance(image.getPixel(x - step, y));
          final rx = _luminance(image.getPixel(x + step, y));
          final uy = _luminance(image.getPixel(x, y - step));
          final dy = _luminance(image.getPixel(x, y + step));
          edgeSum += ((c * 4 - lx - rx - uy - dy).abs());
          edgeCount++;
        }
      }
    }

    final sharpness =
        edgeCount == 0 ? 0 : (edgeSum / edgeCount / 255).clamp(0.0, 1.0);
    final resolution = (math.sqrt(w * h) / 500).clamp(0.0, 1.0);
    final coverage =
        totalSampled == 0 ? 0 : (opaqueCount / totalSampled).clamp(0.0, 1.0);

    return (sharpness * 0.5 + resolution * 0.35 + coverage * 0.15)
        .clamp(0.0, 1.0);
  }

  static double _luminance(img.Pixel p) =>
      0.299 * p.r + 0.587 * p.g + 0.114 * p.b;

  static _ColorAnalysis _analyzeColors(img.Image image) {
    final w = image.width;
    final h = image.height;
    final refCounts = {
      for (final key in _singleRefs.keys) key: 0,
      'calico_white': 0,
      'calico_orange': 0,
      'calico_black': 0,
      'torto_dark': 0,
      'torto_brown': 0,
      'torto_orange': 0,
    };
    final quadrantHits = {
      'calico_white': [false, false, false, false],
      'calico_orange': [false, false, false, false],
      'calico_black': [false, false, false, false],
      'torto_dark': [false, false, false, false],
      'torto_brown': [false, false, false, false],
      'torto_orange': [false, false, false, false],
    };

    var opaque = 0;
    final step = math.max(1, math.max(w, h) ~/ 120);

    for (int y = 0; y < h; y += step) {
      for (int x = 0; x < w; x += step) {
        final pixel = image.getPixel(x, y);
        if (pixel.a < 60) continue;
        opaque++;

        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final q = (y < h / 2 ? 0 : 2) + (x < w / 2 ? 0 : 1);

        final singleKey = _closestSingleRef(r, g, b);
        refCounts[singleKey] = refCounts[singleKey]! + 1;

        final calicoKey = _closestCalicoRef(r, g, b);
        refCounts[calicoKey] = refCounts[calicoKey]! + 1;
        quadrantHits[calicoKey]![q] = true;

        final tortoKey = _closestTortoRef(r, g, b);
        refCounts[tortoKey] = refCounts[tortoKey]! + 1;
        quadrantHits[tortoKey]![q] = true;
      }
    }

    if (opaque == 0) {
      return const _ColorAnalysis(
        dominantKey: 'brown_tabby',
        isCalico: false,
        isTortoiseshell: false,
      );
    }

    final cw = refCounts['calico_white']! / opaque;
    final co = refCounts['calico_orange']! / opaque;
    final cb = refCounts['calico_black']! / opaque;

    final isCalico = cw > 0.12 &&
        co > 0.08 &&
        cb > 0.08 &&
        _spreadCount(quadrantHits['calico_white']!) >= 2 &&
        _spreadCount(quadrantHits['calico_orange']!) >= 2 &&
        _spreadCount(quadrantHits['calico_black']!) >= 2;

    final td = refCounts['torto_dark']! / opaque;
    final tb = refCounts['torto_brown']! / opaque;
    final to = refCounts['torto_orange']! / opaque;
    final whiteRatio = refCounts['white']! / opaque;

    final isTortoiseshell = !isCalico &&
        whiteRatio < 0.07 &&
        td > 0.10 &&
        tb > 0.10 &&
        to > 0.10 &&
        _spreadCount(quadrantHits['torto_dark']!) >= 2 &&
        _spreadCount(quadrantHits['torto_brown']!) >= 2 &&
        _spreadCount(quadrantHits['torto_orange']!) >= 2;

    if (isCalico) {
      return const _ColorAnalysis(
        dominantKey: 'calico',
        isCalico: true,
        isTortoiseshell: false,
      );
    }
    if (isTortoiseshell) {
      return const _ColorAnalysis(
        dominantKey: 'tortoiseshell',
        isCalico: false,
        isTortoiseshell: true,
      );
    }

    return _ColorAnalysis(
      dominantKey: _dominantSingleKey(refCounts, opaque),
      isCalico: false,
      isTortoiseshell: false,
    );
  }

  static String _dominantSingleKey(Map<String, int> counts, int opaque) {
    var bestKey = 'brown_tabby';
    var bestVal = -1.0;

    for (final entry in _singleRefs.entries) {
      final ratio = counts[entry.key]! / opaque;
      var score = ratio;
      if (entry.key == 'brown_tabby') score += 0.06;
      if (score > bestVal) {
        bestVal = score;
        bestKey = entry.key;
      }
    }

    if (bestVal < 0.16) return 'brown_tabby';
    return bestKey;
  }

  static String _closestSingleRef(int r, int g, int b) {
    var bestKey = 'brown_tabby';
    var bestDist = double.infinity;
    _singleRefs.forEach((key, ref) {
      final d = _colorDist(r, g, b, ref);
      if (d < bestDist) {
        bestDist = d;
        bestKey = key;
      }
    });
    return bestKey;
  }

  static String _closestCalicoRef(int r, int g, int b) {
    final dW = _colorDist(r, g, b, _calicoWhite);
    final dO = _colorDist(r, g, b, _calicoOrange);
    final dB = _colorDist(r, g, b, _calicoBlack);
    if (dW <= dO && dW <= dB) return 'calico_white';
    if (dO <= dB) return 'calico_orange';
    return 'calico_black';
  }

  static String _closestTortoRef(int r, int g, int b) {
    final dD = _colorDist(r, g, b, _tortoDark);
    final dB = _colorDist(r, g, b, _tortoBrown);
    final dO = _colorDist(r, g, b, _tortoOrange);
    if (dD <= dB && dD <= dO) return 'torto_dark';
    if (dB <= dO) return 'torto_brown';
    return 'torto_orange';
  }

  static double _colorDist(int r, int g, int b, _Rgb ref) {
    final dr = r - ref.r;
    final dg = g - ref.g;
    final db = b - ref.b;
    return math.sqrt(dr * dr + dg * dg + db * db);
  }

  static int _spreadCount(List<bool> hits) => hits.where((h) => h).length;
}

class _ColorAnalysis {
  const _ColorAnalysis({
    required this.dominantKey,
    required this.isCalico,
    required this.isTortoiseshell,
  });

  final String dominantKey;
  final bool isCalico;
  final bool isTortoiseshell;
}

Color rarityLabelColor(String rarity, {required ColorScheme scheme}) {
  switch (rarity) {
    case 'Common+':
      return const Color(0xFFE65100);
    case 'Uncommon':
      return const Color(0xFF37474F);
    case 'Rare':
      return const Color(0xFF1565C0);
    case 'Epic':
      return const Color(0xFF6A1B9A);
    case 'Legendary':
      return const Color(0xFFF57F17);
    case 'Mythic':
      return const Color(0xFFD84315);
    default:
      return const Color(0xFF5D4037);
  }
}

Color rarityBadgeBackground(String rarity) {
  switch (rarity) {
    case 'Common+':
      return const Color(0xFFFFF3E0);
    case 'Uncommon':
      return const Color(0xFFECEFF1);
    case 'Rare':
      return const Color(0xFFE3F2FD);
    case 'Epic':
      return const Color(0xFFF3E5F5);
    case 'Legendary':
      return const Color(0xFFFFF8E1);
    case 'Mythic':
      return const Color(0xFFFBE9E7);
    default:
      return const Color(0xFFEFEBE9);
  }
}
