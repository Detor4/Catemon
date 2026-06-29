import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'achievements.dart';
import 'app_strings.dart';
import 'profile_store.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final _profile = ProfileStore.instance;

  @override
  void initState() {
    super.initState();
    _profile.addListener(_onChanged);
  }

  @override
  void dispose() {
    _profile.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = S.current;
    final stats = _profile.stats;
    final earned = _profile.earnedAchievements;
    final earnedCount = earned.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🏆 ${s.achievementsTitle}', style: AppText.display(22)),
            Text(s.achievementsSubtitle,
                style: AppText.body(13, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _ProgressBanner(
            earned: earnedCount,
            total: Achievements.all.length,
          ),
          const SizedBox(height: 16),
          ...List.generate(Achievements.all.length, (i) {
            final ach = Achievements.all[i];
            final isEarned = earned.contains(ach.id);
            final isActive = _profile.activeTitleId == ach.id;
            return _AchievementCard(
              achievement: ach,
              stats: stats,
              earned: isEarned,
              active: isActive,
              onSetTitle: isEarned
                  ? () => _profile.setActiveTitle(isActive ? null : ach.id)
                  : null,
            ).animate().fadeIn(delay: (i * 60).ms, duration: 300.ms).slideX(
                  begin: 0.1,
                  curve: Curves.easeOut,
                );
          }),
        ],
      ),
    );
  }
}

class _ProgressBanner extends StatelessWidget {
  const _ProgressBanner({required this.earned, required this.total});

  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : earned / total;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.18),
            AppColors.accentPurple.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: fraction,
                    strokeWidth: 5,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
                const Text('🏆', style: TextStyle(fontSize: 22)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$earned / $total', style: AppText.display(24)),
                Text(
                  S.current.earned,
                  style: AppText.body(13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.achievement,
    required this.stats,
    required this.earned,
    required this.active,
    required this.onSetTitle,
  });

  final Achievement achievement;
  final ProfileStats stats;
  final bool earned;
  final bool active;
  final VoidCallback? onSetTitle;

  @override
  Widget build(BuildContext context) {
    final s = S.current;
    final color = achievement.color;
    final progress = achievement.progressOf(stats);
    final fraction = achievement.progressFraction(stats);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: earned ? color.withValues(alpha: 0.5) : AppColors.border,
          width: earned ? 1.5 : 1,
        ),
        boxShadow: earned
            ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 16)]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: earned
                      ? color.withValues(alpha: 0.18)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  earned ? achievement.icon : Icons.lock_outline_rounded,
                  color: earned ? color : AppColors.textMuted,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            achievement.titleOf(s),
                            style: AppText.heading(16,
                                color: earned
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary),
                          ),
                        ),
                        if (active) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusPill),
                            ),
                            child: Text(s.activeTitle,
                                style: AppText.caps(8, color: Colors.white)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.descOf(s),
                      style: AppText.body(12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (earned)
                Icon(Icons.check_circle_rounded, color: color, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(
                        earned ? color : AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                s.progressOf(
                  progress.clamp(0, achievement.target),
                  achievement.target,
                ),
                style: AppText.game(12, color: AppColors.textSecondary),
              ),
            ],
          ),
          if (earned) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: onSetTitle,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.surfaceElevated
                        : color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                    border: Border.all(
                      color: active ? AppColors.border : color.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      active ? s.noTitle : s.setAsTitle,
                      style: AppText.game(13,
                          color: active ? AppColors.textSecondary : color),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
