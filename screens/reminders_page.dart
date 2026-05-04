import 'package:flutter/material.dart';
import 'package:sajda/models/reminder.dart';
import 'package:sajda/services/reminder_service.dart';
import 'package:sajda/theme.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _reminders = ReminderService.getReminders();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: _buildGradientBackground(),
          child: const Center(
            child: CircularProgressIndicator(
              color: IslamicColors.emeraldGreen,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(20.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildInfoCard(),
                    const SizedBox(height: 24),
                    ..._buildRemindersByType(),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminderDialog,
        backgroundColor: IslamicColors.emeraldGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nouveau Rappel',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          IslamicColors.pearlWhite,
          IslamicColors.pearlWhite.withValues(alpha: 0.8),
          Colors.white.withValues(alpha: 0.9),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Rappels Spirituels',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: IslamicColors.emeraldGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            IslamicColors.emeraldGreen.withValues(alpha: 0.1),
            IslamicColors.roseGold.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: IslamicColors.emeraldGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: IslamicColors.emeraldGreen,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Configuration des Rappels',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: IslamicColors.emeraldGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Recevez des rappels personnalisés pour vos pratiques spirituelles quotidiennes. Activez ou désactivez selon vos besoins.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRemindersByType() {
    final Map<ReminderType, List<Reminder>> remindersByType = {};
    
    for (final reminder in _reminders) {
      if (!remindersByType.containsKey(reminder.type)) {
        remindersByType[reminder.type] = [];
      }
      remindersByType[reminder.type]!.add(reminder);
    }

    final List<Widget> widgets = [];
    
    for (final type in ReminderType.values) {
      if (remindersByType.containsKey(type)) {
        widgets.add(_buildTypeSection(type, remindersByType[type]!));
        widgets.add(const SizedBox(height: 24));
      }
    }

    return widgets;
  }

  Widget _buildTypeSection(ReminderType type, List<Reminder> reminders) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(type.icon, color: type.color, size: 24),
            const SizedBox(width: 12),
            Text(
              type.displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: type.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${reminders.where((r) => r.isActive).length}/${reminders.length}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...reminders.map((reminder) => _buildReminderCard(reminder)),
      ],
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: reminder.isActive
              ? reminder.type.color.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: reminder.isActive
                            ? IslamicColors.emeraldGreen
                            : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reminder.message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: reminder.isActive,
                onChanged: (value) async {
                  await ReminderService.toggleReminder(reminder.id);
                  _loadReminders();
                },
                activeColor: reminder.type.color,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                ReminderService.formatTime(reminder.time),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: reminder.type.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _getDaysText(reminder.days),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showEditReminderDialog(reminder),
                icon: Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
              ),
              IconButton(
                onPressed: () => _deleteReminder(reminder.id),
                icon: Icon(Icons.delete, size: 16, color: Colors.red[400]),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDaysText(List<int> days) {
    if (days.length == 7) return 'Tous les jours';
    if (days.length == 5 && days.every((day) => day <= 5)) return 'En semaine';
    if (days.length == 2 && days.contains(6) && days.contains(7)) return 'Week-end';
    
    final dayNames = ReminderService.getDayNames();
    return days.map((day) => dayNames[day - 1]).join(', ');
  }

  void _showAddReminderDialog() {
    _showReminderDialog(null);
  }

  void _showEditReminderDialog(Reminder reminder) {
    _showReminderDialog(reminder);
  }

  void _showReminderDialog(Reminder? reminder) {
    showDialog(
      context: context,
      builder: (context) => ReminderDialog(
        reminder: reminder,
        onSave: (newReminder) async {
          if (reminder == null) {
            await ReminderService.addReminder(newReminder);
          } else {
            await ReminderService.updateReminder(newReminder);
          }
          _loadReminders();
        },
      ),
    );
  }

  void _deleteReminder(String reminderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer le rappel',
          style: TextStyle(color: IslamicColors.emeraldGreen),
        ),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce rappel ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ReminderService.deleteReminder(reminderId);
              _loadReminders();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
            ),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class ReminderDialog extends StatefulWidget {
  final Reminder? reminder;
  final Function(Reminder) onSave;

  const ReminderDialog({super.key, this.reminder, required this.onSave});

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _arabicMessageController = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  List<int> _selectedDays = [1, 2, 3, 4, 5, 6, 7];
  ReminderType _selectedType = ReminderType.general;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      final reminder = widget.reminder!;
      _titleController.text = reminder.title;
      _messageController.text = reminder.message;
      _arabicMessageController.text = reminder.arabicMessage;
      _selectedTime = reminder.time;
      _selectedDays = List.from(reminder.days);
      _selectedType = reminder.type;
      _isActive = reminder.isActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.reminder == null ? 'Nouveau Rappel' : 'Modifier le Rappel',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: IslamicColors.emeraldGreen,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _arabicMessageController,
              maxLines: 2,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'Message en Arabe',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReminderType>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: ReminderType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(type.icon, color: type.color, size: 20),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Heure'),
              subtitle: Text(ReminderService.formatTime(_selectedTime)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (picked != null) {
                  setState(() {
                    _selectedTime = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Text('Jours de la semaine', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                final day = index + 1;
                final dayName = ReminderService.getDayNames()[index];
                final isSelected = _selectedDays.contains(day);
                
                return FilterChip(
                  label: Text(dayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    });
                  },
                  selectedColor: IslamicColors.emeraldGreen.withValues(alpha: 0.3),
                  checkmarkColor: IslamicColors.emeraldGreen,
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty && _selectedDays.isNotEmpty) {
              final reminder = Reminder(
                id: widget.reminder?.id ?? 'reminder_${DateTime.now().millisecondsSinceEpoch}',
                title: _titleController.text,
                message: _messageController.text,
                arabicMessage: _arabicMessageController.text,
                time: _selectedTime,
                days: _selectedDays,
                isActive: _isActive,
                type: _selectedType,
              );
              
              widget.onSave(reminder);
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: IslamicColors.emeraldGreen,
          ),
          child: const Text('Sauvegarder', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}