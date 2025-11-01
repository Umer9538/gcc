import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/chatbot_model.dart';
import '../models/user_model.dart';

class ChatbotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // TODO: Replace with your actual Gemini API key
  // Get your API key from: https://makersuite.google.com/app/apikey
  static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
  static const String _geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  // Context about GCC Connect app for better responses
  final String _systemContext = '''
You are an AI assistant for GCC Connect, an internal communication and management platform for GCC organizations.

GCC Connect Features:
1. Meeting Management - Schedule, view, and manage meetings with calendar integration
2. Announcements - Send and receive company-wide or department-specific announcements
3. Employee Directory - Search and view employee information
4. Document Management - Access reports, policies, and forms based on user permissions
5. Messaging - 1-on-1 and group messaging between employees
6. Workflow Tracking - Track request statuses (document requests, approvals, etc.)
7. Notifications - Real-time push notifications for all activities
8. Multilingual Support - Full support for English and Arabic

User Roles: Admin, HR Manager, Department Manager, Team Lead, Manager, Employee

Your role is to:
- Help users navigate the platform
- Answer questions about features and how to use them
- Provide quick access to common actions
- Assist with troubleshooting
- Explain company policies and procedures (when available in documents)

Be professional, concise, and helpful. Support both English and Arabic languages.
''';

  // Quick actions available to users
  List<QuickAction> getQuickActions(bool isRTL) {
    return [
      QuickAction(
        id: 'schedule_meeting',
        label: isRTL ? 'جدولة اجتماع' : 'Schedule Meeting',
        command: '/schedule-meeting',
        icon: 'event',
        description: isRTL ? 'إنشاء اجتماع جديد' : 'Create a new meeting',
      ),
      QuickAction(
        id: 'view_documents',
        label: isRTL ? 'عرض الوثائق' : 'View Documents',
        command: '/view-documents',
        icon: 'description',
        description: isRTL ? 'الوصول للوثائق' : 'Access documents',
      ),
      QuickAction(
        id: 'check_announcements',
        label: isRTL ? 'الإعلانات' : 'Announcements',
        command: '/check-announcements',
        icon: 'announcement',
        description: isRTL ? 'عرض الإعلانات الأخيرة' : 'View recent announcements',
      ),
      QuickAction(
        id: 'my_profile',
        label: isRTL ? 'ملفي الشخصي' : 'My Profile',
        command: '/my-profile',
        icon: 'person',
        description: isRTL ? 'عرض الملف الشخصي' : 'View my profile',
      ),
      QuickAction(
        id: 'help',
        label: isRTL ? 'مساعدة' : 'Help',
        command: '/help',
        icon: 'help',
        description: isRTL ? 'عرض قائمة المساعدة' : 'Show help menu',
      ),
      QuickAction(
        id: 'faq',
        label: isRTL ? 'الأسئلة الشائعة' : 'FAQ',
        command: '/faq',
        icon: 'question_answer',
        description: isRTL ? 'الأسئلة المتكررة' : 'Frequently asked questions',
      ),
    ];
  }

  // FAQ responses
  Map<String, String> getFAQs(bool isRTL) {
    if (isRTL) {
      return {
        'كيف أجدول اجتماع؟': 'لجدولة اجتماع، اذهب إلى شاشة الاجتماعات واضغط على زر + أو استخدم الأمر /schedule-meeting. املأ تفاصيل الاجتماع وحدد الحضور.',
        'كيف أرسل إعلان؟': 'لإرسال إعلان، اذهب إلى شاشة الإعلانات (متاح للمدراء والإداريين فقط) واضغط على زر +. حدد الأولوية والمجموعة المستهدفة.',
        'كيف أطلب وثيقة؟': 'اذهب إلى شاشة الوثائق، ابحث عن الوثيقة المطلوبة، واضغط على "طلب وصول" إذا كانت محمية.',
        'كيف أغير اللغة؟': 'اذهب إلى الملف الشخصي، اختر الإعدادات، ثم اختر اللغة (English/العربية).',
        'من يمكنه إنشاء الإعلانات؟': 'المدراء والإداريين فقط يمكنهم إنشاء إعلانات على مستوى الشركة.',
      };
    } else {
      return {
        'How do I schedule a meeting?': 'To schedule a meeting, go to the Meetings screen and tap the + button or use /schedule-meeting command. Fill in the meeting details and select attendees.',
        'How do I send an announcement?': 'To send an announcement, go to the Announcements screen (admin/manager only) and tap the + button. Select priority and target audience.',
        'How do I request a document?': 'Go to the Documents screen, find the document you need, and click "Request Access" if it\'s restricted.',
        'How do I change the language?': 'Go to Profile, select Settings, then choose your language (English/العربية).',
        'Who can create announcements?': 'Only admins and managers can create company-wide or department announcements.',
        'How do I track my requests?': 'Go to the Workflow screen to see all your pending, approved, and rejected requests in real-time.',
        'How do I message a colleague?': 'Go to the Messaging screen, tap the + button, search for the employee, and start chatting.',
        'What notifications will I receive?': 'You\'ll receive notifications for new meetings, announcements, messages, document approvals, and workflow updates.',
      };
    }
  }

  // Generate AI response using Gemini API
  Future<String> generateAIResponse(String userMessage, List<ChatMessage> conversationHistory, UserModel? user) async {
    try {
      // Build conversation context
      final List<Map<String, dynamic>> contents = [];

      // Add system context
      contents.add({
        'parts': [
          {'text': _systemContext}
        ]
      });

      // Add user context if available
      if (user != null) {
        contents.add({
          'parts': [
            {
              'text': 'User Information:\n'
                  'Name: ${user.fullName}\n'
                  'Position: ${user.position}\n'
                  'Department: ${user.department}\n'
                  'Roles: ${user.roles.join(", ")}'
            }
          ]
        });
      }

      // Add conversation history (last 10 messages)
      final recentHistory = conversationHistory.length > 10
          ? conversationHistory.sublist(conversationHistory.length - 10)
          : conversationHistory;

      for (var message in recentHistory) {
        if (message.sender != MessageSender.system) {
          contents.add({
            'parts': [
              {
                'text': message.sender == MessageSender.user
                    ? 'User: ${message.content}'
                    : 'Assistant: ${message.content}'
              }
            ]
          });
        }
      }

      // Add current user message
      contents.add({
        'parts': [
          {'text': 'User: $userMessage'}
        ]
      });

      // Make API request to Gemini
      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$_geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final candidates = data['candidates'] as List<dynamic>?;

        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List<dynamic>;

          if (parts.isNotEmpty) {
            return parts[0]['text'] as String;
          }
        }

        return 'I apologize, but I couldn\'t generate a proper response. Please try rephrasing your question.';
      } else {
        print('Gemini API Error: ${response.statusCode} - ${response.body}');
        return 'I apologize, but I\'m experiencing technical difficulties. Please try again later.';
      }
    } catch (e) {
      print('Error calling Gemini API: $e');
      return 'I apologize, but I encountered an error. Please check your connection and try again.';
    }
  }

  // Process user message and generate response
  Future<ChatMessage> processMessage(
    String userMessage,
    List<ChatMessage> conversationHistory,
    UserModel? user,
    bool isRTL,
  ) async {
    // Check for commands first
    final command = userMessage.trim().toLowerCase();

    if (command.startsWith('/')) {
      return _handleCommand(command, isRTL);
    }

    // Check FAQ
    final faqs = getFAQs(isRTL);
    for (var entry in faqs.entries) {
      if (userMessage.toLowerCase().contains(entry.key.toLowerCase())) {
        return ChatMessage(
          id: _uuid.v4(),
          content: entry.value,
          sender: MessageSender.bot,
          type: MessageType.text,
          timestamp: DateTime.now(),
          quickActions: ['schedule_meeting', 'view_documents', 'help'],
        );
      }
    }

    // Generate AI response using Gemini
    final aiResponse = await generateAIResponse(userMessage, conversationHistory, user);

    return ChatMessage(
      id: _uuid.v4(),
      content: aiResponse,
      sender: MessageSender.bot,
      type: MessageType.text,
      timestamp: DateTime.now(),
      quickActions: _getSuggestedActions(userMessage, isRTL),
    );
  }

  // Handle slash commands
  ChatMessage _handleCommand(String command, bool isRTL) {
    switch (command) {
      case '/help':
        return ChatMessage(
          id: _uuid.v4(),
          content: isRTL
              ? 'الأوامر المتاحة:\n'
                  '/schedule-meeting - جدولة اجتماع\n'
                  '/view-documents - عرض الوثائق\n'
                  '/check-announcements - الإعلانات\n'
                  '/my-profile - الملف الشخصي\n'
                  '/faq - الأسئلة الشائعة'
              : 'Available Commands:\n'
                  '/schedule-meeting - Schedule a meeting\n'
                  '/view-documents - View documents\n'
                  '/check-announcements - Check announcements\n'
                  '/my-profile - View profile\n'
                  '/faq - Frequently asked questions',
          sender: MessageSender.bot,
          type: MessageType.text,
          timestamp: DateTime.now(),
        );

      case '/faq':
        final faqs = getFAQs(isRTL);
        final faqText = faqs.entries
            .map((e) => '${isRTL ? "س" : "Q"}: ${e.key}\n${isRTL ? "ج" : "A"}: ${e.value}')
            .join('\n\n');
        return ChatMessage(
          id: _uuid.v4(),
          content: faqText,
          sender: MessageSender.bot,
          type: MessageType.text,
          timestamp: DateTime.now(),
        );

      case '/schedule-meeting':
        return ChatMessage(
          id: _uuid.v4(),
          content: isRTL
              ? 'سأساعدك في جدولة اجتماع. اذهب إلى شاشة الاجتماعات لإنشاء اجتماع جديد.'
              : 'I\'ll help you schedule a meeting. Go to the Meetings screen to create a new meeting.',
          sender: MessageSender.bot,
          type: MessageType.quickAction,
          timestamp: DateTime.now(),
          metadata: {'action': 'navigate_meetings'},
        );

      case '/view-documents':
        return ChatMessage(
          id: _uuid.v4(),
          content: isRTL
              ? 'سأأخذك إلى شاشة الوثائق حيث يمكنك الوصول للتقارير والسياسات.'
              : 'I\'ll take you to the Documents screen where you can access reports and policies.',
          sender: MessageSender.bot,
          type: MessageType.quickAction,
          timestamp: DateTime.now(),
          metadata: {'action': 'navigate_documents'},
        );

      case '/check-announcements':
        return ChatMessage(
          id: _uuid.v4(),
          content: isRTL
              ? 'إليك آخر الإعلانات. اذهب إلى شاشة الإعلانات لمزيد من التفاصيل.'
              : 'Here are the latest announcements. Go to the Announcements screen for more details.',
          sender: MessageSender.bot,
          type: MessageType.quickAction,
          timestamp: DateTime.now(),
          metadata: {'action': 'navigate_announcements'},
        );

      case '/my-profile':
        return ChatMessage(
          id: _uuid.v4(),
          content: isRTL
              ? 'سأأخذك إلى ملفك الشخصي.'
              : 'I\'ll take you to your profile.',
          sender: MessageSender.bot,
          type: MessageType.quickAction,
          timestamp: DateTime.now(),
          metadata: {'action': 'navigate_profile'},
        );

      default:
        return ChatMessage(
          id: _uuid.v4(),
          content: isRTL
              ? 'أمر غير معروف. استخدم /help لرؤية الأوامر المتاحة.'
              : 'Unknown command. Use /help to see available commands.',
          sender: MessageSender.bot,
          type: MessageType.text,
          timestamp: DateTime.now(),
        );
    }
  }

  // Get suggested quick actions based on message content
  List<String> _getSuggestedActions(String message, bool isRTL) {
    final lowerMessage = message.toLowerCase();
    final suggestions = <String>[];

    if (lowerMessage.contains('meeting') || lowerMessage.contains('اجتماع')) {
      suggestions.add('schedule_meeting');
    }
    if (lowerMessage.contains('document') || lowerMessage.contains('وثيقة') || lowerMessage.contains('report') || lowerMessage.contains('تقرير')) {
      suggestions.add('view_documents');
    }
    if (lowerMessage.contains('announcement') || lowerMessage.contains('إعلان')) {
      suggestions.add('check_announcements');
    }
    if (lowerMessage.contains('profile') || lowerMessage.contains('ملف')) {
      suggestions.add('my_profile');
    }

    // Always add help as a fallback
    if (suggestions.isEmpty) {
      suggestions.add('help');
    }

    return suggestions.take(3).toList();
  }

  // Save conversation to Firestore
  Future<void> saveConversation(ChatConversation conversation) async {
    await _firestore
        .collection('chatbot_conversations')
        .doc(conversation.id)
        .set(conversation.toMap());
  }

  // Get user's conversation history
  Stream<List<ChatConversation>> getUserConversations(String userId) {
    return _firestore
        .collection('chatbot_conversations')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatConversation.fromMap(doc.data()))
            .toList());
  }

  // Create new conversation
  ChatConversation createNewConversation(String userId, bool isRTL) {
    return ChatConversation(
      id: _uuid.v4(),
      userId: userId,
      messages: [
        ChatMessage(
          id: _uuid.v4(),
          content: isRTL
              ? 'مرحباً! أنا مساعد GCC Connect الذكي. كيف يمكنني مساعدتك اليوم؟'
              : 'Hello! I\'m the GCC Connect AI Assistant. How can I help you today?',
          sender: MessageSender.bot,
          type: MessageType.text,
          timestamp: DateTime.now(),
          quickActions: ['schedule_meeting', 'view_documents', 'help'],
        ),
      ],
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      title: isRTL ? 'محادثة جديدة' : 'New Conversation',
    );
  }
}
