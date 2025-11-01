import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../providers/app_provider.dart';
import '../../constants/app_constants.dart';
import '../../services/chatbot_service.dart';
import '../../models/chatbot_model.dart';
import '../meetings/meetings_screen.dart';
import '../documents/documents_screen.dart';
import '../announcements/announcements_screen.dart';
import '../profile/profile_screen.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ChatbotService _chatbotService = ChatbotService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late ChatConversation _currentConversation;
  bool _isLoading = false;
  bool _showQuickActions = true;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isRTL = Provider.of<AppProvider>(context, listen: false).isRTL;
    _currentConversation = _chatbotService.createNewConversation(userId, isRTL);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message, {bool isQuickAction = false}) async {
    if (message.trim().isEmpty) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    final isRTL = appProvider.isRTL;
    final user = authProvider.currentUser;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      sender: MessageSender.user,
      type: isQuickAction ? MessageType.quickAction : MessageType.text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _currentConversation.messages.add(userMessage);
      _isLoading = true;
      _showQuickActions = false;
    });

    _messageController.clear();
    _scrollToBottom();

    // Process message and get bot response
    try {
      final botResponse = await _chatbotService.processMessage(
        message,
        _currentConversation.messages,
        user,
        isRTL,
      );

      setState(() {
        _currentConversation.messages.add(botResponse);
        _isLoading = false;
      });

      _scrollToBottom();

      // Handle navigation actions
      if (botResponse.metadata != null && botResponse.metadata!['action'] != null) {
        _handleNavigationAction(botResponse.metadata!['action'] as String);
      }

      // Save conversation
      await _chatbotService.saveConversation(_currentConversation);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentConversation.messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: isRTL
                ? 'عذراً، حدث خطأ. يرجى المحاولة مرة أخرى.'
                : 'Sorry, an error occurred. Please try again.',
            sender: MessageSender.bot,
            type: MessageType.error,
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }

  void _handleNavigationAction(String action) {
    Widget? screen;

    switch (action) {
      case 'navigate_meetings':
        screen = const MeetingsScreen();
        break;
      case 'navigate_documents':
        screen = const DocumentsScreen();
        break;
      case 'navigate_announcements':
        screen = const AnnouncementsScreen();
        break;
      case 'navigate_profile':
        screen = const ProfileScreen();
        break;
    }

    if (screen != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen!),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = kIsWeb || size.width > 800;

    return Consumer2<app_auth.AuthProvider, AppProvider>(
      builder: (context, authProvider, appProvider, child) {
        final isRTL = appProvider.isRTL;

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            title: FadeIn(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.smart_toy, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isRTL ? 'مساعد GCC الذكي' : 'GCC AI Assistant',
                    style: AppTextStyles.heading2.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            backgroundColor: AppColors.primaryColor,
            actions: [
              FadeIn(
                delay: const Duration(milliseconds: 200),
                child: IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: isRTL ? 'محادثة جديدة' : 'New Conversation',
                  onPressed: () {
                    setState(() {
                      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
                      _currentConversation = _chatbotService.createNewConversation(userId, isRTL);
                      _showQuickActions = true;
                    });
                  },
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Messages List
              Expanded(
                child: AnimationLimiter(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(isWeb ? 24 : 16),
                    itemCount: _currentConversation.messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == _currentConversation.messages.length) {
                        return _buildTypingIndicator(isWeb);
                      }

                      final message = _currentConversation.messages[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildMessageBubble(message, isRTL, isWeb),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Quick Actions
              if (_showQuickActions)
                FadeInUp(
                  child: _buildQuickActions(isRTL, isWeb),
                ),

              // Input Field
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _buildInputField(isRTL, isWeb),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isRTL, bool isWeb) {
    final isUser = message.sender == MessageSender.user;
    final isSystem = message.sender == MessageSender.system;

    if (isSystem) {
      return Center(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: isWeb ? 12 : 8),
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 16 : 12,
            vertical: isWeb ? 8 : 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              fontSize: isWeb ? 12 : 11,
              color: AppColors.textSecondaryColor,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: isUser
          ? (isRTL ? Alignment.centerLeft : Alignment.centerRight)
          : (isRTL ? Alignment.centerRight : Alignment.centerLeft),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: isWeb ? 600 : size.width * 0.75,
            ),
            margin: EdgeInsets.only(bottom: isWeb ? 12 : 8),
            padding: EdgeInsets.all(isWeb ? 16 : 12),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.primaryColor
                  : message.type == MessageType.error
                      ? AppColors.errorColor.withOpacity(0.1)
                      : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    fontSize: isWeb ? 15 : 14,
                    color: isUser
                        ? Colors.white
                        : message.type == MessageType.error
                            ? AppColors.errorColor
                            : AppColors.textPrimaryColor,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: isWeb ? 6 : 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: isWeb ? 11 : 10,
                    color: isUser
                        ? Colors.white.withOpacity(0.7)
                        : AppColors.textLightColor,
                  ),
                ),
              ],
            ),
          ),
          // Quick action buttons
          if (message.quickActions != null && message.quickActions!.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: message.quickActions!.map((actionId) {
                final action = _chatbotService.getQuickActions(isRTL).firstWhere(
                      (a) => a.id == actionId,
                      orElse: () => QuickAction(
                        id: '',
                        label: '',
                        command: '',
                        icon: '',
                        description: '',
                      ),
                    );
                if (action.id.isEmpty) return const SizedBox.shrink();

                return ActionChip(
                  label: Text(action.label),
                  onPressed: () => _sendMessage(action.command, isQuickAction: true),
                  backgroundColor: AppColors.lightGray,
                  labelStyle: TextStyle(
                    fontSize: isWeb ? 13 : 12,
                    color: AppColors.primaryColor,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isWeb) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: isWeb ? 12 : 8),
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 16 : 12,
          vertical: isWeb ? 12 : 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypingDot(0),
            const SizedBox(width: 4),
            _buildTypingDot(150),
            const SizedBox(width: 4),
            _buildTypingDot(300),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return FadeIn(
      delay: Duration(milliseconds: delay),
      child: Pulse(
        infinite: true,
        delay: Duration(milliseconds: delay),
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isRTL, bool isWeb) {
    final actions = _chatbotService.getQuickActions(isRTL);

    return Container(
      padding: EdgeInsets.all(isWeb ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRTL ? 'إجراءات سريعة' : 'Quick Actions',
            style: TextStyle(
              fontSize: isWeb ? 14 : 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondaryColor,
            ),
          ),
          SizedBox(height: isWeb ? 12 : 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions.map((action) {
              return ActionChip(
                avatar: Icon(
                  _getIconData(action.icon),
                  size: isWeb ? 18 : 16,
                  color: AppColors.primaryColor,
                ),
                label: Text(action.label),
                onPressed: () => _sendMessage(action.command, isQuickAction: true),
                backgroundColor: AppColors.lightGray,
                labelStyle: TextStyle(
                  fontSize: isWeb ? 13 : 12,
                  color: AppColors.textPrimaryColor,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(bool isRTL, bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: isRTL ? 'اكتب رسالتك...' : 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: AppColors.backgroundColor,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isWeb ? 20 : 16,
                  vertical: isWeb ? 14 : 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) => _sendMessage(value),
            ),
          ),
          SizedBox(width: isWeb ? 12 : 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(_messageController.text),
              tooltip: isRTL ? 'إرسال' : 'Send',
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'event':
        return Icons.event;
      case 'description':
        return Icons.description;
      case 'announcement':
        return Icons.announcement;
      case 'person':
        return Icons.person;
      case 'help':
        return Icons.help_outline;
      case 'question_answer':
        return Icons.question_answer;
      default:
        return Icons.star;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
