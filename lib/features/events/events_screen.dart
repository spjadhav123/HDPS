// lib/features/events/events_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/event_model.dart';
import '../../core/providers/event_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/app_date_utils.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/confirm_dialog.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  EventCategory? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(allEventsProvider);
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.role == 'admin';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Events & Calendar',
              subtitle: 'School events and important dates',
              action: isAdmin
                  ? ElevatedButton.icon(
                      onPressed: () => _showAddEventDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Event'),
                    )
                  : null,
            ),
            const SizedBox(height: 20),
            _buildCategoryFilter(),
            const SizedBox(height: 16),
            Expanded(
              child: eventsAsync.when(
                data: (events) {
                  final filtered = _categoryFilter == null
                      ? events
                      : events
                          .where((e) => e.category == _categoryFilter)
                          .toList();

                  if (filtered.isEmpty) {
                    return const EmptyState(
                      emoji: '📅',
                      title: 'No upcoming events',
                      subtitle: 'School events and important dates\nwill appear here.',
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _EventCard(
                      event: filtered[i],
                      index: i,
                      isAdmin: isAdmin,
                      onDelete: () => _deleteEvent(filtered[i]),
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) =>
                    Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip(null, 'All', Icons.grid_view_rounded),
          ...EventCategory.values.map((cat) => _buildCategoryChip(
                cat,
                cat.categoryLabel,
                _categoryIcon(cat),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
      EventCategory? cat, String label, IconData icon) {
    final isSelected = _categoryFilter == cat;
    final color = cat == null ? AppTheme.primary : _categoryColor(cat);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        avatar: Icon(icon, size: 14, color: isSelected ? color : AppTheme.textSecondary),
        label: Text(label),
        onSelected: (_) =>
            setState(() => _categoryFilter = cat),
        selectedColor: color.withOpacity(0.15),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isSelected ? color : AppTheme.textSecondary,
          fontWeight:
              isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 12,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  IconData _categoryIcon(EventCategory cat) {
    switch (cat) {
      case EventCategory.academic:
        return Icons.school_rounded;
      case EventCategory.cultural:
        return Icons.celebration_rounded;
      case EventCategory.sports:
        return Icons.sports_rounded;
      case EventCategory.holiday:
        return Icons.beach_access_rounded;
      case EventCategory.other:
        return Icons.event_rounded;
    }
  }

  Color _categoryColor(EventCategory cat) {
    switch (cat) {
      case EventCategory.academic:
        return AppTheme.primary;
      case EventCategory.cultural:
        return AppTheme.secondary;
      case EventCategory.sports:
        return AppTheme.accent;
      case EventCategory.holiday:
        return AppTheme.warning;
      case EventCategory.other:
        return const Color(0xFF8B5CF6);
    }
  }

  Future<void> _deleteEvent(SchoolEvent event) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Event',
      message: 'Delete "${event.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      icon: Icons.delete_rounded,
    );
    if (!confirmed || !mounted) return;
    await ref.read(eventRepositoryProvider).deleteEvent(event.id);
  }

  void _showAddEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AddEventDialog(
        onAdd: (event) async {
          await ref.read(eventRepositoryProvider).addEvent(event);
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final SchoolEvent event;
  final int index;
  final bool isAdmin;
  final VoidCallback onDelete;

  const _EventCard({
    required this.event,
    required this.index,
    required this.isAdmin,
    required this.onDelete,
  });

  Color _catColor(EventCategory cat) {
    switch (cat) {
      case EventCategory.academic:
        return AppTheme.primary;
      case EventCategory.cultural:
        return AppTheme.secondary;
      case EventCategory.sports:
        return AppTheme.accent;
      case EventCategory.holiday:
        return AppTheme.warning;
      case EventCategory.other:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _catColor(event.category);
    final isUpcoming = event.date.isAfter(DateTime.now());
    final daysUntil = event.date.difference(DateTime.now()).inDays;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date column
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(event.date),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(event.date).toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  DateFormat('yyyy').format(event.date),
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (isUpcoming)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            daysUntil == 0
                                ? 'Today!'
                                : daysUntil == 1
                                    ? 'Tomorrow'
                                    : 'In $daysUntil days',
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (isAdmin) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          onPressed: onDelete,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          event.categoryLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        AppDateUtils.dayOfWeek(event.date),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05);
  }
}

class _AddEventDialog extends ConsumerStatefulWidget {
  final Future<void> Function(SchoolEvent) onAdd;
  const _AddEventDialog({required this.onAdd});

  @override
  ConsumerState<_AddEventDialog> createState() =>
      _AddEventDialogState();
}

class _AddEventDialogState
    extends ConsumerState<_AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  EventCategory _category = EventCategory.academic;
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authProvider);
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add School Event'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Event Title *',
                    prefixIcon: Icon(Icons.event_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.notes_rounded),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<EventCategory>(
                  value: _category,
                  decoration:
                      const InputDecoration(labelText: 'Category'),
                  items: EventCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.categoryLabel),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date *',
                      prefixIcon: Icon(Icons.calendar_today_rounded),
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(_date),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : () => _save(auth),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Add Event'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save(AuthState auth) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final event = SchoolEvent(
      id: '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      date: _date,
      category: _category,
      createdBy: auth.user?.name ?? 'Admin',
      createdAt: DateTime.now(),
    );

    try {
      await widget.onAdd(event);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event added successfully!'),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
