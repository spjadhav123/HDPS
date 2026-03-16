// lib/features/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/chat_message_model.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/app_date_utils.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/empty_state.dart';

/// Entry point — shows list of threads or opens a thread
class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.uid ?? '';
    final role = authState.user?.role ?? '';

    final threadsAsync = ref.watch(chatThreadsProvider(userId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Messages',
              subtitle: role == 'teacher'
                  ? 'Chat with parents'
                  : 'Chat with your child\'s teacher',
            ),
            const SizedBox(height: 20),
            Expanded(
              child: threadsAsync.when(
                data: (threads) {
                  if (threads.isEmpty) {
                    return EmptyState(
                      emoji: '💬',
                      title: 'No conversations yet',
                      subtitle: role == 'parent'
                          ? 'Start a conversation with your child\'s teacher.'
                          : 'Conversations with parents will appear here.',
                    );
                  }
                  return ListView.separated(
                    itemCount: threads.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _ThreadCard(
                      thread: threads[i],
                      currentUserId: userId,
                      currentRole: role,
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
}

class _ThreadCard extends StatelessWidget {
  final ChatThread thread;
  final String currentUserId;
  final String currentRole;
  final int index;

  const _ThreadCard({
    required this.thread,
    required this.currentUserId,
    required this.currentRole,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final otherName = currentRole == 'parent'
        ? thread.teacherName
        : thread.parentName;
    final hasUnread = thread.unreadCount > 0;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatThreadScreen(
            threadId: thread.id,
            otherName: otherName,
            studentName: thread.studentName,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasUnread
                ? AppTheme.primary.withOpacity(0.3)
                : Colors.grey.shade100,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primary.withOpacity(0.15),
              child: Text(
                otherName.isNotEmpty ? otherName[0] : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
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
                          otherName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        AppDateUtils.formatRelative(
                            thread.lastMessageAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Re: ${thread.studentName}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.lastMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUnread
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${thread.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
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

/// The actual chat thread / message view
class ChatThreadScreen extends ConsumerStatefulWidget {
  final String threadId;
  final String otherName;
  final String studentName;

  const ChatThreadScreen({
    super.key,
    required this.threadId,
    required this.otherName,
    required this.studentName,
  });

  @override
  ConsumerState<ChatThreadScreen> createState() =>
      _ChatThreadScreenState();
}

class _ChatThreadScreenState
    extends ConsumerState<ChatThreadScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Mark thread as read on open
    Future.microtask(() =>
        ref.read(chatRepositoryProvider).markThreadRead(widget.threadId));
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final messagesAsync =
        ref.watch(chatMessagesProvider(widget.threadId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherName,
                style: const TextStyle(fontSize: 15)),
            Text(
              'Re: ${widget.studentName}',
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        leading: const BackButton(),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const EmptyState(
                    emoji: '👋',
                    title: 'Start the conversation',
                    subtitle:
                        'Send a message to start chatting.',
                  );
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.animateTo(
                      _scrollCtrl.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == auth.user?.uid;
                    return _MessageBubble(
                      message: msg,
                      isMe: isMe,
                      showName: !isMe && i == 0 ||
                          (i > 0 &&
                              messages[i - 1].senderId !=
                                  msg.senderId),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Error: $err')),
            ),
          ),
          // Message input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _isSending ? null : () => _sendMessage(auth),
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(AuthState auth) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);

    final msg = ChatMessage(
      id: '',
      senderId: auth.user?.uid ?? '',
      senderName: auth.user?.name ?? '',
      senderRole: auth.user?.role ?? '',
      message: text,
      timestamp: DateTime.now(),
      isRead: false,
    );

    _msgCtrl.clear();

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            threadId: widget.threadId,
            message: msg,
            parentName: auth.user?.role == 'parent'
                ? auth.user?.name ?? ''
                : widget.otherName,
            teacherName: auth.user?.role == 'teacher'
                ? auth.user?.name ?? ''
                : widget.otherName,
            studentName: widget.studentName,
            participantIds: [
              auth.user?.uid ?? '',
              widget.threadId.replaceAll(auth.user?.uid ?? '', '').replaceAll('_', ''),
            ],
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showName;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showName && !isMe)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                message.senderName,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                  child: Text(
                    message.senderName.isNotEmpty
                        ? message.senderName[0]
                        : '?',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: isMe
                              ? Colors.white
                              : AppTheme.textPrimary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppDateUtils.formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white60
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                  child: Text(
                    message.senderName.isNotEmpty
                        ? message.senderName[0]
                        : '?',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
