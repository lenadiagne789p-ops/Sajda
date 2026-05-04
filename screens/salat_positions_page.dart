import 'package:flutter/material.dart';
import 'package:sajda/models/salat_course.dart';
import 'package:sajda/screens/salat_mastery_page.dart';
import 'package:sajda/theme.dart';
import 'package:sajda/services/salat_asset_service.dart';
import 'package:sajda/data/salat_media.dart';

class SalatPositionsPage extends StatefulWidget {
  const SalatPositionsPage({super.key});

  @override
  State<SalatPositionsPage> createState() => _SalatPositionsPageState();
}

class _SalatPositionsPageState extends State<SalatPositionsPage> with TickerProviderStateMixin {
  int _selectedPositionIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Map<SalatStepType, List<String>> _localImages = const {};
  List<String> _qawmahImages = const [];
  
  final List<SalatPositionGuide> _positions = [
    SalatPositionGuide(
      name: 'Qiyâm (Position debout)',
      arabicName: 'قيام',
      type: SalatStepType.standing,
      description: 'Position de départ de la prière. Tenez-vous debout face à la Qibla, les pieds légèrement écartés.',
      instructions: [
        'Tenez-vous debout, les pieds parallèles et légèrement écartés',
        'Regardez vers l\'endroit de la prosternation',
        'Placez la main droite sur la main gauche au niveau de la poitrine',
        'Gardez le dos droit et les épaules détendues',
      ],
      benefits: 'Cette position exprime l\'humilité et la concentration devant Allah.',
    ),
    SalatPositionGuide(
      name: 'Rukû\' (Inclinaison)',
      arabicName: 'ركوع',
      type: SalatStepType.bowing,
      description: 'Inclinez-vous en avant en gardant le dos droit, les mains posées sur les genoux.',
      instructions: [
        'Inclinez-vous en avant depuis la taille',
        'Gardez le dos parfaitement droit',
        'Posez les mains sur les genoux, doigts écartés',
        'Regardez vers le sol entre vos pieds',
        'Récitez "Subhâna rabbiya-l-\'azîm" (3x minimum)',
      ],
      benefits: 'L\'inclinaison symbolise la soumission totale à Allah et renforce les muscles du dos.',
    ),
    // Redressement après Rukû' (Qawmah / I'tidāl)
    SalatPositionGuide(
      name: 'Qawmah (Redressement après Rukû\')',
      arabicName: 'قَوْمَة',
      type: SalatStepType.standing,
      description: 'Après l\'inclinaison, redressez-vous complètement en disant: «Samia-llāhu liman hamidah», puis «Rabbanā wa laka-l-hamd».',
      instructions: [
        'Relevez-vous jusqu\'à être totalement droit, sans précipitation',
        'Laissez les bras le long du corps (écoles malikite/hanbalite) ou replacez-les sur la poitrine (écoles hanafite/shaféite) selon votre madhhab',
        'Stabilisez-vous un instant avant de passer au sujûd',
      ],
      benefits: 'Favorise l\'alignement de la colonne et la sérénité entre deux positions majeures.',
      customKey: 'qawmah',
    ),
    SalatPositionGuide(
      name: 'Sujûd (Prosternation)',
      arabicName: 'سجود',
      type: SalatStepType.prostration,
      description: 'Prosternez-vous en touchant le sol avec sept parties du corps.',
      instructions: [
        'Posez le front et le nez sur le sol',
        'Placez les paumes à plat sur le sol, doigts joints',
        'Les genoux touchent le sol',
        'Les orteils pointent vers la Qibla',
        'Gardez les bras légèrement écartés du corps',
        'Récitez "Subhâna rabbiya-l-a\'lâ" (3x minimum)',
      ],
      benefits: 'Position la plus proche d\'Allah, elle développe l\'humilité et favorise la circulation sanguine.',
    ),
    SalatPositionGuide(
      name: 'Julûs (Position assise)',
      arabicName: 'جلوس',
      type: SalatStepType.sitting,
      description: 'Asseyez-vous entre les prosternations ou pour le Tashahhud.',
      instructions: [
        'Asseyez-vous sur le pied gauche plié',
        'Le pied droit reste dressé, orteils vers la Qibla',
        'Placez les mains sur les cuisses',
        'Gardez le dos droit',
        'Pour le Tashahhud, levez l\'index droit lors de l\'attestation',
      ],
      benefits: 'Position de recueillement qui favorise la méditation et la concentration.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _animationController.forward();
    _loadLocalImages();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalImages() async {
    try {
      final map = await SalatAssetService.loadPositionImages();
      final qawmah = await SalatAssetService.loadQawmahImages();
      if (mounted) {
        setState(() {
          _localImages = map;
          _qawmahImages = qawmah;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildPositionSelector(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: _buildPositionDetail(_positions[_selectedPositionIndex])),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground() {
    final selectedPosition = _positions[_selectedPositionIndex];
    return BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
        _getStepTypeColor(selectedPosition.type).withValues(alpha: 0.1),
        IslamicColors.pearlWhite.withValues(alpha: 0.8),
        Colors.white,
      ]),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: IslamicColors.emeraldGreen), onPressed: () => Navigator.pop(context)),
          Expanded(
            child: Text('🧘‍♂️ Positions de la Salat', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: IslamicColors.emeraldGreen, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ),
          IconButton(icon: const Icon(Icons.school, color: IslamicColors.emeraldGreen), tooltip: 'Perfectionner sa Salat', onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SalatMasteryPage()));
          }),
          IconButton(icon: const Icon(Icons.info_outline, color: IslamicColors.emeraldGreen), onPressed: _showGeneralInfo),
        ],
      ),
    );
  }

  Widget _buildPositionSelector() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _positions.length,
        itemBuilder: (context, index) {
          final position = _positions[index];
          final isSelected = index == _selectedPositionIndex;
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedPositionIndex = index);
              _animationController.reset();
              _animationController.forward();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 100,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: [
                        _getStepTypeColor(position.type).withValues(alpha: 0.3),
                        _getStepTypeColor(position.type).withValues(alpha: 0.1),
                      ])
                    : null,
                color: isSelected ? null : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? _getStepTypeColor(position.type) : Colors.grey[300]!, width: isSelected ? 2 : 1),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(_getStepTypeIcon(position.type), color: isSelected ? _getStepTypeColor(position.type) : Colors.grey[600], size: 32),
                const SizedBox(height: 8),
                Text(position.arabicName, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: isSelected ? _getStepTypeColor(position.type) : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(position.name.split(' ')[0], style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isSelected ? _getStepTypeColor(position.type) : Colors.grey[500]), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPositionDetail(SalatPositionGuide position) {
    final accent = _getStepTypeColor(position.type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête de la position
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accent.withValues(alpha: 0.15), accent.withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accent.withValues(alpha: 0.3), width: 2),
          ),
          child: Column(children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: accent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)), child: Icon(_getStepTypeIcon(position.type), color: accent, size: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(position.arabicName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: accent, fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
                  const SizedBox(height: 4),
                  Text(position.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
            const SizedBox(height: 16),
            Text(position.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700], height: 1.5)),
          ]),
        ),

        const SizedBox(height: 24),

          // Visuel principal de la position (n'affiche QUE vos images locales si présentes, sinon une illustration)
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
            child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                  // Visuel de la position: pour Rukû' et Julûs, on privilégie des photos web
                  // sélectionnées (curated). Pour les autres, on montre d'abord les images locales,
                  // puis on retombe sur curated si vide, et enfin sur une illustration minimale.
                  Builder(builder: (context) {
                    final isQawmah = position.customKey == 'qawmah';
                    final localList = isQawmah ? _qawmahImages : (_localImages[position.type] ?? const []);

                    // Curated fallback list (références internet + quelques assets si présents)
                    final curated = SalatMediaRepository.stepImages[isQawmah ? SalatStepType.standing : position.type] ?? const [];

                    // Règle d'affichage spécifiques:
                    //  - Julûs (assis): privilégier VOS images locales (capture d'écran) avant les images web
                    //  - Rukû' (inclinaison): conserver curated en premier, puis locales
                    if (position.type == SalatStepType.sitting) {
                      final combined = [
                        ...localList,
                        ...curated.where((p) => !localList.contains(p)),
                      ];
                      if (combined.isNotEmpty) {
                        return PageView.builder(
                          itemCount: combined.length,
                          itemBuilder: (context, index) => _buildImage(combined[index]),
                        );
                      }
                      return _buildHeroFallback(accent, position);
                    }

                    if (position.type == SalatStepType.bowing) {
                      final combined = [
                        ...curated,
                        ...localList.where((p) => !curated.contains(p)),
                      ];
                      if (combined.isNotEmpty) {
                        return PageView.builder(
                          itemCount: combined.length,
                          itemBuilder: (context, index) => _buildImage(combined[index]),
                        );
                      }
                      return _buildHeroFallback(accent, position);
                    }

                    // Autres positions: locales d'abord
                    if (localList.isNotEmpty) {
                      return PageView.builder(
                        itemCount: localList.length,
                        itemBuilder: (context, index) => _buildImage(localList[index]),
                      );
                    }
                    // puis curated si dispo
                    if (curated.isNotEmpty) {
                      return PageView.builder(
                        itemCount: curated.length,
                        itemBuilder: (context, index) => _buildImage(curated[index]),
                      );
                    }
                    // Sinon: illustration minimale
                    return _buildHeroFallback(accent, position);
                  }),
                // Overlay avec informations
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          position.arabicName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Position authentique dans une mosquée',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Section "Références photos" supprimée à la demande de l'utilisateur

        const SizedBox(height: 24),

        // Instructions détaillées
        _buildInstructionsCard(position),

        const SizedBox(height: 20),

        // Bienfaits
        _buildBenefitsCard(position),

        const SizedBox(height: 20),
      ],
    );
  }

  /// Fallback visuel si aucune image n'est disponible
  Widget _buildHeroFallback(Color accent, SalatPositionGuide position) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent.withValues(alpha: 0.1), accent.withValues(alpha: 0.05)]),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.3), width: 2),
            ),
            child: _buildPositionIllustration(position.type),
          ),
          const SizedBox(height: 16),
          Text(
            position.arabicName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: accent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(SalatPositionGuide position) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.list_alt, color: _getStepTypeColor(position.type), size: 24),
          const SizedBox(width: 8),
          Text('Instructions étape par étape', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _getStepTypeColor(position.type), fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        ...position.instructions.asMap().entries.map((entry) {
          final index = entry.key;
          final instruction = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: _getStepTypeColor(position.type).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text('${index + 1}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _getStepTypeColor(position.type), fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(instruction, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700], height: 1.4))),
            ]),
          );
        }),
      ]),
    );
  }

  /// Helper pour afficher indifféremment une image locale (asset) ou réseau
  Widget _buildImage(String path) {
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }

  Widget _buildBenefitsCard(SalatPositionGuide position) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [IslamicColors.roseGold.withValues(alpha: 0.1), IslamicColors.roseGold.withValues(alpha: 0.05)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IslamicColors.roseGold.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.favorite, color: IslamicColors.roseGold, size: 24),
          const SizedBox(width: 8),
          Text('Bienfaits spirituels et physiques', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: IslamicColors.roseGold, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        Text(position.benefits, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700], height: 1.5)),
      ]),
    );
  }

  // Aucune image par défaut : on s'en tient aux images locales ou à une illustration.

  void _showGeneralInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.info, color: IslamicColors.emeraldGreen),
          const SizedBox(width: 8),
          const Text('À propos des positions'),
        ]),
        content: const Text(
          'Les positions de la Salat ont été établies par le Prophète Muhammad ﷺ. '
          'Chaque position a sa sagesse spirituelle et ses bienfaits physiques. '
          'La régularité dans ces mouvements constitue un véritable exercice pour le corps et l\'âme.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
      ),
    );
  }

  Color _getStepTypeColor(SalatStepType type) {
    switch (type) {
      case SalatStepType.standing:
        return IslamicColors.emeraldGreen;
      case SalatStepType.bowing:
        return IslamicColors.mysticBlue;
      case SalatStepType.prostration:
        return IslamicColors.roseGold;
      case SalatStepType.sitting:
        return IslamicColors.dustyRose;
      case SalatStepType.transition:
        return Colors.grey;
    }
  }

  IconData _getStepTypeIcon(SalatStepType type) {
    switch (type) {
      case SalatStepType.standing:
        return Icons.accessibility_new;
      case SalatStepType.bowing:
        return Icons.keyboard_arrow_down;
      case SalatStepType.prostration:
        return Icons.keyboard_double_arrow_down;
      case SalatStepType.sitting:
        return Icons.event_seat;
      case SalatStepType.transition:
        return Icons.sync_alt;
    }
  }

  Widget _buildPositionIllustration(SalatStepType type) {
    final color = _getStepTypeColor(type);
    
    switch (type) {
      case SalatStepType.standing:
        return _buildStandingIllustration(color);
      case SalatStepType.bowing:
        return _buildBowingIllustration(color);
      case SalatStepType.prostration:
        return _buildProstrationIllustration(color);
      case SalatStepType.sitting:
        return _buildSittingIllustration(color);
      case SalatStepType.transition:
        return Icon(Icons.sync_alt, size: 40, color: color);
    }
  }

  Widget _buildStandingIllustration(Color color) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      // Tête
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(height: 4),
      // Corps
      Container(width: 8, height: 30, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      // Bras
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 15, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Container(width: 15, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      ]),
      const SizedBox(height: 8),
      // Jambes
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      ]),
    ]);
  }

  Widget _buildBowingIllustration(Color color) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      // Tête inclinée
      Transform.rotate(angle: 0.5, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle))),
      const SizedBox(height: 2),
      // Corps incliné
      Transform.rotate(angle: 0.8, child: Container(width: 6, height: 25, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)))),
      // Bras vers les genoux
      Transform.rotate(
        angle: 0.8,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 12, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Container(width: 12, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        ]),
      ),
      const SizedBox(height: 8),
      // Jambes droites
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      ]),
    ]);
  }

  Widget _buildProstrationIllustration(Color color) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(height: 20),
      // Position prosternation
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        // Tête au sol
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        // Corps plié
        Column(children: [
          Container(width: 20, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 4),
          // Jambes pliées
          Row(children: [
            Container(width: 3, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 3),
            Container(width: 3, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          ]),
        ]),
      ]),
      const SizedBox(height: 8),
      // Base (genoux)
      Container(width: 16, height: 3, decoration: BoxDecoration(color: color.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
    ]);
  }

  Widget _buildSittingIllustration(Color color) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      // Tête
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(height: 4),
      // Corps assis
      Container(width: 6, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(height: 4),
      // Bras sur les cuisses
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 10, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Container(width: 10, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      ]),
      const SizedBox(height: 4),
      // Position assise (jambes pliées)
      Container(width: 20, height: 8, decoration: BoxDecoration(color: color.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4))),
    ]);
  }
}

class SalatPositionGuide {
  final String name;
  final String arabicName;
  final SalatStepType type;
  final String description;
  final List<String> instructions;
  final String benefits;
  final String? customKey; // e.g., 'qawmah' to differentiate special cases from generic type

  SalatPositionGuide({
    required this.name,
    required this.arabicName,
    required this.type,
    required this.description,
    required this.instructions,
    required this.benefits,
    this.customKey,
  });
}
