import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import 'achievements.dart';
import 'achievements_page.dart';
import 'app_strings.dart';
import 'camera_page.dart';
import 'cat_photo_store.dart';
import 'gallery_page.dart';
import 'profile_store.dart';
import 'settings_page.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'upgrade_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _store = CatPhotoStore.instance;
  final _profile = ProfileStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onChanged);
    _profile.addListener(_onChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onChanged);
    _profile.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _openCamera() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, _, _) => const CameraPage(),
        transitionsBuilder: (_, animation, _, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    );
  }

  void _openGallery() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const GalleryPage()));
  }

  void _openUpgrade() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const UpgradePage()));
  }

  void _openAchievements() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AchievementsPage()));
  }

  void _openSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsPage()));
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _profile.name);
    final s = S.current;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(s.editName, style: AppText.heading(18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 18,
          style: AppText.heading(16),
          decoration: InputDecoration(
            hintText: s.player,
            hintStyle: AppText.body(15, color: AppColors.textMuted),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(s.save,
                style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
    if (result != null) {
      await _profile.setName(result);
    }
  }

  Future<void> _changeAvatar() async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        await _profile.setAvatar(picked.path);
      }
    } catch (_) {}
  }

  Future<void> _chooseShowcase() async {
    final photos = _store.photos;
    final s = S.current;
    if (photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.noCatsYet),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(s.chooseShowcase, style: AppText.heading(17)),
                const SizedBox(height: 12),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      final color = AppRarity.color(
                          photo.grade?.tier.rarity ?? 'Common');
                      return GestureDetector(
                        onTap: () {
                          _profile.setShowcaseCat(photo.path);
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: color.withValues(alpha: 0.4),
                                width: 1.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.file(File(photo.path),
                              fit: BoxFit.contain),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.current;
    final stats = _profile.stats;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              onAchievements: _openAchievements,
              onSettings: _openSettings,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  children: [
                    _ShowcaseFrame(
                      path: _profile.showcaseCatPath,
                      onTap: _chooseShowcase,
                    ),
                    const SizedBox(height: 20),
                    _ProfileCard(
                      profile: _profile,
                      stats: stats,
                      onEditName: _editName,
                      onAvatar: _changeAvatar,
                    ),
                    const SizedBox(height: 16),
                    _LevelBar(stats: stats),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickStat(
                            icon: Icons.pets_rounded,
                            value: '${stats.totalCats}',
                            label: s.catsCount,
                            color: AppColors.accentTeal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickStat(
                            icon: Icons.bolt_rounded,
                            value: '${stats.totalPower}',
                            label: s.power,
                            color: AppColors.accentSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickStat(
                            icon: Icons.local_fire_department_rounded,
                            value: '${stats.streak}',
                            label: s.achStreakTitle,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _MenuButton(
                      icon: Icons.emoji_events_rounded,
                      label: s.achievements,
                      trailing:
                          '${_profile.earnedAchievements.length}/${Achievements.all.length}',
                      color: AppColors.accentSecondary,
                      onTap: _openAchievements,
                    ),
                    const SizedBox(height: 10),
                    _MenuButton(
                      icon: Icons.settings_rounded,
                      label: s.settings,
                      trailing: _profile.lang.flag,
                      color: AppColors.accentPurple,
                      onTap: _openSettings,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _HomeBottomNav(
        onGallery: _openGallery,
        onCamera: _openCamera,
        onUpgrade: _openUpgrade,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onAchievements, required this.onSettings});

  final VoidCallback onAchievements;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final s = S.current;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
      child: Row(
        children: [
          Text('🐾 ', style: AppText.display(24)),
          Text(s.appName, style: AppText.display(26)),
          const Spacer(),
          _IconBtn(icon: Icons.emoji_events_rounded, onTap: onAchievements),
          const SizedBox(width: 6),
          _IconBtn(icon: Icons.settings_rounded, onTap: onSettings),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3, curve: Curves.easeOut);
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppColors.textSecondary, size: 22),
        ),
      ),
    );
  }
}

class _ShowcaseFrame extends StatelessWidget {
  const _ShowcaseFrame({required this.path, required this.onTap});

  final String? path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = path != null && File(path!).existsSync();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          gradient: const RadialGradient(
            radius: 0.9,
            colors: [Color(0x26FF6B35), Color(0x000D0D0F)],
          ),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _FrameDotsPainter()),
            if (hasImage)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Image.file(File(path!), fit: BoxFit.contain),
              )
            else
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🐱', style: TextStyle(fontSize: 72))
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveY(
                            begin: 0,
                            end: -6,
                            duration: 2000.ms,
                            curve: Curves.easeInOut),
                    const SizedBox(height: 6),
                    Text(S.current.chooseShowcase,
                        style:
                            AppText.body(13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_rounded,
                    size: 16, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(
          begin: const Offset(0.96, 0.96),
          curve: Curves.easeOut,
        );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.profile,
    required this.stats,
    required this.onEditName,
    required this.onAvatar,
  });

  final ProfileStore profile;
  final ProfileStats stats;
  final VoidCallback onEditName;
  final VoidCallback onAvatar;

  @override
  Widget build(BuildContext context) {
    final s = S.current;
    final avatar = profile.avatarPath;
    final hasAvatar = avatar != null && File(avatar).existsSync();
    final title = Achievements.byId(profile.activeTitleId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatar,
            child: Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.orangeGradient,
                  ),
                  padding: const EdgeInsets.all(2.5),
                  child: ClipOval(
                    child: hasAvatar
                        ? Image.file(File(avatar), fit: BoxFit.cover)
                        : Container(
                            color: AppColors.surfaceElevated,
                            child: const Icon(Icons.person_rounded,
                                color: AppColors.textSecondary, size: 32),
                          ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onEditName,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.display(20),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_rounded,
                          size: 14, color: AppColors.textMuted),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                if (title != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: title.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(title.icon, size: 12, color: title.color),
                        const SizedBox(width: 4),
                        Text(title.titleOf(s),
                            style: AppText.game(11, color: title.color)),
                      ],
                    ),
                  )
                else
                  Text(s.tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(12, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _LevelBadge(level: stats.level),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.accentSecondary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppTheme.neon(AppColors.accent),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$level', style: AppText.game(20, color: Colors.white)),
          Text('LVL', style: AppText.caps(8, color: Colors.white)),
        ],
      ),
    );
  }
}

class _LevelBar extends StatelessWidget {
  const _LevelBar({required this.stats});

  final ProfileStats stats;

  @override
  Widget build(BuildContext context) {
    final s = S.current;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(s.levelLabel(stats.level), style: AppText.game(13)),
            const Spacer(),
            Text(
              '${stats.powerInLevel} / ${stats.powerForNextLevel}',
              style: AppText.body(12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: stats.levelProgress,
            minHeight: 10,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: AppText.game(18)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String trailing;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: AppText.heading(15))),
              Text(trailing,
                  style: AppText.game(13, color: AppColors.textSecondary)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _FrameDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.03);
    const spacing = 22.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({
    required this.onGallery,
    required this.onCamera,
    required this.onUpgrade,
  });

  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final s = S.current;
    return Container(
      height: 80 + MediaQuery.paddingOf(context).bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.grid_view_outlined,
                  label: s.collection,
                  onTap: onGallery,
                ),
              ),
              const Expanded(child: SizedBox()),
              Expanded(
                child: _NavItem(
                  icon: Icons.auto_awesome,
                  label: s.upgrade,
                  onTap: onUpgrade,
                ),
              ),
            ],
          ),
          Positioned(
            top: -20,
            child: _CameraNavButton(onTap: onCamera),
          ),
        ],
      ),
    );
  }
}

class _CameraNavButton extends StatelessWidget {
  const _CameraNavButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          gradient: AppColors.orangeGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.55),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: AppColors.surface, width: 4),
        ),
        child:
            const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 32),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 1200.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 26),
            const SizedBox(height: 4),
            Text(label,
                style: AppText.body(11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
