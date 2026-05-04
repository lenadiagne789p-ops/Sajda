import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sajda/models/morning_evening_dhikr.dart';
import 'package:sajda/models/rabbana_duas.dart';
import 'package:sajda/theme.dart';

class RabbanaPage extends StatefulWidget {
  const RabbanaPage({super.key});

  @override
  State<RabbanaPage> createState() => _RabbanaPageState();
}

class _RabbanaPageState extends State<RabbanaPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  late List<DhikrItem> _all;
  late List<DhikrItem> _filtered;

  @override
  void initState() {
    super.initState();
    _all = RabbanaDuas.all();
    _filtered = List.of(_all);
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = List.of(_all));
      return;
    }
    setState(() {
      _filtered = _all.where((d) {
        final a = d.arabicText.toLowerCase();
        final t = d.transliteration.toLowerCase();
        final m = d.meaning.toLowerCase();
        final s = (d.source ?? '').toLowerCase();
        return a.contains(q) || t.contains(q) || m.contains(q) || s.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.emeraldAurora,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildSearchBar(context),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) => _RabbanaCard(item: _filtered[index]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'رَبَّنَا — Invocations du Coran',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${_all.length} invocations disponibles',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: TextField(
          controller: _searchCtrl,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Rechercher (arabe, translittération, français, référence)…',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
    );
  }
}

class _RabbanaCard extends StatelessWidget {
  final DhikrItem item;
  const _RabbanaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (item.color).withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.source ?? 'Coran',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: item.color,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: IslamicColors.mysticBlue),
                  onPressed: () {
                    final text = '"${item.arabicText}"\n\n${item.transliteration}\n\n${item.meaning}\n\n${item.source ?? ''}';
                    _share(context, text);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: IslamicColors.emeraldGreen),
                  onPressed: () {
                    _copy(context, '${item.arabicText}\n\n${item.transliteration}\n\n${item.meaning}');
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.arabicText,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: item.color,
                      height: 1.7,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item.transliteration,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: IslamicColors.mysticBlue,
                    fontStyle: FontStyle.italic,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              item.meaning,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[800],
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copié dans le presse‑papiers')),
      );
    }
  }

  void _share(BuildContext context, String text) {
    // Simple share via SnackBar hint; replace with Share.share if package is added
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Prêt à partager:\n\n$text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
