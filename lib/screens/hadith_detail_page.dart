import 'package:flutter/material.dart';
import 'package:sajda/models/islamic_action.dart';
import 'package:sajda/theme.dart';

class HadithDetailPage extends StatefulWidget {
  final IslamicAction hadithAction;
  final Function(String) onActionCompleted;

  const HadithDetailPage({
    super.key,
    required this.hadithAction,
    required this.onActionCompleted,
  });

  @override
  State<HadithDetailPage> createState() => _HadithDetailPageState();
}

class _HadithDetailPageState extends State<HadithDetailPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  int _currentHadithIndex = 0;
  bool _isBookmarked = false;

  // Collection de hadiths supplémentaires pour l'étude
  final List<Map<String, String>> _additionalHadiths = [
    {
      'text': 'D\'après Abou Hourayra (qu\'Allah l\'agrée), le Prophète ﷺ a dit : "Celui qui croit en Allah et au jour dernier qu\'il dise du bien ou qu\'il se taise".',
      'source': 'Rapporté par Bukhari et Muslim',
      'lesson': 'Ce hadith enseigne l\'importance de parler avec sagesse et de éviter les paroles nuisibles.',
    },
    {
      'text': 'Le Prophète ﷺ a dit : "Le croyant n\'est pas celui qui se rassasie alors que son voisin a faim".',
      'source': 'Rapporté par Bukhari dans Al-Adab Al-Mufrad',
      'lesson': 'L\'Islam encourage la solidarité et le partage avec ses voisins, quelle que soit leur religion.',
    },
    {
      'text': 'D\'après Anas ibn Malik, le Prophète ﷺ a dit : "Aucun d\'entre vous ne croira vraiment tant qu\'il n\'aimera pas pour son frère ce qu\'il aime pour lui-même".',
      'source': 'Rapporté par Bukhari et Muslim',
      'lesson': 'Ce hadith établit un principe fondamental de fraternité et d\'empathie entre les croyants.',
    },
    {
      'text': 'Le Prophète ﷺ a dit : "Les actions ne valent que par les intentions, et chacun n\'obtiendra que ce qu\'il a eu l\'intention de faire".',
      'source': 'Rapporté par Bukhari et Muslim',
      'lesson': 'L\'intention (niyyah) est cruciale dans l\'Islam. Une bonne intention transforme les actes ordinaires en adorations.',
    },
    {
      'text': 'D\'après Abou Dharr, le Prophète ﷺ a dit : "Crains Allah où que tu sois, fais suivre la mauvaise action par une bonne qui l\'efface, et comporte-toi avec les gens avec un bon caractère".',
      'source': 'Rapporté par Tirmidhi',
      'lesson': 'Ce hadith résume trois piliers de la spiritualité islamique : la taqwa, la repentance par les bonnes œuvres, et le bon comportement.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _nextHadith() {
    setState(() {
      _currentHadithIndex = (_currentHadithIndex + 1) % _additionalHadiths.length;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  void _previousHadith() {
    setState(() {
      _currentHadithIndex = _currentHadithIndex > 0 
          ? _currentHadithIndex - 1 
          : _additionalHadiths.length - 1;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  void _toggleBookmark() {
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? 'Hadith ajouté aux favoris' : 'Hadith retiré des favoris'),
        backgroundColor: const Color(0xFF8D6E63),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _completeStudy() {
    widget.onActionCompleted(widget.hadithAction.id);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.school, color: Color(0xFF8D6E63)),
            SizedBox(width: 8),
            Text('Étude Terminée!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vous avez étudié les hadiths avec attention.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '+${widget.hadithAction.hassanatReward} Hassanat gagnés!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: IslamicColors.emeraldGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentHadith = _additionalHadiths[_currentHadithIndex];
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3E5F5),
              Color(0xFFFAF9F9),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildActionCard(),
                    const SizedBox(height: 20),
                    _buildHadithCard(currentHadith),
                    const SizedBox(height: 20),
                    _buildNavigationControls(),
                    const SizedBox(height: 20),
                    _buildProgressIndicator(),
                    const SizedBox(height: 20),
                    _buildCompleteButton(),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF8D6E63).withValues(alpha: 0.1),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF8D6E63)),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: const Color(0xFF8D6E63),
          ),
          onPressed: _toggleBookmark,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Étude des Hadiths',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFF8D6E63),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8D6E63).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chrome_reader_mode,
                  color: Color(0xFF8D6E63),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.hadithAction.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF8D6E63),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.hadithAction.arabicTitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: IslamicColors.roseGold,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: Color(0xFF8D6E63), size: 16),
                const SizedBox(width: 4),
                Text(
                  '+${widget.hadithAction.hassanatReward} Hassanat',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8D6E63),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHadithCard(Map<String, String> hadith) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Hadith ${_currentHadithIndex + 1}/${_additionalHadiths.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8D6E63),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF8D6E63).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF8D6E63).withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                hadith['text']!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: Colors.grey[800],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hadith['source']!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8D6E63).withValues(alpha: 0.1),
                    const Color(0xFF8D6E63).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Color(0xFF8D6E63), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Enseignement',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF8D6E63),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hadith['lesson']!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavButton(
          Icons.arrow_back,
          'Précédent',
          _previousHadith,
          _currentHadithIndex > 0,
        ),
        _buildNavButton(
          Icons.arrow_forward,
          'Suivant',
          _nextHadith,
          _currentHadithIndex < _additionalHadiths.length - 1,
        ),
      ],
    );
  }

  Widget _buildNavButton(IconData icon, String label, VoidCallback onTap, bool enabled) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF8D6E63).withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: enabled
                ? const Color(0xFF8D6E63).withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: enabled ? const Color(0xFF8D6E63) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: enabled ? const Color(0xFF8D6E63) : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = (_currentHadithIndex + 1) / _additionalHadiths.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF8D6E63),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_currentHadithIndex + 1}/${_additionalHadiths.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8D6E63)),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton() {
    final isCompleted = widget.hadithAction.isCompleted;
    
    return GestureDetector(
      onTap: isCompleted ? null : _completeStudy,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isCompleted
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF8D6E63), Color(0xFF6D4C41)],
                ),
          color: isCompleted ? Colors.grey[300] : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isCompleted
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF8D6E63).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.school,
              color: isCompleted ? Colors.grey[600] : Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              isCompleted ? 'Étude Déjà Terminée' : 'Terminer l\'Étude',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isCompleted ? Colors.grey[600] : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}