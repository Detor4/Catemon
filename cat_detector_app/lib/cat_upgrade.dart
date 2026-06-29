import 'cat_grade.dart';

class CatUpgradeRule {
  const CatUpgradeRule({
    required this.fromLevel,
    required this.toLevel,
    required this.requiredCount,
  });

  final int fromLevel;
  final int toLevel;
  final int requiredCount;

  CatGradeTier get fromTier => CatGradeTier.forLevel(fromLevel);
  CatGradeTier get toTier => CatGradeTier.forLevel(toLevel);

  String get label =>
      '${fromTier.rarity} → ${toTier.rarity}';

  String get requirementLabel =>
      '$requiredCount × ${fromTier.rarity}';
}

class CatUpgradeCatalog {
  const CatUpgradeCatalog._();

  static const rules = [
    CatUpgradeRule(fromLevel: 1, toLevel: 2, requiredCount: 2),
    CatUpgradeRule(fromLevel: 2, toLevel: 3, requiredCount: 2),
    CatUpgradeRule(fromLevel: 3, toLevel: 4, requiredCount: 2),
    CatUpgradeRule(fromLevel: 4, toLevel: 5, requiredCount: 3),
    CatUpgradeRule(fromLevel: 5, toLevel: 6, requiredCount: 3),
    CatUpgradeRule(fromLevel: 6, toLevel: 7, requiredCount: 4),
  ];

  static CatUpgradeRule? ruleForLevels(int from, int to) {
    for (final rule in rules) {
      if (rule.fromLevel == from && rule.toLevel == to) return rule;
    }
    return null;
  }

  static CatUpgradeRule? ruleForFromLevel(int fromLevel) {
    for (final rule in rules) {
      if (rule.fromLevel == fromLevel) return rule;
    }
    return null;
  }

  static String colorKeyForLevel(int level) {
    switch (level) {
      case 2:
        return 'orange';
      case 3:
        return 'black';
      case 4:
        return 'gray';
      case 5:
        return 'white';
      case 6:
        return 'calico';
      case 7:
        return 'tortoiseshell';
      default:
        return 'brown_tabby';
    }
  }
}
