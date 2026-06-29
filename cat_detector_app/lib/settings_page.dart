import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'profile_store.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 20,
        title: Text('⚙️ ${s.settings}', style: AppText.display(22)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionLabel(s.language),
          const SizedBox(height: 10),
          ...AppLang.values.map(
            (lang) => _LanguageTile(
              lang: lang,
              selected: _profile.lang == lang,
              onTap: () => _profile.setLang(lang),
            ),
          ),
          const SizedBox(height: 28),
          _SectionLabel(s.about),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.orangeGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('🐾', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.appName, style: AppText.heading(16)),
                      Text('${s.version} 1.0.0',
                          style: AppText.body(13, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.caps(12, color: AppColors.textSecondary),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final AppLang lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(lang.flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                lang.label,
                style: AppText.heading(16,
                    color: selected ? AppColors.textPrimary : AppColors.textSecondary),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.accent)
            else
              const Icon(Icons.circle_outlined, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
