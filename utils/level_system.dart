import 'package:flutter/material.dart';
import 'package:sajda/theme.dart';

class LevelInfo {
  final int level; // 1..100
  final String title; // e.g., "Aspirant", "Rubis"
  final String gemstone; // gemstone/tier label
  final double progress; // 0..1 within current level
  final Color color;
  final List<Color> gradient;

  const LevelInfo({
    required this.level,
    required this.title,
    required this.gemstone,
    required this.progress,
    required this.color,
    required this.gradient,
  });
}

class LevelSystem {
  // Simple rule: 100 hassanat per level, 100 levels max
  static const int xpPerLevel = 100;
  static const int maxLevel = 100;

  static LevelInfo fromHassanat(int totalHassanat) {
    int lvl = (totalHassanat ~/ xpPerLevel) + 1;
    if (lvl < 1) lvl = 1;
    if (lvl > maxLevel) lvl = maxLevel;
    final int xpIntoLevel = totalHassanat % xpPerLevel;
    final double prog = (lvl == maxLevel) ? 1.0 : (xpIntoLevel / xpPerLevel);

    final _Tier tier = _tierForLevel(lvl);

    return LevelInfo(
      level: lvl,
      title: tier.title,
      gemstone: tier.gemstone,
      progress: prog.clamp(0.0, 1.0),
      color: tier.color,
      gradient: tier.gradient,
    );
  }

  // Define tiers across 100 levels
  static _Tier _tierForLevel(int level) {
    if (level <= 9) {
      return _Tier(
        title: 'Aspirant',
        gemstone: 'Quartz',
        color: IslamicColors.quartz,
        gradient: [IslamicColors.quartz, Colors.white],
      );
    } else if (level <= 19) {
      return _Tier(
        title: 'Disciple',
        gemstone: 'Topaze',
        color: IslamicColors.topaz,
        gradient: [IslamicColors.topaz, IslamicColors.roseGold],
      );
    } else if (level <= 29) {
      return _Tier(
        title: 'Élève',
        gemstone: 'Améthyste',
        color: IslamicColors.amethystPurple,
        gradient: [IslamicColors.amethystPurple, IslamicColors.softViolet],
      );
    } else if (level <= 39) {
      return _Tier(
        title: 'Serviteur',
        gemstone: 'Émeraude',
        color: IslamicColors.emerald,
        gradient: [IslamicColors.emerald, IslamicColors.emeraldGreen.withValues(alpha: 0.8)],
      );
    } else if (level <= 49) {
      return _Tier(
        title: 'Dévoué',
        gemstone: 'Saphir',
        color: IslamicColors.sapphireBlue,
        gradient: [IslamicColors.sapphireBlue, IslamicColors.mysticBlue],
      );
    } else if (level <= 59) {
      return _Tier(
        title: 'Pieux',
        gemstone: 'Rubis',
        color: IslamicColors.rubyRed,
        gradient: [IslamicColors.rubyRed, Colors.redAccent],
      );
    } else if (level <= 69) {
      return _Tier(
        title: 'Bienfaisant',
        gemstone: 'Opale',
        color: IslamicColors.opalIridescent,
        gradient: [IslamicColors.opalIridescent, Colors.white],
      );
    } else if (level <= 79) {
      return _Tier(
        title: 'Exemplaire',
        gemstone: 'Onyx',
        color: IslamicColors.onyx,
        gradient: [IslamicColors.onyx, Colors.black87],
      );
    } else if (level <= 99) {
      return _Tier(
        title: 'Éminent',
        gemstone: 'Diamant',
        color: Colors.lightBlueAccent,
        gradient: [Colors.white, IslamicColors.opalIridescent],
      );
    } else {
      return _Tier(
        title: 'Maqām al‑Ihsān',
        gemstone: 'Diamant Éthéré',
        color: Colors.white,
        gradient: [Colors.white, IslamicColors.opalIridescent],
      );
    }
  }
}

class _Tier {
  final String title;
  final String gemstone;
  final Color color;
  final List<Color> gradient;
  _Tier({required this.title, required this.gemstone, required this.color, required this.gradient});
}
