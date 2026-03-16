// lib/features/teacher/homework_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/homework_model.dart';
import '../../core/providers/homework_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/validators.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/search_filter_bar.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/confirm_dialog.dart';

class HomeworkScreen extends ConsumerStatefulWidget {
  const HomeworkScreen({super.key});

  @override
  ConsumerState<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends ConsumerState<HomeworkScreen> {
  String _search = '';
  String _classFilter = 'All';

  static const _classes = [
    'All',
    'Playgroup',
    'Nursery',
    'Jr. KG',
    'Sr. KG'
  ];

  List<HomeworkModel> _applyFilters(List<HomeworkModel> list) {
    return list.where((hw) {
      final matchClass =
          _classFilter == 'All' || hw.className == _classFilter;
      final matchSearch = _search.isEmpty ||
          hw.title.toLowerCase().contains(_search.toLowerCase()) ||
          hw.subject.toLowerCase().contains(_search.toLowerCase());
      return matchClass && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hwAsync = ref.watch(allHomeworkProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Homework',
              subtitle: 'Assign and track class homework',
              action: ElevatedButton.icon(
                onPressed: () => _showAddHomeworkDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Assign Homework'),
              ),
            ),
            const SizedBox(height: 20),
            SearchFilterBar(
              hint: 'Search homework...',
              onSearch: (v) => setState(() => _search = v),
              filterOptions: _classes,
              selectedFilter: _classFilter,
              onFilterChanged: (f) => setState(() => _classFilter = f),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: hwAsync.when(
                data: (list) {
                  final filtered = _applyFilters(list);
                  if (filtered.isEmpty) {
                    return const EmptyState(
                      emoji: '📚',
                      title: 'No homework yet',
                      subtitle:
                          'Assign homework to a class by tapping\n"Assign Homework" above.',
                    );
                  }
                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (ctx, i) =>
                        _HomeworkCard(
                          hw: filtered[i],
                          index: i,
                          onDelete: () => _deleteHomework(filtered[i]),
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

  Future<void> _deleteHomework(HomeworkModel hw) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Homework',
      message:
          'Are you sure you want to delete "${hw.title}"? This cannot be undone.',
      confirmLabel: 'Delete',
      icon: Icons.delete_rounded,
    );
    if (!confirmed || !mounted) return;
    await ref.read(homeworkRepositoryProvider).deleteHomework(hw.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Homework deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddHomeworkDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AddHomeworkDialog(
        onAdd: (hw) async {
          await ref.read(homeworkRepositoryProvider).addHomework(hw);
        },
      ),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final HomeworkModel hw;
  final int index;
  final VoidCallback onDelete;

  const _HomeworkCard({
    required this.hw,
    required this.index,
    required this.onDelete,
  });

  Color _subjectColor(String subject) {
    final colors = [
      AppTheme.primary,
      AppTheme.accent,
      AppTheme.warning,
      AppTheme.secondary,
      const Color(0xFF8B5CF6),
    ];
    return colors[subject.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _subjectColor(hw.subject);
    return AppCard(
      accentColor: color,
      onTap: null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.menu_book_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        hw.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    StatusBadge(
                      label: hw.isOverdue ? 'Overdue' : 'Active',
                      color: hw.isOverdue
                          ? AppTheme.secondary
                          : AppTheme.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
                        hw.subject,
                        style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hw.className,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  hw.description,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${AppDateUtils.formatDisplay(hw.dueDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: hw.isOverdue
                            ? AppTheme.secondary
                            : AppTheme.textSecondary,
                        fontWeight: hw.isOverdue
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'By ${hw.teacherName.split(' ').first}',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18, color: Colors.redAccent),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05);
  }
}

class _AddHomeworkDialog extends ConsumerStatefulWidget {
  final Future<void> Function(HomeworkModel hw) onAdd;
  const _AddHomeworkDialog({required this.onAdd});

  @override
  ConsumerState<_AddHomeworkDialog> createState() =>
      _AddHomeworkDialogState();
}

class _AddHomeworkDialogState
    extends ConsumerState<_AddHomeworkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedClass = 'Playgroup';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  bool _isSaving = false;

  static const _classes = ['Playgroup', 'Nursery', 'Jr. KG', 'Sr. KG'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authProvider);
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Assign Homework'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    prefixIcon: Icon(Icons.title_rounded),
                    hintText: 'e.g. Write 5 sentences',
                  ),
                  validator: (v) => Validators.required(v, 'Title'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Subject *',
                    prefixIcon: Icon(Icons.book_rounded),
                    hintText: 'e.g. English, Math',
                  ),
                  validator: (v) => Validators.required(v, 'Subject'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.notes_rounded),
                    hintText: 'Detailed instructions...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration:
                      const InputDecoration(labelText: 'Class *'),
                  items: _classes
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _selectedClass = v!),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDueDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Due Date *',
                      prefixIcon: Icon(Icons.event_rounded),
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy').format(_dueDate),
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
          onPressed: _isSaving ? null : () => Navigator.pop(context),
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
              : const Text('Assign'),
        ),
      ],
    );
  }

  Future<void> _pickDueDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _dueDate = d);
  }

  Future<void> _save(AuthState auth) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final hw = HomeworkModel(
      id: '',
      title: _titleCtrl.text.trim(),
      subject: _subjectCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      className: _selectedClass,
      dueDate: _dueDate,
      teacherId: auth.user?.uid ?? '',
      teacherName: auth.user?.name ?? 'Teacher',
      createdAt: DateTime.now(),
    );

    try {
      await widget.onAdd(hw);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Homework assigned successfully!'),
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
