import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sajda/models/dhikr_counter.dart';
import 'package:sajda/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DhikrCounterPage extends StatefulWidget {
  const DhikrCounterPage({super.key});

  @override
  State<DhikrCounterPage> createState() => _DhikrCounterPageState();
}

class _DhikrCounterPageState extends State<DhikrCounterPage>
    with TickerProviderStateMixin {
  List<DhikrItem> _dhikrList = [];
  List<DhikrItem> _customDhikrList = [];
  int _selectedDhikrIndex = 0;
  late AnimationController _counterController;
  late AnimationController _progressController;
  late Animation<double> _scaleAnimation;
  static const String _customDhikrKey = 'custom_dhikr_list';

  @override
  void initState() {
    super.initState();
    _dhikrList = DhikrItem.getDefaultDhikrList();
    _loadCustomDhikr();

    _counterController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _counterController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _counterController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomDhikr() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_customDhikrKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = json.decode(raw);
        final customs = decoded.map((e) => DhikrItem(
          id: e['id'] as String,
          arabic: e['arabic'] as String? ?? '',
          transliteration: e['transliteration'] as String? ?? '',
          french: e['french'] as String,
          meaning: e['meaning'] as String? ?? '',
          benefit: e['benefit'] as String? ?? 'Dhikr personnalisé',
          targetCount: e['targetCount'] as int? ?? 33,
          hassanatPerRecitation: e['hassanatPerRecitation'] as int? ?? 1,
          icon: Icons.favorite,
          color: const Color(0xFFE91E63),
        )).toList();
        if (mounted) {
          setState(() {
            _customDhikrList = customs;
            _dhikrList = [...DhikrItem.getDefaultDhikrList(), ..._customDhikrList];
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _saveCustomDhikr() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(_customDhikrList.map((d) => {
        'id': d.id,
        'arabic': d.arabic,
        'transliteration': d.transliteration,
        'french': d.french,
        'meaning': d.meaning,
        'benefit': d.benefit,
        'targetCount': d.targetCount,
        'hassanatPerRecitation': d.hassanatPerRecitation,
      }).toList());
      await prefs.setString(_customDhikrKey, encoded);
    } catch (_) {}
  }

  void _incrementCounter() {
    HapticFeedback.lightImpact();

    setState(() {
      final currentDhikr = _dhikrList[_selectedDhikrIndex];
      _dhikrList[_selectedDhikrIndex] = currentDhikr.copyWith(
        currentCount: currentDhikr.currentCount + 1,
      );
    });

    _counterController.forward().then((_) {
      _counterController.reverse();
    });

    final updatedDhikr = _dhikrList[_selectedDhikrIndex];
    if (updatedDhikr.currentCount == updatedDhikr.targetCount) {
      _progressController.forward();
      _showCompletionDialog(updatedDhikr);
    }
  }

  void _resetCounter() {
    setState(() {
      final currentDhikr = _dhikrList[_selectedDhikrIndex];
      _dhikrList[_selectedDhikrIndex] = currentDhikr.copyWith(currentCount: 0);
    });
    _progressController.reset();
  }

  void _showCompletionDialog(DhikrItem dhikr) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.stars, color: IslamicColors.roseGold),
            const SizedBox(width: 8),
            const Text('ماشاء الله!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dhikr.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(dhikr.icon, color: dhikr.color, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    dhikr.arabic.isNotEmpty ? dhikr.arabic : dhikr.french,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: dhikr.color,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Objectif atteint!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+${dhikr.totalHassanat} Hassanat',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: IslamicColors.emeraldGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetCounter();
            },
            child: const Text('Recommencer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: IslamicColors.emeraldGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomDhikrDialog() {
    final frenchController = TextEditingController();
    final arabicController = TextEditingController();
    final translitController = TextEditingController();
    final targetController = TextEditingController(text: '33');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.add_circle, color: IslamicColors.emeraldGreen),
            const SizedBox(width: 8),
            const Text('Ajouter un Dhikr'),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: frenchController,
                  decoration: const InputDecoration(
                    labelText: 'Nom (Français) *',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: arabicController,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'Texte arabe (optionnel)',
                    prefixIcon: Icon(Icons.text_fields),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: translitController,
                  decoration: const InputDecoration(
                    labelText: 'Translittération (optionnel)',
                    prefixIcon: Icon(Icons.translate),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de répétitions *',
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Champ requis';
                    final n = int.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Entrez un nombre valide';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: IslamicColors.emeraldGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final newDhikr = DhikrItem(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                arabic: arabicController.text.trim(),
                transliteration: translitController.text.trim(),
                french: frenchController.text.trim(),
                meaning: 'Dhikr personnalisé',
                benefit: 'Invocation personnalisée',
                targetCount: int.parse(targetController.text.trim()),
                hassanatPerRecitation: 1,
                icon: Icons.favorite,
                color: const Color(0xFFE91E63),
              );
              setState(() {
                _customDhikrList.add(newDhikr);
                _dhikrList = [
                  ...DhikrItem.getDefaultDhikrList(),
                  ..._customDhikrList
                ];
              });
              _saveCustomDhikr();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('«${newDhikr.french}» ajouté !'),
                  backgroundColor: IslamicColors.emeraldGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _deleteCustomDhikr(DhikrItem dhikr) {
    setState(() {
      _customDhikrList.removeWhere((d) => d.id == dhikr.id);
      _dhikrList = [
        ...DhikrItem.getDefaultDhikrList(),
        ..._customDhikrList
      ];
      if (_selectedDhikrIndex >= _dhikrList.length) {
        _selectedDhikrIndex = 0;
      }
    });
    _saveCustomDhikr();
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildDhikrSelector(),
                      const SizedBox(height: 30),
                      _buildMainCounter(),
                      const SizedBox(height: 30),
                      _buildProgressIndicator(),
                      const SizedBox(height: 30),
                      _buildStatisticsCard(),
                      const SizedBox(height: 20),
                      _buildBenefitCard(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              _buildCounterButtons(),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground() {
    final selectedDhikr = _dhikrList[_selectedDhikrIndex];
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          selectedDhikr.color.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.95),
          IslamicColors.pearlWhite,
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: IslamicColors.emeraldGreen),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'المسبحة الإلكترونية',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: IslamicColors.emeraldGreen,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Bouton pour ajouter un dhikr personnalisé
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: IslamicColors.emeraldGreen),
            tooltip: 'Ajouter un Dhikr personnalisé',
            onPressed: _showAddCustomDhikrDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildDhikrSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _dhikrList.length,
            itemBuilder: (context, index) {
              final dhikr = _dhikrList[index];
              final isSelected = index == _selectedDhikrIndex;
              final isCustom = _customDhikrList.any((c) => c.id == dhikr.id);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDhikrIndex = index;
                  });
                  _progressController.reset();
                },
                onLongPress: isCustom
                    ? () => _confirmDeleteCustomDhikr(dhikr)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(12),
                  width: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                          ? [
                              dhikr.color.withValues(alpha: 0.2),
                              dhikr.color.withValues(alpha: 0.1),
                            ]
                          : [
                              Colors.grey.withValues(alpha: 0.1),
                              Colors.grey.withValues(alpha: 0.05),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? dhikr.color
                          : Colors.grey.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            dhikr.icon,
                            color: isSelected ? dhikr.color : Colors.grey[600],
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dhikr.french,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected ? dhikr.color : Colors.grey[600],
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      // Badge "personnalisé"
                      if (isCustom)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE91E63),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, size: 10, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Bouton "Ajouter un dhikr" en bas du sélecteur
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _showAddCustomDhikrDialog,
            icon: const Icon(Icons.add, size: 16, color: IslamicColors.emeraldGreen),
            label: const Text(
              'Ajouter un dhikr personnalisé',
              style: TextStyle(color: IslamicColors.emeraldGreen, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteCustomDhikr(DhikrItem dhikr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce Dhikr ?'),
        content: Text('Voulez-vous supprimer «${dhikr.french}» de vos dhikrs personnalisés ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteCustomDhikr(dhikr);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCounter() {
    final selectedDhikr = _dhikrList[_selectedDhikrIndex];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            selectedDhikr.color.withValues(alpha: 0.1),
            selectedDhikr.color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selectedDhikr.color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            selectedDhikr.arabic.isNotEmpty ? selectedDhikr.arabic : selectedDhikr.french,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: selectedDhikr.color,
              fontWeight: FontWeight.bold,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            textDirection: selectedDhikr.arabic.isNotEmpty ? TextDirection.rtl : TextDirection.ltr,
          ),
          if (selectedDhikr.transliteration.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              selectedDhikr.transliteration,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selectedDhikr.color.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            selectedDhikr.french,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ScaleTransition(
            scale: _scaleAnimation,
            child: Text(
              '${selectedDhikr.currentCount}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: selectedDhikr.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            '/ ${selectedDhikr.targetCount}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final selectedDhikr = _dhikrList[_selectedDhikrIndex];
    final progress = selectedDhikr.targetCount > 0
        ? selectedDhikr.currentCount / selectedDhikr.targetCount
        : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progression',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selectedDhikr.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 10,
            backgroundColor: Colors.grey.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(selectedDhikr.color),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    final selectedDhikr = _dhikrList[_selectedDhikrIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.repeat,
            label: 'Répétitions',
            value: '${selectedDhikr.currentCount}',
            color: selectedDhikr.color,
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildStatItem(
            icon: Icons.stars,
            label: 'Hassanat',
            value: '+${selectedDhikr.currentCount * selectedDhikr.hassanatPerRecitation}',
            color: IslamicColors.roseGold,
          ),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _buildStatItem(
            icon: Icons.flag,
            label: 'Objectif',
            value: '${selectedDhikr.targetCount}',
            color: IslamicColors.emeraldGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitCard() {
    final selectedDhikr = _dhikrList[_selectedDhikrIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            selectedDhikr.color.withValues(alpha: 0.08),
            selectedDhikr.color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selectedDhikr.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: selectedDhikr.color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Vertu & Bénéfice',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selectedDhikr.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            selectedDhikr.benefit,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          if (selectedDhikr.reference != null) ...[
            const SizedBox(height: 8),
            Text(
              'Référence: ${selectedDhikr.reference}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selectedDhikr.color.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCounterButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Bouton reset
          IconButton(
            onPressed: _resetCounter,
            icon: const Icon(Icons.refresh),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.withValues(alpha: 0.1),
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(width: 16),
          // Bouton principal de comptage
          Expanded(
            child: GestureDetector(
              onTap: _incrementCounter,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _dhikrList[_selectedDhikrIndex].color,
                      _dhikrList[_selectedDhikrIndex].color.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _dhikrList[_selectedDhikrIndex].color.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'ذِكْر',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
