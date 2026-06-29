import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'cat_photo_store.dart';
import 'cat_upgrade.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/rarity_widgets.dart';

class UpgradePage extends StatefulWidget {
  const UpgradePage({super.key});

  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  final _store = CatPhotoStore.instance;

  /// Upgrade qilinadigan asosiy mushuk.
  String? _targetPath;
  final _sacrificePaths = <String>{};
  bool _upgrading = false;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    // Tanlangan mushuk o'chirilgan bo'lsa — reset.
    if (_targetPath != null &&
        !_store.photos.any((p) => p.path == _targetPath)) {
      _targetPath = null;
      _sacrificePaths.clear();
    } else {
      _sacrificePaths.removeWhere(
        (path) => !_store.photos.any((p) => p.path == path),
      );
    }
    setState(() {});
  }

  CatPhoto? get _target {
    if (_targetPath == null) return null;
    for (final p in _store.photos) {
      if (p.path == _targetPath) return p;
    }
    return null;
  }

  CatUpgradeRule? get _rule {
    final level = _target?.grade?.level;
    if (level == null) return null;
    return CatUpgradeCatalog.ruleForFromLevel(level);
  }

  /// Upgrade qilish mumkin bo'lgan barcha mushuklar (1–6 daraja).
  List<CatPhoto> get _targetCandidates {
    return _store.photos.where((p) {
      final level = p.grade?.level;
      return level != null && CatUpgradeCatalog.ruleForFromLevel(level) != null;
    }).toList();
  }

  /// Asosiy mushukdan tashqari, bir xil darajadagi qurbanlar.
  List<CatPhoto> get _sacrificeCandidates {
    final rule = _rule;
    if (rule == null || _targetPath == null) return [];
    return _store
        .photosAtLevel(rule.fromLevel)
        .where((p) => p.path != _targetPath)
        .toList();
  }

  void _selectTarget(String path) {
    setState(() {
      _targetPath = path;
      _sacrificePaths.clear();
    });
  }

  void _clearTarget() {
    setState(() {
      _targetPath = null;
      _sacrificePaths.clear();
    });
  }

  void _toggleSacrifice(String path) {
    final rule = _rule;
    if (rule == null || path == _targetPath) return;

    setState(() {
      if (_sacrificePaths.contains(path)) {
        _sacrificePaths.remove(path);
      } else if (_sacrificePaths.length < rule.requiredCount) {
        _sacrificePaths.add(path);
      }
    });
  }

  Future<void> _confirmUpgrade() async {
    final rule = _rule;
    final targetPath = _targetPath;
    if (rule == null || targetPath == null) return;
    if (_sacrificePaths.length != rule.requiredCount) return;

    setState(() => _upgrading = true);
    try {
      final result = await _store.upgrade(
        targetPath: targetPath,
        sacrificePaths: _sacrificePaths.toList(),
        rule: rule,
      );

      if (!mounted) return;
      setState(() {
        _targetPath = null;
        _sacrificePaths.clear();
      });

      final color = AppRarity.color(result.grade!.tier.rarity);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: color.withValues(alpha: 0.95),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
          content: Row(
            children: [
              Text(AppRarity.emoji(result.grade!.tier.rarity),
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '🎉 ${result.grade!.tier.rarity} ga ko\'tarildi!',
                  style: AppText.game(15, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _upgrading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    final rule = _rule;
    final hasTarget = target != null && rule != null;
    final ready = hasTarget && _sacrificePaths.length == rule.requiredCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [AppColors.accent, AppColors.accentSecondary],
              ).createShader(rect),
              child: Text('⚡ Upgrade', style: AppText.display(22, color: Colors.white)),
            ),
            Text(
              hasTarget
                  ? 'Qurban mushuklarni tanlang'
                  : 'Avval upgrade qilinadigan mushukni tanlang',
              style: AppText.body(13, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          if (hasTarget)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Qayta tanlash',
              onPressed: _clearTarget,
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Yuqori: asosiy mushuk sloti (~45%) ──
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.38,
                child: _TargetPanel(
                  target: target,
                  rule: rule,
                  sacrificeCount: _sacrificePaths.length,
                  onClear: hasTarget ? _clearTarget : null,
                ),
              ),
              Container(height: 1, color: AppColors.border),
              // ── Pastki: scroll grid (~55%) ──
              Expanded(child: _buildGrid(hasTarget, rule)),
            ],
          ),
          if (ready)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20 + MediaQuery.paddingOf(context).bottom,
              child: _UpgradeButton(
                label: '${rule.toTier.rarity} ga ko\'tarish',
                color: AppRarity.color(rule.toTier.rarity),
                onTap: _upgrading ? null : _confirmUpgrade,
              ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.5),
            ),
          if (_upgrading) const _FusionOverlay(),
        ],
      ),
    );
  }

  Widget _buildGrid(bool hasTarget, CatUpgradeRule? rule) {
    if (!hasTarget) {
      final candidates = _targetCandidates;
      if (candidates.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Upgrade qilish mumkin bo\'lgan mushuk yo\'q.\nAvval kameradan mushuk toping!',
              textAlign: TextAlign.center,
              style: AppText.body(14, color: AppColors.textMuted),
            ),
          ),
        );
      }
      return _PhotoGrid(
        title: 'Upgrade qilinadigan mushukni tanlang',
        photos: candidates,
        isSelected: (_) => false,
        onTap: (photo) => _selectTarget(photo.path),
      );
    }

    final candidates = _sacrificeCandidates;
    final fromRarity = rule!.fromTier.rarity;

    if (candidates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Qurban uchun $fromRarity mushuk yo\'q',
                  style: AppText.heading(16, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text(
                'Bu mushukni ko\'tarish uchun o\'zingizdan tashqari '
                '${rule.requiredCount} ta $fromRarity kerak.',
                textAlign: TextAlign.center,
                style: AppText.body(13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (candidates.length < rule.requiredCount) {
      return Column(
        children: [
          _GridHeader(
            title: 'Qurbanlar: $fromRarity',
            subtitle:
                'Yetmayapti — ${candidates.length}/${rule.requiredCount} ta mavjud',
            badge: '${_sacrificePaths.length}/${rule.requiredCount}',
            badgeReady: false,
          ),
          Expanded(
            child: _PhotoGrid(
              photos: candidates,
              isSelected: (p) => _sacrificePaths.contains(p.path),
              onTap: (p) => _toggleSacrifice(p.path),
              dimmed: true,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _GridHeader(
          title: 'Qurbanlar tanlang',
          subtitle:
              'O\'zingizdan tashqari ${rule.requiredCount} ta $fromRarity kerak',
          badge: '${_sacrificePaths.length}/${rule.requiredCount}',
          badgeReady: _sacrificePaths.length == rule.requiredCount,
        ),
        Expanded(
          child: _PhotoGrid(
            photos: candidates,
            isSelected: (p) => _sacrificePaths.contains(p.path),
            onTap: (p) => _toggleSacrifice(p.path),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────── Target panel ────────────────────────────

class _TargetPanel extends StatelessWidget {
  const _TargetPanel({
    required this.target,
    required this.rule,
    required this.sacrificeCount,
    this.onClear,
  });

  final CatPhoto? target;
  final CatUpgradeRule? rule;
  final int sacrificeCount;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Asosiy slot
                Expanded(
                  flex: 3,
                  child: _TargetSlot(
                    target: target,
                    onClear: onClear,
                  ),
                ),
                if (target != null && rule != null) ...[
                  const SizedBox(width: 12),
                  // O'q + yangi daraja
                  Expanded(
                    flex: 2,
                    child: _UpgradeArrow(rule: rule!),
                  ),
                ],
              ],
            ),
          ),
          if (target != null && rule != null) ...[
            const SizedBox(height: 12),
            _RequirementBar(
              rule: rule!,
              sacrificeCount: sacrificeCount,
            ),
          ],
        ],
      ),
    );
  }
}

class _TargetSlot extends StatelessWidget {
  const _TargetSlot({required this.target, this.onClear});

  final CatPhoto? target;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final rarity = target?.grade?.tier.rarity;
    final color = rarity != null
        ? AppRarity.color(rarity)
        : AppColors.border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: target != null ? color.withValues(alpha: 0.6) : AppColors.border,
          width: target != null ? 2 : 1.5,
        ),
        boxShadow: target != null
            ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 16)]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: target == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded,
                    size: 36, color: AppColors.textMuted.withValues(alpha: 0.5)),
                const SizedBox(height: 8),
                Text('Asosiy mushuk',
                    style: AppText.body(13, color: AppColors.textMuted)),
                Text('Pastdan tanlang',
                    style: AppText.body(11, color: AppColors.textMuted)),
              ],
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: AppColors.surfaceElevated),
                Image.file(File(target!.path), fit: BoxFit.contain),
                Positioned(
                  top: 8,
                  left: 8,
                  child: RarityPill(rarity: rarity!, fontSize: 9),
                ),
                if (onClear != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onClear,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _UpgradeArrow extends StatelessWidget {
  const _UpgradeArrow({required this.rule});

  final CatUpgradeRule rule;

  @override
  Widget build(BuildContext context) {
    final fromColor = AppRarity.color(rule.fromTier.rarity);
    final toColor = AppRarity.color(rule.toTier.rarity);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(rule.fromTier.rarity,
            style: AppText.game(11, color: fromColor),
            textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Icon(Icons.arrow_downward_rounded, color: AppColors.accent, size: 22)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: 4, duration: 900.ms, curve: Curves.easeInOut),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: toColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: toColor.withValues(alpha: 0.5)),
          ),
          child: Text(rule.toTier.rarity,
              style: AppText.game(12, color: toColor),
              textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

class _RequirementBar extends StatelessWidget {
  const _RequirementBar({
    required this.rule,
    required this.sacrificeCount,
  });

  final CatUpgradeRule rule;
  final int sacrificeCount;

  @override
  Widget build(BuildContext context) {
    final ready = sacrificeCount == rule.requiredCount;
    final fromRarity = rule.fromTier.rarity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            ready ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: ready ? AppColors.accentTeal : AppColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ready
                  ? 'Tayyor! Upgrade qilish mumkin'
                  : 'Kerak: o\'zingizdan tashqari '
                      '${rule.requiredCount} ta $fromRarity qurban',
              style: AppText.body(12,
                  color: ready ? AppColors.accentTeal : AppColors.textSecondary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (ready ? AppColors.accentTeal : AppColors.textMuted)
                  .withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Text(
              '$sacrificeCount/${rule.requiredCount}',
              style: AppText.game(12,
                  color: ready ? AppColors.accentTeal : AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── Grid ────────────────────────────

class _GridHeader extends StatelessWidget {
  const _GridHeader({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeReady,
  });

  final String title;
  final String subtitle;
  final String badge;
  final bool badgeReady;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.heading(15)),
                Text(subtitle,
                    style: AppText.body(12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (badgeReady ? AppColors.accentTeal : AppColors.textMuted)
                  .withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Text(
              badge,
              style: AppText.game(12,
                  color: badgeReady
                      ? AppColors.accentTeal
                      : AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({
    this.title,
    required this.photos,
    required this.isSelected,
    required this.onTap,
    this.dimmed = false,
  });

  final String? title;
  final List<CatPhoto> photos;
  final bool Function(CatPhoto) isSelected;
  final void Function(CatPhoto) onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (title != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(title!, style: AppText.heading(15)),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final photo = photos[index];
                return _CandidateTile(
                  path: photo.path,
                  rarity: photo.grade?.tier.rarity ?? 'Common',
                  selected: isSelected(photo),
                  dimmed: dimmed,
                  onTap: () => onTap(photo),
                );
              },
              childCount: photos.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({
    required this.path,
    required this.rarity,
    required this.selected,
    required this.onTap,
    this.dimmed = false,
  });

  final String path;
  final String rarity;
  final bool selected;
  final VoidCallback onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final color = AppRarity.color(rarity);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accentTeal : color.withValues(alpha: 0.35),
            width: selected ? 3 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.surface),
            Opacity(
              opacity: dimmed ? 0.45 : 1,
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
            if (selected)
              Container(
                color: AppColors.accentTeal.withValues(alpha: 0.25),
                child: const Center(
                  child: Icon(Icons.check_circle_rounded,
                      color: AppColors.accentTeal, size: 28),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          boxShadow: AppTheme.neon(color),
        ),
        child: Center(
          child: Text(label, style: AppText.game(16, color: Colors.white)),
        ),
      ),
    );
  }
}

class _FusionOverlay extends StatelessWidget {
  const _FusionOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✨', style: const TextStyle(fontSize: 64))
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.2, 1.2),
                  duration: 700.ms,
                  curve: Curves.easeInOut,
                )
                .then()
                .shake(),
            const SizedBox(height: 16),
            Text('Birlashtirilmoqda...', style: AppText.heading(16)),
          ],
        ),
      ),
    );
  }
}
