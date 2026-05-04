import 'package:flutter/material.dart';
import 'package:sajda/theme.dart';

/// Légende complète des règles du Tajwid avec code couleur et significations.
class TajweedLegendWidget extends StatelessWidget {
  const TajweedLegendWidget({super.key});

  /// Affiche la légende dans un BottomSheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const TajweedLegendWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: IslamicColors.emeraldGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.palette,
                    color: IslamicColors.emeraldGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Règles du Tajwid',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Code couleur et significations',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _sectionTitle(theme, 'Règles de prononciation'),
                const SizedBox(height: 8),
                ..._tajweedRules.map((r) => _ruleCard(theme, cs, r)),
                const SizedBox(height: 20),
                _sectionTitle(theme, 'Voyelles (Tashkil)'),
                const SizedBox(height: 8),
                ..._vowelRules.map((r) => _ruleCard(theme, cs, r)),
                const SizedBox(height: 24),
                _infoNote(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String title) => Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: IslamicColors.emeraldGreen,
          letterSpacing: 0.5,
        ),
      );

  Widget _ruleCard(ThemeData theme, ColorScheme cs, _TajweedRule rule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rule.color.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: rule.color.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicateur couleur avec exemple arabe
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: rule.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: rule.color, width: 2),
              ),
              child: Center(
                child: Text(
                  rule.arabicExample,
                  style: TextStyle(
                    color: rule.color,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        rule.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: rule.color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: rule.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rule.arabicName,
                          style: TextStyle(
                            color: rule.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    rule.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                  if (rule.example.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: rule.color.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '📖 ${rule.example}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: rule.color.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoNote(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: IslamicColors.emeraldGreen.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: IslamicColors.emeraldGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              color: IslamicColors.emeraldGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Le Tajwid est l\'ensemble des règles de récitation du Coran. '
              'Ces couleurs sont une aide visuelle pour identifier les règles '
              'de prononciation. Activez le mode Tajwid via le bouton "Tajwid" '
              'dans le lecteur pour voir ces couleurs sur le texte arabe.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: IslamicColors.emeraldGreen,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TajweedRule {
  final String name;
  final String arabicName;
  final String arabicExample;
  final Color color;
  final String description;
  final String example;

  const _TajweedRule({
    required this.name,
    required this.arabicName,
    required this.arabicExample,
    required this.color,
    required this.description,
    this.example = '',
  });
}

const List<_TajweedRule> _tajweedRules = [
  _TajweedRule(
    name: 'Ghunnah',
    arabicName: 'غُنَّة',
    arabicExample: 'نّ',
    color: IslamicColors.tajweedGhunnah,
    description:
        'Nasalisation : son nasal produit par le nez lors de la prononciation '
        'du Noun (ن) ou du Meem (م) avec une Shadda. Durée : 2 temps.',
    example: 'إِنَّ — "Inna" (le Noun avec Shadda)',
  ),
  _TajweedRule(
    name: 'Qalqalah',
    arabicName: 'قَلْقَلَة',
    arabicExample: 'قْ',
    color: IslamicColors.tajweedQalqalah,
    description:
        'Écho/vibration : légère résonance produite lors de la prononciation '
        'des 5 lettres (ق ط ب ج د) en état de sukun. Plus prononcée en fin de verset.',
    example: 'يَقْطَعُ — le "Qaf" avec sukun',
  ),
  _TajweedRule(
    name: 'Idgham',
    arabicName: 'إِدْغَام',
    arabicExample: 'نْي',
    color: IslamicColors.tajweedIdgham,
    description:
        'Fusion : le Noun sakin (ن) ou le Tanween se fond dans la lettre '
        'suivante parmi (ي ر م ل و ن). Avec ou sans Ghunnah selon la lettre.',
    example: 'مِن يَقُولُ — le Noun se fond dans le Yaa',
  ),
  _TajweedRule(
    name: 'Ikhfa',
    arabicName: 'إِخْفَاء',
    arabicExample: 'نْت',
    color: IslamicColors.tajweedIkhfa,
    description:
        'Dissimulation : le Noun sakin ou le Tanween est prononcé de manière '
        'atténuée devant 15 lettres spécifiques. Durée : 2 temps avec nasalisation.',
    example: 'مِنْ تَحْتِهَا — le Noun avant le Taa',
  ),
  _TajweedRule(
    name: 'Iqlab',
    arabicName: 'إِقْلَاب',
    arabicExample: 'نْب',
    color: IslamicColors.tajweedIqlab,
    description:
        'Transformation : le Noun sakin ou le Tanween se transforme en son '
        'de Meem (م) nasalisé lorsqu\'il est suivi de la lettre Baa (ب).',
    example: 'مِنْ بَعْدِ — le Noun devient un Meem nasal',
  ),
];

const List<_TajweedRule> _vowelRules = [
  _TajweedRule(
    name: 'Fatha',
    arabicName: 'فَتْحَة',
    arabicExample: 'َ',
    color: IslamicColors.vowelFatha,
    description:
        'Voyelle courte "a" : trait horizontal au-dessus de la lettre. '
        'Prononciation : son "a" court comme dans "chat".',
    example: 'كَتَبَ — "kataba"',
  ),
  _TajweedRule(
    name: 'Kasra',
    arabicName: 'كَسْرَة',
    arabicExample: 'ِ',
    color: IslamicColors.vowelKasra,
    description:
        'Voyelle courte "i" : trait horizontal sous la lettre. '
        'Prononciation : son "i" court comme dans "lit".',
    example: 'بِسْمِ — "bismi"',
  ),
  _TajweedRule(
    name: 'Damma',
    arabicName: 'ضَمَّة',
    arabicExample: 'ُ',
    color: IslamicColors.vowelDamma,
    description:
        'Voyelle courte "u" : petit waw au-dessus de la lettre. '
        'Prononciation : son "ou" court comme dans "loup".',
    example: 'كُتِبَ — "kutiba"',
  ),
  _TajweedRule(
    name: 'Sukun',
    arabicName: 'سُكُون',
    arabicExample: 'ْ',
    color: IslamicColors.vowelSukun,
    description:
        'Repos/silence : petit cercle au-dessus de la lettre indiquant '
        'l\'absence de voyelle. La lettre est prononcée sans son vocalique.',
    example: 'مَلِكْ — le Kaf final sans voyelle',
  ),
  _TajweedRule(
    name: 'Shadda',
    arabicName: 'شَدَّة',
    arabicExample: 'ّ',
    color: IslamicColors.vowelShadda,
    description:
        'Doublement : signe en forme de "w" indiquant que la lettre est '
        'doublée. La lettre est prononcée deux fois : sans voyelle puis avec voyelle.',
    example: 'مَدَّ — "madda" (le Dal est doublé)',
  ),
  _TajweedRule(
    name: 'Tanween',
    arabicName: 'تَنْوِين',
    arabicExample: 'ً',
    color: IslamicColors.vowelTanween,
    description:
        'Nunation : double voyelle en fin de mot indiquant un "n" final. '
        'Tanween Fath (ً) = "an", Tanween Kasra (ٍ) = "in", Tanween Damm (ٌ) = "un".',
    example: 'كِتَابًا — "kitaaban"',
  ),
];
