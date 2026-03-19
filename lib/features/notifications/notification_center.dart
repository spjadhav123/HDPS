// lib/features/notifications/notification_center.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/notification_model.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/app_date_utils.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/empty_state.dart';

class NotificationCenter extends ConsumerWidget {
  const NotificationCenter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);
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
              title: 'Notifications',
              subtitle: 'School announcements and updates',
              action: isAdmin
                  ? ElevatedButton.icon(
                      onPressed: () => _showSendDialog(context, ref),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Send Notification'),
                    )
                  : notifAsync.maybeWhen(
                      data: (list) {
                        final unread =
                            list.where((n) => !n.isRead).toList();
                        if (unread.isEmpty) return null;
                        return TextButton.icon(
                          onPressed: () => _markAllRead(ref, unread),
                          icon: const Icon(
                              Icons.done_all_rounded,
                              size: 18),
                          label: const Text('Mark all read'),
                        );
                      },
                      orElse: () => null,
                    ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: notifAsync.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      emoji: '🔔',
                      title: 'No notifications',
                      subtitle:
                          'You\'re all caught up! New announcements\nwill appear here.',
                    );
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _NotificationCard(
                      notif: list[i],
                      index: i,
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

  void _markAllRead(WidgetRef ref, List<AppNotification> unread) async {
    final ids = unread.map((n) => n.id).toList();
    await ref.read(notificationRepositoryProvider).markAllAsRead(ids);
  }

  void _showSendDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _SendNotificationDialog(
        onSend: (notif) async {
          await ref
              .read(notificationRepositoryProvider)
              .sendNotification(notif);
        },
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final AppNotification notif;
  final int index;

  const _NotificationCard({required this.notif, required this.index});

  IconData _typeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.announcement:
        return Icons.campaign_rounded;
      case NotificationType.feeReminder:
        return Icons.payments_rounded;
      case NotificationType.attendance:
        return Icons.how_to_reg_rounded;
      case NotificationType.homework:
        return Icons.menu_book_rounded;
      case NotificationType.event:
        return Icons.event_rounded;
      case NotificationType.general:
        return Icons.notifications_rounded;
    }
  }

  Color _typeColor(NotificationType type) {
    switch (type) {
      case NotificationType.announcement:
        return AppTheme.primary;
      case NotificationType.feeReminder:
        return AppTheme.warning;
      case NotificationType.attendance:
        return AppTheme.accent;
      case NotificationType.homework:
        return const Color(0xFF8B5CF6);
      case NotificationType.event:
        return AppTheme.secondary;
      case NotificationType.general:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _typeColor(notif.type);
    return InkWell(
      onTap: () {
        if (!notif.isRead) {
          ref
              .read(notificationRepositoryProvider)
              .markAsRead(notif.id);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead
                ? Colors.grey.shade100
                : color.withOpacity(0.3),
            width: notif.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(notif.isRead ? 0.04 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(notif.type), color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notif.isRead
                                ? FontWeight.w600
                                : FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          notif.type.name[0].toUpperCase() +
                              notif.type.name.substring(1),
                          style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        AppDateUtils.formatRelative(notif.createdAt),
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
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05);
  }
}

class _SendNotificationDialog extends ConsumerStatefulWidget {
  final Future<void> Function(AppNotification) onSend;
  const _SendNotificationDialog({required this.onSend});

  @override
  ConsumerState<_SendNotificationDialog> createState() =>
      _SendNotificationDialogState();
}

class _SendNotificationDialogState
    extends ConsumerState<_SendNotificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  NotificationType _type = NotificationType.announcement;
  String _targetRole = 'all';
  bool _isSending = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Send Notification'),
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
                    labelText: 'Title *',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Message *',
                    prefixIcon: Icon(Icons.message_rounded),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<NotificationType>(
                  initialValue: _type,
                  decoration:
                      const InputDecoration(labelText: 'Type'),
                  items: NotificationType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              t.name[0].toUpperCase() +
                                  t.name.substring(1),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _targetRole,
                  decoration: const InputDecoration(
                      labelText: 'Send To'),
                  items: const [
                    DropdownMenuItem(
                        value: 'all', child: Text('All Users')),
                    DropdownMenuItem(
                        value: 'parent', child: Text('Parents Only')),
                    DropdownMenuItem(
                        value: 'teacher',
                        child: Text('Teachers Only')),
                  ],
                  onChanged: (v) =>
                      setState(() => _targetRole = v!),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isSending ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSending ? null : _send,
          icon: const Icon(Icons.send_rounded, size: 16),
          label: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Send'),
        ),
      ],
    );
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    final notif = AppNotification(
      id: '',
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      type: _type,
      targetRole: _targetRole,
      isRead: false,
      createdAt: DateTime.now(),
    );

    try {
      await widget.onSend(notif);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sent!'),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
