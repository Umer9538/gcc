import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../constants/app_constants.dart';
import '../../services/messaging_service.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../utils/date_utils.dart';

class ChatScreen extends StatefulWidget {
  final UserModel otherUser;
  final UserModel currentUser;

  const ChatScreen({
    super.key,
    required this.otherUser,
    required this.currentUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessagingService _messagingService = MessagingService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get _conversationId => _messagingService.getConversationId(
        widget.currentUser.id,
        widget.otherUser.id,
      );

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markMessagesAsRead() {
    _messagingService.markMessagesAsRead(_conversationId, widget.currentUser.id);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final isRTL = appProvider.isRTL;

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
                  backgroundImage: widget.otherUser.profileImageUrl?.isNotEmpty == true
                      ? NetworkImage(widget.otherUser.profileImageUrl!)
                      : null,
                  child: widget.otherUser.profileImageUrl?.isEmpty != false
                      ? Text(
                          _getInitials(widget.otherUser.fullName),
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.otherUser.fullName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.otherUser.position,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.phone),
                onPressed: () {
                  // TODO: Implement voice call
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isRTL ? 'المكالمات قريباً' : 'Calling feature coming soon'),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.videocam),
                onPressed: () {
                  // TODO: Implement video call
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isRTL ? 'المكالمات المرئية قريباً' : 'Video calling coming soon'),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Messages list
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _messagingService.getConversationMessages(_conversationId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: AppColors.textLightColor,
                            ),
                            const SizedBox(height: AppConstants.defaultPadding),
                            Text(
                              isRTL ? 'ابدأ المحادثة' : 'Start the conversation',
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: AppConstants.smallPadding),
                            Text(
                              isRTL ? 'أرسل أول رسالة' : 'Send your first message',
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }

                    final messages = snapshot.data!;
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == widget.currentUser.id;
                        final showDate = index == 0 ||
                            !_isSameDay(messages[index - 1].timestamp, message.timestamp);

                        return Column(
                          children: [
                            if (showDate) _buildDateHeader(message.timestamp, isRTL),
                            _buildMessageBubble(message, isMe, isRTL),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              // Message input
              _buildMessageInput(isRTL),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date, bool isRTL) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppConstants.defaultPadding),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.smallPadding,
        ),
        decoration: BoxDecoration(
          color: AppColors.textLightColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Text(
          AppDateUtils.formatDate(date, locale: isRTL ? 'ar' : 'en'),
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe, bool isRTL) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
              backgroundImage: widget.otherUser.profileImageUrl?.isNotEmpty == true
                  ? NetworkImage(widget.otherUser.profileImageUrl!)
                  : null,
              child: widget.otherUser.profileImageUrl?.isEmpty != false
                  ? Text(
                      _getInitials(widget.otherUser.fullName),
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: AppConstants.smallPadding,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primaryColor : AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                border: !isMe
                    ? Border.all(color: AppColors.borderColor, width: 1)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isMe ? Colors.white : AppColors.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppDateUtils.formatTime(message.timestamp),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.textLightColor,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
              backgroundImage: widget.currentUser.profileImageUrl?.isNotEmpty == true
                  ? NetworkImage(widget.currentUser.profileImageUrl!)
                  : null,
              child: widget.currentUser.profileImageUrl?.isEmpty != false
                  ? Text(
                      _getInitials(widget.currentUser.fullName),
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isRTL) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: const BoxDecoration(
        color: AppColors.surfaceColor,
        border: Border(
          top: BorderSide(color: AppColors.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundColor,
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: isRTL ? 'اكتب رسالة...' : 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.defaultPadding,
                    vertical: AppConstants.smallPadding,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    try {
      await _messagingService.sendMessage(
        conversationId: _conversationId,
        senderId: widget.currentUser.id,
        senderName: widget.currentUser.fullName,
        receiverId: widget.otherUser.id,
        content: content,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message'),
          ),
        );
      }
    }
  }

  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}