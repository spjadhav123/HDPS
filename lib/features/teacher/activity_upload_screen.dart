// lib/features/teacher/activity_upload_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/daily_activity_model.dart';
import '../../core/models/student_model.dart';
import '../../core/providers/student_provider.dart';
import '../../core/providers/daily_activity_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/app_date_utils.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/search_filter_bar.dart';
import '../../shared/widgets/app_card.dart';

class ActivityUploadScreen extends ConsumerStatefulWidget {
  const ActivityUploadScreen({super.key});

  @override
  ConsumerState<ActivityUploadScreen> createState() => _ActivityUploadScreenState();
}

class _ActivityUploadScreenState extends ConsumerState<ActivityUploadScreen> {
  String _selectedClass = 'Playgroup';
  DateTime _selectedDate = DateTime.now();
  String _search = '';

  final _classes = ['Playgroup', 'Nursery', 'Jr. KG', 'Sr. KG'];

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            PageHeader(
              title: 'Daily Activities',
              subtitle: 'Record student mood and activities',
              action: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(DateFormat('dd MMM').format(_selectedDate)),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedClass,
                    items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedClass = v!),
                    underline: const SizedBox(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SearchFilterBar(
              hint: 'Search students...',
              onSearch: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: studentsAsync.when(
                data: (students) {
                  final filtered = students.where((s) {
                    final matchClass = s.className == _selectedClass;
                    final matchSearch = s.name.toLowerCase().contains(_search.toLowerCase());
                    return matchClass && matchSearch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const EmptyState(
                      emoji: '🧑‍🎓',
                      title: 'No students found',
                      subtitle: 'Try changing the class or search term.',
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) => _StudentActivityCard(
                      student: filtered[i],
                      date: AppDateUtils.dateKey(_selectedDate),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _selectedDate = d);
  }
}

class _StudentActivityCard extends ConsumerWidget {
  final Student student;
  final String date;

  const _StudentActivityCard({required this.student, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(studentDailyActivityProvider((studentId: student.id, date: date)));

    return AppCard(
      onTap: () => _showActivityDialog(context, ref, activityAsync.asData?.value),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Text(student.name[0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(student.studentCode, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          activityAsync.when(
            data: (activity) {
              if (activity == null) {
                return const Text('Not recorded', style: TextStyle(fontSize: 12, color: Colors.grey));
              }
              return Row(
                children: [
                  Text(activity.moodEmoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 20),
                ],
              );
            },
            loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => const Icon(Icons.error_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showActivityDialog(BuildContext context, WidgetRef ref, DailyActivity? existing) {
    showDialog(
      context: context,
      builder: (_) => _RecordActivityDialog(
        student: student,
        date: date,
        existing: existing,
      ),
    );
  }
}

class _RecordActivityDialog extends ConsumerStatefulWidget {
  final Student student;
  final String date;
  final DailyActivity? existing;

  const _RecordActivityDialog({
    required this.student,
    required this.date,
    this.existing,
  });

  @override
  ConsumerState<_RecordActivityDialog> createState() => _RecordActivityDialogState();
}

class _RecordActivityDialogState extends ConsumerState<_RecordActivityDialog> {
  late String _mood;
  late TextEditingController _noteCtrl;
  late List<String> _selectedActivities;
  bool _isSaving = false;

  final _allActivities = ['Drawing', 'Story Telling', 'Math Games', 'Rhymes', 'Outdoor Play', 'Nap Time', 'Crafts'];
  final _moods = [
    {'label': 'Happy', 'emoji': '😊', 'value': 'happy'},
    {'label': 'Okay', 'emoji': '😐', 'value': 'okay'},
    {'label': 'Sad', 'emoji': '😢', 'value': 'sad'},
    {'label': 'Excited', 'emoji': '🤩', 'value': 'excited'},
  ];

  @override
  void initState() {
    super.initState();
    _mood = widget.existing?.mood ?? 'happy';
    _noteCtrl = TextEditingController(text: widget.existing?.teacherNote ?? '');
    _selectedActivities = List<String>.from(widget.existing?.activities ?? []);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Record Activity - ${widget.student.name}'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How was the mood today?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _moods.map((m) {
                  final isSelected = _mood == m['value'];
                  return InkWell(
                    onTap: () => setState(() => _mood = m['value']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(m['emoji']!, style: const TextStyle(fontSize: 24)),
                          Text(m['label']!, style: TextStyle(fontSize: 10, color: isSelected ? AppTheme.primary : AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text('Activities Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _allActivities.map((act) {
                  final isSelected = _selectedActivities.contains(act);
                  return FilterChip(
                    label: Text(act, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) _selectedActivities.add(act);
                        else _selectedActivities.remove(act);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Teacher\'s Note',
                  hintText: 'Any specific feedback or observation...',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Record'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final auth = ref.read(authProvider);

    final activity = DailyActivity(
      id: widget.existing?.id ?? '',
      studentId: widget.student.id,
      studentName: widget.student.name,
      className: widget.student.className,
      date: widget.date,
      mood: _mood,
      activities: _selectedActivities,
      teacherNote: _noteCtrl.text.trim(),
      photoUrls: widget.existing?.photoUrls ?? [],
      markedBy: auth.user?.name ?? 'Teacher',
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(dailyActivityRepositoryProvider).saveDailyActivity(activity);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity recorded successfully!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }
}
