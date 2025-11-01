# 🤖 GCC Connect AI Chatbot Setup Guide

## Overview

The GCC Connect AI Chatbot is powered by **Google Gemini Pro API**, providing intelligent assistance to users for navigating the platform, answering questions, and performing quick actions.

## Features

### ✨ AI-Powered Conversations
- Natural language understanding using Google Gemini Pro
- Context-aware responses based on user information
- Conversation history for coherent multi-turn dialogues
- Support for both English and Arabic languages

### 🎯 Quick Actions
The chatbot provides instant access to common tasks:
- **Schedule Meeting** - `/schedule-meeting`
- **View Documents** - `/view-documents`
- **Check Announcements** - `/check-announcements`
- **My Profile** - `/my-profile`
- **Help** - `/help`
- **FAQ** - `/faq`

### 📚 Built-in FAQ System
Pre-configured answers for common questions:
- How to schedule meetings
- How to send announcements
- How to request documents
- How to change language
- Permission-based features
- And more...

### 🎨 Beautiful UI
- Animated message bubbles
- Typing indicators
- Quick action chips
- Responsive design (Web + Mobile)
- RTL support for Arabic

---

## 🔑 Getting Your Gemini API Key

### Step 1: Access Google AI Studio

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account

### Step 2: Create API Key

1. Click on **"Get API Key"** or **"Create API Key"**
2. Select or create a Google Cloud project
3. Copy the generated API key

### Step 3: Configure the API Key

Open the file: `lib/services/chatbot_service.dart`

Find line 13 and replace `YOUR_GEMINI_API_KEY_HERE` with your actual API key:

```dart
static const String _geminiApiKey = 'AIzaSy...your-actual-api-key...';
```

**⚠️ IMPORTANT SECURITY NOTES:**
- **Never commit your API key to version control**
- Add the API key to `.gitignore` or use environment variables
- For production, use secure secret management (Firebase Remote Config, AWS Secrets Manager, etc.)

---

## 🚀 Usage

### Accessing the Chatbot

Users can access the AI Assistant in two ways:

1. **From Dashboard**: Tap the floating "AI Assistant" button (green button with robot icon)
2. **Direct Navigation**: Navigate to ChatbotScreen programmatically

### Chatbot Commands

Users can type natural questions or use slash commands:

#### Natural Language Examples:
- "How do I schedule a meeting?"
- "Show me available documents"
- "What announcements did I miss?"
- "كيف أجدول اجتماع؟" (Arabic)

#### Slash Commands:
- `/help` - Show all available commands
- `/faq` - Display frequently asked questions
- `/schedule-meeting` - Navigate to meetings screen
- `/view-documents` - Navigate to documents screen
- `/check-announcements` - Navigate to announcements screen
- `/my-profile` - Navigate to user profile

### Quick Actions

The chatbot suggests contextual quick actions based on:
- User's message content
- Current conversation context
- User's role and permissions

---

## 🔧 Configuration

### Customizing the System Context

Edit the `_systemContext` variable in `chatbot_service.dart` to customize how the AI understands your organization:

```dart
final String _systemContext = '''
You are an AI assistant for [YOUR COMPANY NAME]...
// Add your company-specific information
''';
```

### Adding Custom FAQs

Add new FAQs in the `getFAQs()` method in `chatbot_service.dart`:

```dart
Map<String, String> getFAQs(bool isRTL) {
  if (isRTL) {
    return {
      'سؤالك هنا؟': 'الجواب هنا',
      // Add more Arabic FAQs
    };
  } else {
    return {
      'Your question here?': 'Your answer here',
      // Add more English FAQs
    };
  }
}
```

### Adding New Quick Actions

Add custom quick actions in the `getQuickActions()` method:

```dart
QuickAction(
  id: 'your_action_id',
  label: isRTL ? 'النص العربي' : 'English Text',
  command: '/your-command',
  icon: 'icon_name',
  description: 'Description here',
),
```

Then handle the command in `_handleCommand()` method.

---

## 📊 Data Storage

### Conversation History

Conversations are stored in Firestore:
- **Collection**: `chatbot_conversations`
- **Document ID**: Unique conversation ID
- **Fields**:
  - `userId` - User who owns the conversation
  - `messages` - Array of chat messages
  - `createdAt` - Conversation creation timestamp
  - `lastMessageAt` - Last message timestamp
  - `title` - Conversation title
  - `isActive` - Whether conversation is active

### Message Structure

Each message contains:
- `id` - Unique message ID
- `content` - Message text
- `sender` - user, bot, or system
- `type` - text, quickAction, suggestion, error
- `timestamp` - When message was sent
- `metadata` - Additional data (navigation actions, etc.)
- `quickActions` - Suggested quick action IDs

---

## 🎛️ API Configuration

### Gemini API Settings

Current configuration (in `chatbot_service.dart`):

```dart
'generationConfig': {
  'temperature': 0.7,        // Creativity (0.0 = focused, 1.0 = creative)
  'topK': 40,                // Top K sampling
  'topP': 0.95,              // Nucleus sampling
  'maxOutputTokens': 1024,   // Max response length
}
```

### Safety Settings

Content filtering levels:
- Harassment: BLOCK_MEDIUM_AND_ABOVE
- Hate Speech: BLOCK_MEDIUM_AND_ABOVE
- Sexually Explicit: BLOCK_MEDIUM_AND_ABOVE
- Dangerous Content: BLOCK_MEDIUM_AND_ABOVE

---

## 🔒 Security Best Practices

### 1. API Key Management

**Development:**
```dart
// Use environment variables
static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
```

**Production:**
- Use Firebase Remote Config
- Implement server-side proxy
- Use Cloud Functions to make API calls
- Never expose API key in client code

### 2. Rate Limiting

Implement rate limiting to prevent abuse:
```dart
// TODO: Add rate limiting logic
// Example: Max 50 messages per user per day
```

### 3. Content Filtering

- Gemini API has built-in safety filters
- Additional validation on user input
- Monitoring for inappropriate usage

---

## 💰 API Costs

### Gemini Pro Pricing (as of 2024)

- **Free Tier**: 60 requests per minute
- **Paid Tier**: $0.00025 per 1K characters (input)
- **Paid Tier**: $0.0005 per 1K characters (output)

### Cost Estimation

Average conversation:
- 10 messages per session
- ~500 characters per message
- Cost: ~$0.01 per session

For 1000 users with 5 sessions/month:
- ~50,000 sessions/month
- Estimated cost: ~$500/month

**Tip**: Use FAQ responses for common questions to reduce API calls!

---

## 🧪 Testing

### Manual Testing Checklist

- [ ] Test natural language questions (English & Arabic)
- [ ] Test all slash commands
- [ ] Test quick action buttons
- [ ] Test conversation history
- [ ] Test navigation actions
- [ ] Test error handling (no internet, API errors)
- [ ] Test on web and mobile
- [ ] Test RTL layout for Arabic

### Test Messages

```
English:
- "How do I schedule a meeting?"
- "Show me my documents"
- "/help"
- "What can you help me with?"

Arabic:
- "كيف أجدول اجتماع؟"
- "أين الوثائق؟"
- "/help"
- "ماذا تستطيع أن تساعدني؟"
```

---

## 🐛 Troubleshooting

### Issue: "API Key Error"
**Solution**: Verify your API key is correct and has Gemini API enabled

### Issue: "No response from bot"
**Solutions**:
- Check internet connection
- Verify Firestore security rules allow writes
- Check browser console for errors
- Verify API key quota not exceeded

### Issue: "Conversation not saving"
**Solution**: Check Firestore security rules:
```javascript
match /chatbot_conversations/{conversationId} {
  allow read, write: if request.auth != null &&
                     request.auth.uid == resource.data.userId;
}
```

---

## 📈 Future Enhancements

Planned features:
- [ ] Voice input/output
- [ ] Image recognition for document queries
- [ ] Integration with company knowledge base
- [ ] Sentiment analysis
- [ ] Conversation analytics dashboard
- [ ] Multi-language support (French, Spanish, etc.)
- [ ] Proactive notifications based on user behavior
- [ ] Integration with external systems (HR, CRM, etc.)

---

## 📞 Support

For issues or questions:
1. Check this documentation
2. Review Gemini API docs: https://ai.google.dev/docs
3. Check Firebase console for errors
4. Contact development team

---

## 📄 License

Copyright © 2024 GCC Connect. All rights reserved.

---

**Happy Chatting! 🤖✨**
