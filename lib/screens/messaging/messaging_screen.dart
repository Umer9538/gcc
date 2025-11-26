import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../constants/app_constants.dart';
import '../../services/messaging_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../utils/date_utils.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';
import '../../widgets/create_group_dialog.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> with SingleTickerProviderStateMixin {
  final MessagingService _messagingService = MessagingService();
  final UserService _userService = UserService();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, app_auth.AuthProvider>(
      builder: (context, appProvider, authProvider, child) {
        final isRTL = appProvider.isRTL;
        final currentUser = authProvider.currentUser;
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            title: Text(
              isRTL ? 'الرسائل' : 'Messages',
              style: AppTextStyles.heading2.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.primaryColor,
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(value, context, isRTL, currentUser),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'new_chat',
                    child: Row(
                      children: [
                        const Icon(Icons.person_add),
                        const SizedBox(width: 8),
                        Text(isRTL ? 'محادثة جديدة' : 'New Chat'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'new_group',
                    child: Row(
                      children: [
                        const Icon(Icons.group_add),
                        const SizedBox(width: 8),
                        Text(isRTL ? 'مجموعة جديدة' : 'New Group'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: isRTL ? 'المحادثات' : 'Chats'),
                Tab(text: isRTL ? 'المجموعات' : 'Groups'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildChatsTab(userId, isRTL, currentUser),
              _buildGroupsTab(userId, isRTL, currentUser),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _handleMenuAction('new_chat', context, isRTL, currentUser),
            backgroundColor: AppColors.primaryColor,
            child: const Icon(Icons.message),
          ),
        );
      },
    );
  }

  Widget _buildChatsTab(String userId, bool isRTL, UserModel? currentUser) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: isRTL ? 'البحث في المحادثات...' : 'Search conversations...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                borderSide: const BorderSide(color: AppColors.borderColor),
              ),
              filled: true,
              fillColor: AppColors.surfaceColor,
            ),
          ),
        ),
        // Conversations list
        Expanded(
          child: StreamBuilder(
            stream: _messagingService.getUserConversations(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState(isRTL, 'chats');
              }

              final conversations = snapshot.data!;
              return ListView.builder(
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  final otherUserId = conversation.participants
                      .firstWhere((id) => id != userId);

                  return FutureBuilder<UserModel?>(
                    future: _userService.getUserById(otherUserId),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final otherUser = userSnapshot.data!;
                      final hasUnread = (conversation.unreadCount[userId] ?? 0) > 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppConstants.defaultPadding,
                          vertical: AppConstants.smallPadding,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
                            backgroundImage: (otherUser.profileImageUrl?.isNotEmpty == true)
                                ? NetworkImage(otherUser.profileImageUrl!)
                                : null,
                            child: (otherUser.profileImageUrl?.isEmpty != false)
                                ? Text(
                                    _getInitials(otherUser.fullName),
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  otherUser.fullName,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (hasUnread)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${conversation.unreadCount[userId]}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                conversation.lastMessage,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    otherUser.department,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppDateUtils.formatDate(conversation.lastMessageTime),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textLightColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  otherUser: otherUser,
                                  currentUser: currentUser!,
                                ),
                              ),
                            );
                          },
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsTab(String userId, bool isRTL, UserModel? currentUser) {
    return StreamBuilder(
      stream: _messagingService.getUserGroupConversations(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(isRTL, 'groups');
        }

        final groups = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final hasUnread = (group.unreadCount[userId] ?? 0) > 0;

            return Card(
              margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.secondaryColor.withValues(alpha: 0.2),
                  child: Icon(
                    Icons.group,
                    color: AppColors.secondaryColor,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.secondaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${group.unreadCount[userId]}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.description,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 12,
                          color: AppColors.textLightColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.participants.length} ${isRTL ? 'أعضاء' : 'members'}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLightColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          AppDateUtils.formatDate(group.lastMessageTime),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textLightColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupChatScreen(
                        group: group,
                        currentUser: currentUser!,
                      ),
                    ),
                  );
                },
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isRTL, String type) {
    String message;
    String subtitle;
    IconData icon;

    if (type == 'chats') {
      message = isRTL ? 'لا توجد محادثات' : 'No conversations';
      subtitle = isRTL ? 'ابدأ محادثة جديدة' : 'Start a new conversation';
      icon = Icons.chat_bubble_outline;
    } else {
      message = isRTL ? 'لا توجد مجموعات' : 'No groups';
      subtitle = isRTL ? 'انضم إلى مجموعة أو أنشئ واحدة' : 'Join or create a group';
      icon = Icons.group_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textLightColor,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            message,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
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

  void _showNewMessageDialog(BuildContext context, bool isRTL, UserModel? currentUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'محادثة جديدة' : 'New Conversation'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.5,
          child: FutureBuilder<List<UserModel>>(
            future: _userService.getAllUsersExcept(currentUser?.id ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(isRTL ? 'لا يوجد مستخدمون' : 'No users available'),
                );
              }

              final users = snapshot.data!;
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
                      backgroundImage: (user.profileImageUrl?.isNotEmpty == true)
                          ? NetworkImage(user.profileImageUrl!)
                          : null,
                      child: (user.profileImageUrl?.isEmpty != false)
                          ? Text(
                              _getInitials(user.fullName),
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(user.fullName),
                    subtitle: Text('${user.position} • ${user.department}'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            otherUser: user,
                            currentUser: currentUser!,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRTL ? 'إلغاء' : 'Cancel'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, BuildContext context, bool isRTL, UserModel? currentUser) {
    switch (action) {
      case 'new_chat':
        _showNewMessageDialog(context, isRTL, currentUser);
        break;
      case 'new_group':
        _showCreateGroupDialog(context, isRTL, currentUser);
        break;
    }
  }

  void _showCreateGroupDialog(BuildContext context, bool isRTL, UserModel? currentUser) async {
    if (currentUser == null) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => CreateGroupDialog(currentUser: currentUser),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRTL ? 'تم إنشاء المجموعة بنجاح' : 'Group created successfully'),
        ),
      );
    }
  }
}