import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'profile_store.dart';
import 'theme/app_colors.dart';

/// Bitta yutuq (titul) ta'rifi.
class Achievement {
  const Achievement({
    required this.id,
    required this.icon,
    required this.color,
    required this.target,
    required this.titleOf,
    required this.descOf,
    required this.progressOf,
  });

  final String id;
  final IconData icon;
  final Color color;
  final int target;

  /// Lokalizatsiya qilingan nom.
  final String Function(S s) titleOf;

  /// Lokalizatsiya qilingan tavsif.
  final String Function(S s) descOf;

  /// Joriy progress (0..target).
  final int Function(ProfileStats stats) progressOf;

  bool isEarned(ProfileStats stats) => progressOf(stats) >= target;

  double progressFraction(ProfileStats stats) =>
      (progressOf(stats) / target).clamp(0.0, 1.0);
}

class Achievements {
  const Achievements._();

  static final List<Achievement> all = [
    Achievement(
      id: 'first_cat',
      icon: Icons.pets_rounded,
      color: AppColors.accentTeal,
      target: 1,
      titleOf: (s) => s.achFirstCatTitle,
      descOf: (s) => s.achFirstCatDesc,
      progressOf: (st) => st.totalCats,
    ),
    Achievement(
      id: 'collector_30',
      icon: Icons.grid_view_rounded,
      color: AppColors.accent,
      target: 30,
      titleOf: (s) => s.achCollectorTitle,
      descOf: (s) => s.achCollectorDesc,
      progressOf: (st) => st.totalCats,
    ),
    Achievement(
      id: 'legend_3',
      icon: Icons.local_fire_department_rounded,
      color: const Color(0xFFFF6B35),
      target: 3,
      titleOf: (s) => s.achLegendTitle,
      descOf: (s) => s.achLegendDesc,
      progressOf: (st) => st.legendaryCount,
    ),
    Achievement(
      id: 'mythic_1',
      icon: Icons.auto_awesome_rounded,
      color: AppColors.accentSecondary,
      target: 1,
      titleOf: (s) => s.achMythicTitle,
      descOf: (s) => s.achMythicDesc,
      progressOf: (st) => st.mythicCount,
    ),
    Achievement(
      id: 'level_10',
      icon: Icons.military_tech_rounded,
      color: AppColors.accentPurple,
      target: 10,
      titleOf: (s) => s.achLevelTitle,
      descOf: (s) => s.achLevelDesc,
      progressOf: (st) => st.level,
    ),
    Achievement(
      id: 'streak_7',
      icon: Icons.calendar_month_rounded,
      color: const Color(0xFF3B82F6),
      target: 7,
      titleOf: (s) => s.achStreakTitle,
      descOf: (s) => s.achStreakDesc,
      progressOf: (st) => st.bestStreak,
    ),
  ];

  static Achievement? byId(String? id) {
    if (id == null) return null;
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}
