import 'package:flutter/material.dart';
import 'package:sajda/models/islamic_action.dart';
import 'package:sajda/services/storage_service.dart';
import 'package:sajda/theme.dart';

class PinnedActionsReorderPage extends StatefulWidget {
  const PinnedActionsReorderPage({super.key});

  @override
  State<PinnedActionsReorderPage> createState() => _PinnedActionsReorderPageState();
}

class _PinnedActionsReorderPageState extends State<PinnedActionsReorderPage> {
  List<String> _order = <String>[];
  final Map<String, IslamicAction> _byId = {
    for (final a in IslamicAction.getDefaultActions()) a.id: a,
  };
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final order = await StorageService.getPinnedActionOrder();
    setState(() => _order = List<String>.from(order));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await StorageService.setPinnedActionsOrder(_order);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Réorganiser les épinglés',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: IslamicColors.emeraldGreen,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check, color: IslamicColors.emeraldGreen),
            label: Text('Enregistrer', style: TextStyle(color: _saving ? Colors.grey : IslamicColors.emeraldGreen)),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              IslamicColors.pearlWhite,
              IslamicColors.pearlWhite.withValues(alpha: 0.85),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: _order.isEmpty
              ? Center(
                  child: Text(
                    'Aucune action épinglée',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _order.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _order.removeAt(oldIndex);
                      _order.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final id = _order[index];
                    final action = _byId[id];
                    if (action == null) {
                      return const SizedBox.shrink(key: ValueKey('missing'));
                    }
                    return Container(
                      key: ValueKey(id),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: IslamicColors.emeraldGreen.withValues(alpha: 0.2)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: IslamicColors.emeraldGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(action.icon, color: IslamicColors.emeraldGreen, size: 22),
                        ),
                        title: Text(action.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: IslamicColors.emeraldGreen, fontWeight: FontWeight.w600)),
                        subtitle: Text(action.arabicTitle, textDirection: TextDirection.rtl, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: IslamicColors.roseGold)),
                        trailing: const Icon(Icons.drag_handle, color: Colors.grey),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
