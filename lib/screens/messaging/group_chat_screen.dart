import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../constants/app_constants.dart';
import '../../services/messaging_service.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../utils/date_utils.dart';

class GroupChatScreen extends StatefulWidget {
  final GroupConversationModel group;
  final UserModel currentUser;

  const GroupChatScreen({
    super.key,
    required this.group,
    required this.currentUser,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final MessagingService _messagingService = MessagingService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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
                  backgroundColor: AppColors.secondaryColor.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.group,
                    color: AppColors.secondaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.group.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.group.participants.length} ${isRTL ? 'أعضاء' : 'members'}',
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
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, isRTL),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'info',
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 8),
                        Text(isRTL ? 'معلومات المجموعة' : 'Group Info'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'members',
                    child: Row(
                      children: [
                        const Icon(Icons.people),
                        const SizedBox(width: 8),
                        Text(isRTL ? 'الأعضاء' : 'Members'),
                      ],
                    ),
                  ),
                  if (widget.group.createdBy == widget.currentUser.id)
                    PopupMenuItem(
                      value: 'manage',
                      child: Row(
                        children: [
                          const Icon(Icons.settings),
                          const SizedBox(width: 8),
                          Text(isRTL ? 'إدارة المجموعة' : 'Manage Group'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'leave',
                    child: Row(
                      children: [
                        const Icon(Icons.exit_to_app, color: AppColors.errorColor),
                        const SizedBox(width: 8),
                        Text(
                          isRTL ? 'مغادرة المجموعة' : 'Leave Group',
                          style: const TextStyle(color: AppColors.errorColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Messages
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: _messagingService.getConversationMessages(widget.group.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyMessages(isRTL);
                    }

                    final messages = snapshot.data!;

                    // Mark messages as read when user opens the chat
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _markMessagesAsRead(messages);
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppConstants.defaultPadding),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMyMessage = message.senderId == widget.currentUser.id;
                        final showSenderName = !isMyMessage &&
                            (index == 0 || messages[index - 1].senderId != message.senderId);

                        return _buildMessageBubble(
                          message: message,
                          isMyMessage: isMyMessage,
                          showSenderName: showSenderName,
                          isRTL: isRTL,
                        );
                      },
                    );
                  },
                ),
              ),

              // Message Input
              _buildMessageInput(isRTL),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyMessages(bool isRTL) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 64,
            color: AppColors.textLightColor,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            isRTL ? 'مرحباً بك في المجموعة!' : 'Welcome to the group!',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            isRTL
                ? 'ابدأ المحادثة مع أعضاء المجموعة'
                : 'Start the conversation with group members',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required MessageModel message,
    required bool isMyMessage,
    required bool showSenderName,
    required bool isRTL,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
              child: Text(
                _getInitials(message.senderName),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMyMessage
                    ? AppColors.primaryColor
                    : AppColors.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMyMessage ? 16 : 4),
                  bottomRight: Radius.circular(isMyMessage ? 4 : 16),
                ),
                border: !isMyMessage
                    ? Border.all(color: AppColors.borderColor.withValues(alpha: 0.3))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showSenderName) ...[
                    Text(
                      message.senderName,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isMyMessage
                            ? Colors.white.withValues(alpha: 0.8)
                            : AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isMyMessage ? Colors.white : AppColors.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppDateUtils.formatTime(message.timestamp),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isMyMessage
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.textLightColor,
                        ),
                      ),
                      if (isMyMessage) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 16,
                          color: message.isRead
                              ? AppColors.successColor
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMyMessage) ...[
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
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
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
          top: BorderSide(color: AppColors.borderColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: isRTL ? 'اكتب رسالة...' : 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primaryColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
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

  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    try {
      await _messagingService.sendGroupMessage(
        groupId: widget.group.id,
        senderId: widget.currentUser.id,
        senderName: widget.currentUser.fullName,
        content: content,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<AppProvider>(context, listen: false).isRTL
                  ? 'فشل في إرسال الرسالة'
                  : 'Failed to send message',
            ),
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _markMessagesAsRead(List<MessageModel> messages) {
    for (final message in messages) {
      if (message.senderId != widget.currentUser.id && !message.isRead) {
        _messagingService.markGroupMessageAsRead(
          widget.group.id,
          message.id,
          widget.currentUser.id,
        );
      }
    }
  }

  void _handleMenuAction(String action, bool isRTL) {
    switch (action) {
      case 'info':
        _showGroupInfo(isRTL);
        break;
      case 'members':
        _showGroupMembers(isRTL);
        break;
      case 'manage':
        _showGroupManagement(isRTL);
        break;
      case 'leave':
        _showLeaveGroupDialog(isRTL);
        break;
    }
  }

  void _showGroupInfo(bool isRTL) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'معلومات المجموعة' : 'Group Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              icon: Icons.group,
              label: isRTL ? 'اسم المجموعة' : 'Group Name',
              value: widget.group.name,
            ),
            _buildInfoRow(
              icon: Icons.description,
              label: isRTL ? 'الوصف' : 'Description',
              value: widget.group.description.isEmpty
                  ? (isRTL ? 'لا يوجد وصف' : 'No description')
                  : widget.group.description,
            ),
            _buildInfoRow(
              icon: Icons.people,
              label: isRTL ? 'عدد الأعضاء' : 'Members',
              value: '${widget.group.participants.length}',
            ),
            _buildInfoRow(
              icon: Icons.person,
              label: isRTL ? 'منشئ المجموعة' : 'Created by',
              value: widget.group.createdBy,
            ),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: isRTL ? 'تاريخ الإنشاء' : 'Created',
              value: AppDateUtils.formatDate(widget.group.createdAt),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRTL ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupMembers(bool isRTL) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isRTL ? 'أعضاء المجموعة' : 'Group Members'} (${widget.group.participants.length})'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: FutureBuilder<List<UserModel>>(
            future: _loadGroupMembers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(isRTL ? 'لا يوجد أعضاء' : 'No members found'),
                );
              }

              final members = snapshot.data!;
              return ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isCreator = member.id == widget.group.createdBy;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
                      backgroundImage: member.profileImageUrl?.isNotEmpty == true
                          ? NetworkImage(member.profileImageUrl!)
                          : null,
                      child: member.profileImageUrl?.isEmpty != false
                          ? Text(
                              _getInitials(member.fullName),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryColor,
                              ),
                            )
                          : null,
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(member.fullName)),
                        if (isCreator)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isRTL ? 'مشرف' : 'Admin',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text('${member.position} • ${member.department}'),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRTL ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }

  void _showGroupManagement(bool isRTL) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isRTL ? 'إدارة المجموعة قريباً' : 'Group management coming soon'),
      ),
    );
  }

  void _showLeaveGroupDialog(bool isRTL) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'مغادرة المجموعة' : 'Leave Group'),
        content: Text(
          isRTL
              ? 'هل أنت متأكد من مغادرة "${widget.group.name}"؟'
              : 'Are you sure you want to leave "${widget.group.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRTL ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _leaveGroup();
            },
            child: Text(
              isRTL ? 'مغادرة' : 'Leave',
              style: const TextStyle(color: AppColors.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<UserModel>> _loadGroupMembers() async {
    final futures = widget.group.participants.map((userId) async {
      return await _messagingService.getUserById(userId);
    }).toList();

    final results = await Future.wait(futures);
    return results.where((user) => user != null).cast<UserModel>().toList();
  }

  Future<void> _leaveGroup() async {
    try {
      await _messagingService.removeParticipantFromGroupChat(
        widget.group.id,
        widget.currentUser.id,
        widget.currentUser.fullName,
      );

      if (mounted) {
        Navigator.pop(context); // Return to messaging screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<AppProvider>(context, listen: false).isRTL
                  ? 'تم مغادرة المجموعة'
                  : 'Left the group',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Provider.of<AppProvider>(context, listen: false).isRTL
                  ? 'فشل في مغادرة المجموعة'
                  : 'Failed to leave group',
            ),
          ),
        );
      }
    }
  }
}