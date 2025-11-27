# GCC Connect - Complete Functionality Guide

This document explains every feature of the GCC Connect app in simple terms. Each section describes what the feature does, where to find the code, and how it works.

---

## Table of Contents

1. [App Overview](#app-overview)
2. [Authentication (Login/Register)](#authentication-loginregister)
3. [Dashboard (Home Screen)](#dashboard-home-screen)
4. [Meetings Management](#meetings-management)
5. [Announcements](#announcements)
6. [Document Management](#document-management)
7. [Workflow Management](#workflow-management)
8. [Messaging/Chat](#messagingchat)
9. [Employee Directory](#employee-directory)
10. [Profile & Settings](#profile--settings)
11. [Notifications](#notifications)
12. [AI Chatbot](#ai-chatbot)
13. [Language Support (Arabic/English)](#language-support-arabicenglish)
14. [Demo Data Seeder](#demo-data-seeder)

---

## App Overview

### What is GCC Connect?
GCC Connect is a corporate communication and management app that helps employees:
- Attend and schedule meetings
- Read company announcements
- Access and share documents
- Submit and track workflow requests (leave, expenses, etc.)
- Chat with colleagues
- View employee directory
- Receive notifications

### App Structure

```
lib/
├── main.dart                 # App entry point - starts the app
├── firebase_options.dart     # Firebase configuration
├── constants/                # App-wide settings (colors, text styles)
├── models/                   # Data structures (User, Meeting, Document, etc.)
├── providers/                # State management (manages app data)
├── services/                 # Database operations (Firebase interactions)
├── screens/                  # User interface screens
├── widgets/                  # Reusable UI components
└── utils/                    # Helper functions
```

---

## Authentication (Login/Register)

### What it does
Allows users to sign in to their account or create a new account.

### Where to find the code

| File | Purpose |
|------|---------|
| `lib/screens/auth/login_screen.dart` | Login page UI |
| `lib/screens/auth/animated_login_screen.dart` | Animated login page (modern design) |
| `lib/screens/auth/register_screen.dart` | Registration page UI |
| `lib/providers/auth_provider.dart` | Manages login state |
| `lib/services/auth_service.dart` | Communicates with Firebase Auth |

### How it works

**Login Process:**
```
1. User enters email and password
2. App calls AuthProvider.signIn(email, password)
3. AuthProvider calls AuthService.signIn()
4. AuthService talks to Firebase Authentication
5. If successful → User data is fetched from Firestore
6. App navigates to Home Screen
7. If failed → Error message is shown
```

**Registration Process:**
```
1. User fills form (name, email, password, department, etc.)
2. App calls AuthProvider.signUp()
3. Firebase creates authentication account
4. User document is created in Firestore 'users' collection
5. User is automatically logged in
```

### Key Code Snippets

**Login Button (login_screen.dart):**
```dart
ElevatedButton(
  onPressed: () async {
    // Validate form
    if (_formKey.currentState!.validate()) {
      // Try to sign in
      await authProvider.signIn(
        _emailController.text,
        _passwordController.text,
      );
      // Navigate to home if successful
      if (authProvider.currentUser != null) {
        context.go('/home');
      }
    }
  },
  child: Text('Sign In'),
)
```

---

## Dashboard (Home Screen)

### What it does
The main screen users see after login. Shows:
- Welcome message with user's name
- Quick action buttons (shortcuts to features)
- Today's meetings
- Recent announcements

### Where to find the code

| File | Purpose |
|------|---------|
| `lib/screens/home/home_screen.dart` | Main container with bottom navigation |
| `lib/screens/home/dashboard_screen.dart` | Dashboard content |
| `lib/screens/home/animated_dashboard_screen.dart` | Animated dashboard (modern) |

### How it works

**Home Screen Structure:**
```
HomeScreen (home_screen.dart)
├── AppBar (top bar with title and notifications)
├── Body (shows current tab content)
│   ├── Dashboard (index 0)
│   ├── Meetings (index 1)
│   ├── Announcements (index 2)
│   ├── Documents (index 3)
│   └── Profile (index 4)
└── BottomNavigationBar (5 tabs at bottom)
```

**Quick Actions (6 buttons):**
```dart
// Each button navigates to a different screen
Quick Actions:
1. Schedule Meeting → Opens Meetings tab
2. Send Announcement → Opens Announcements tab
3. Documents → Opens Documents tab
4. Workflow Tracking → Opens Workflow screen
5. Employee Directory → Opens Directory screen
6. Messages → Opens Messaging screen
```

### Key Code Snippets

**Bottom Navigation (home_screen.dart):**
```dart
BottomNavigationBar(
  currentIndex: _currentIndex,  // Which tab is selected
  onTap: (index) {
    setState(() {
      _currentIndex = index;  // Change to tapped tab
    });
  },
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.calendar), label: 'Meetings'),
    BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Announcements'),
    BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Documents'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
  ],
)
```

---

## Meetings Management

### What it does
- View all scheduled meetings
- Create new meetings
- See meeting details (time, location, attendees)
- Filter meetings by date (upcoming, today, past)
- Calendar view

### Where to find the code

| File | Purpose |
|------|---------|
| `lib/screens/meetings/meetings_screen.dart` | Meetings list UI |
| `lib/screens/meetings/animated_meetings_screen.dart` | Animated version |
| `lib/screens/meetings/calendar_screen.dart` | Calendar view |
| `lib/screens/meetings/create_meeting_screen.dart` | Create meeting form |
| `lib/services/meeting_service.dart` | Database operations |
| `lib/models/meeting_model.dart` | Meeting data structure |
| `lib/providers/meeting_provider.dart` | State management |

### How it works

**Meeting Data Structure (meeting_model.dart):**
```dart
class MeetingModel {
  String id;              // Unique identifier
  String title;           // Meeting name
  String titleAr;         // Arabic title
  String description;     // What the meeting is about
  DateTime date;          // When it happens
  String startTime;       // Start time (e.g., "10:00 AM")
  String endTime;         // End time (e.g., "11:30 AM")
  String location;        // Where it happens
  String organizerId;     // Who created it
  String organizerName;   // Organizer's name
  List<String> attendees; // List of attendee user IDs
  String status;          // scheduled, completed, cancelled
}
```

**Fetching Meetings (meeting_service.dart):**
```dart
// Get all meetings from Firebase
Stream<List<MeetingModel>> getMeetings() {
  return _firestore
      .collection('meetings')           // Go to 'meetings' collection
      .where('isActive', isEqualTo: true) // Only active meetings
      .orderBy('date')                   // Sort by date
      .snapshots()                       // Listen for real-time updates
      .map((snapshot) {
        // Convert each document to MeetingModel
        return snapshot.docs.map((doc) => MeetingModel.fromMap(doc.data())).toList();
      });
}
```

**Creating a Meeting:**
```
1. User taps "+" button
2. Create Meeting form opens
3. User fills: title, description, date, time, location, attendees
4. User taps "Create"
5. MeetingService.createMeeting() is called
6. Meeting document is added to Firestore 'meetings' collection
7. Notifications are sent to attendees
8. User returns to meetings list (new meeting appears)
```

### Database Structure (Firestore)

```
meetings (collection)
└── meeting_id (document)
    ├── id: "meeting_1"
    ├── title: "Q4 Planning Meeting"
    ├── titleAr: "اجتماع تخطيط الربع الرابع"
    ├── description: "Discuss Q4 goals..."
    ├── date: Timestamp
    ├── startTime: "10:00 AM"
    ├── endTime: "11:30 AM"
    ├── location: "Conference Room A"
    ├── organizerId: "user_123"
    ├── organizerName: "Basmah Alhamidi"
    ├── attendees: ["user_456", "user_789"]
    ├── status: "scheduled"
    └── isActive: true
```

---

## Announcements

### What it does
- View company-wide announcements
- Create new announcements (if authorized)
- Filter by category (general, HR, IT, marketing)
- Pin important announcements
- Set priority levels (high, medium, low)

### Where to find the code

| File | Purpose |
|------|---------|
| `lib/screens/announcements/announcements_screen.dart` | Announcements list |
| `lib/screens/announcements/create_announcement_screen.dart` | Create form |
| `lib/services/announcement_service.dart` | Database operations |
| `lib/models/announcement_model.dart` | Data structure |

### How it works

**Announcement Data Structure:**
```dart
class AnnouncementModel {
  String id;
  String title;           // Announcement title
  String titleAr;         // Arabic title
  String content;         // Full announcement text
  String contentAr;       // Arabic content
  String authorId;        // Who posted it
  String authorName;      // Author's name
  String department;      // Which department
  String priority;        // high, medium, low
  String category;        // general, hr, it, marketing
  bool isPinned;          // Pinned to top?
  DateTime createdAt;     // When posted
  DateTime expiresAt;     // When to hide
}
```

**Displaying Announcements:**
```dart
// In announcements_screen.dart
StreamBuilder<List<AnnouncementModel>>(
  stream: AnnouncementService().getAnnouncements(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final announcements = snapshot.data!;
      return ListView.builder(
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final announcement = announcements[index];
          return AnnouncementCard(announcement: announcement);
        },
      );
    }
    return CircularProgressIndicator(); // Loading
  },
)
```

---

## Document Management

### What it does
- Browse company documents
- Upload new documents
- Download documents
- Request access to restricted documents
- Filter by category (policies, forms, reports, etc.)
- Track document statistics

### Where to find the code

| File | Purpose |
|------|---------|
| `lib/screens/documents/documents_screen.dart` | Main documents UI |
| `lib/screens/documents/web_helper_stub.dart` | Web download helper |
| `lib/services/document_service.dart` | Database & storage operations |
| `lib/models/document_model.dart` | Data structure |

### How it works

**Document Data Structure:**
```dart
class DocumentModel {
  String id;
  String title;              // Document name
  String description;        // What it contains
  String fileUrl;            // Download URL (Firebase Storage)
  String fileName;           // Original file name
  String fileType;           // pdf, docx, xlsx, etc.
  double fileSize;           // Size in bytes
  String uploadedById;       // Who uploaded
  String uploadedByName;     // Uploader's name
  List<String> allowedRoles; // Who can access (empty = everyone)
  List<String> allowedDepartments; // Which departments can access
  String category;           // policies, forms, reports, etc.
}
```

**Document Access Control:**
```dart
// In document_service.dart - filtering logic
bool canUserAccess(DocumentModel doc, UserModel user) {
  // User can always see their own documents
  if (doc.uploadedById == user.id) return true;

  // If no restrictions, everyone can access
  if (doc.allowedRoles.isEmpty && doc.allowedDepartments.isEmpty) {
    return true;
  }

  // Check if user's role is allowed
  if (doc.allowedRoles.isNotEmpty) {
    if (user.roles.any((role) => doc.allowedRoles.contains(role))) {
      return true;
    }
  }

  // Check if user's department is allowed
  if (doc.allowedDepartments.isNotEmpty) {
    if (doc.allowedDepartments.contains(user.department)) {
      return true;
    }
  }

  return false; // No access
}
```

**Upload Process:**
```
1. User taps "Upload Document"
2. File picker opens
3. User selects a file
4. File is uploaded to Firebase Storage
5. Download URL is generated
6. Document metadata is saved to Firestore
7. Document appears in the list
```

**Tabs in Documents Screen:**
```
Tab 1: All Documents - Shows all accessible documents
Tab 2: My Uploads - Documents uploaded by current user
Tab 3: Requests - Document access requests (for managers)
Tab 4: Statistics - Document usage stats with charts
```

---

## Workflow Management

### What it does
- Submit requests (leave, expenses, purchases, approvals)
- Track request status (pending, in progress, approved, rejected)
- Approve/reject requests (for managers)
- View workflow statistics
- Multi-step approval process

### Where to find the code

| File | Purpose |
|------|---------|
| `lib/screens/workflow/workflow_screen.dart` | Main workflow UI |
| `lib/screens/workflow/create_workflow_screen.dart` | Create request form |
| `lib/services/workflow_service.dart` | Database operations |
| `lib/models/workflow_model.dart` | Data structure |

### How it works

**Workflow Data Structure:**
```dart
class WorkflowModel {
  String id;
  String title;              // Request title
  String titleAr;            // Arabic title
  String description;        // Request details
  String type;               // leaveRequest, expenseClaim, purchaseRequest, approval
  String status;             // pending, inProgress, approved, rejected, completed
  String priority;           // high, medium, low
  String initiatorId;        // Who submitted
  String initiatorName;      // Submitter's name
  String assigneeId;         // Current approver
  String assigneeName;       // Approver's name
  String department;         // Which department
  DateTime dueDate;          // Deadline
  int currentStepIndex;      // Which approval step
  List<WorkflowStep> steps;  // Approval steps
  List<String> attachments;  // Attached files
  List<Comment> comments;    // Discussion
}
```

**Workflow Steps (Multi-level Approval):**
```dart
// Example: Purchase Request needs 2 approvals
steps: [
  WorkflowStep(
    title: "Manager Approval",
    assigneeId: "manager_id",
    status: "completed",  // Already approved
  ),
  WorkflowStep(
    title: "Finance Approval",
    assigneeId: "finance_id",
    status: "pending",  // Waiting for approval
  ),
]
```

**Status Flow:**
```
pending → inProgress → approved/rejected → completed
    │                        │
    └── (can be) ───────────→ rejected
```

**Tabs in Workflow Screen:**
```
Tab 1: My Requests - Workflows submitted by user
Tab 2: Pending Approval - Requests waiting for user's approval
Tab 3: All Workflows - All workflows (for admins)
Tab 4: Statistics - Charts showing workflow data
```

---

## Messaging/Chat

### What it does
- Direct messages between employees
- Group chats
- Real-time messaging
- Message notifications

### Where to find the code

| File | Purpose |
|------|---------|
| `lib/screens/messaging/messaging_screen.dart` | Chat list |
| `lib/screens/messaging/chat_screen.dart` | Individual chat view |
| `lib/services/chat_service.dart` | Database operations |
| `lib/models/chat_model.dart` | Chat data structure |
| `lib/models/message_model.dart` | Message data structure |

### How it works

**Chat Data Structure:**
```dart
class ChatModel {
  String id;
  String type;                    // 'direct' or 'group'
  String? name;                   // Group name (for group chats)
  List<String> participants;      // User IDs in chat
  Map<String, String> participantNames; // User ID → Name mapping
  String lastMessage;             // Preview of last message
  DateTime lastMessageAt;         // When last message was sent
  String lastMessageBy;           // Who sent last message
}

class MessageModel {
  String id;
  String chatId;          // Which chat this belongs to
  String senderId;        // Who sent it
  String senderName;      // Sender's name
  String content;         // Message text
  DateTime sentAt;        // When sent
  bool isRead;           // Has recipient read it?
}
```

**Real-time Messaging:**
```dart
// Listening for new messages in chat_screen.dart
StreamBuilder<List<MessageModel>>(
  stream: ChatService().getMessages(chatId),
  builder: (context, snapshot) {
    // Messages update automatically when new ones arrive
    final messages = snapshot.data ?? [];
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(message: messages[index]);
      },
    );
  },
)
```

**Sending a Message:**
```dart
// When user taps send button
void sendMessage() {
  final message = MessageModel(
    chatId: currentChatId,
    senderId: currentUser.id,
    senderName: currentUser.fullName,
    content: _messageController.text,
    sentAt: DateTime.now(),
  );

  ChatService().sendMessage(message);
  _messageController.clear();
}
```

---

## Employee Directory

### What it does
- View list of all employees
- Search employees by name
- Filter by department
- View employee details (email, phone, position)
- Contact employees directly

### Where to find the code

| File | Purpose |
|------|---------|
| `lib/screens/directory/directory_screen.dart` | Employee list |
| `lib/services/user_service.dart` | Fetches user data |
| `lib/models/user_model.dart` | User data structure |

### How it works

**User Data Structure:**
```dart
class UserModel {
  String id;
  String email;
  String firstName;
  String lastName;
  String? phoneNumber;
  String? department;
  String? position;
  String? profileImageUrl;
  List<String> roles;      // employee, manager, admin
  bool isActive;
  DateTime createdAt;
  DateTime? lastLogin;

  // Computed property
  String get fullName => '$firstName $lastName';
}
```

**Fetching Employees:**
```dart
// In user_service.dart
Stream<List<UserModel>> getAllUsers() {
  return _firestore
      .collection('users')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
      });
}
```

**Search Functionality:**
```dart
// Filter employees as user types
List<UserModel> filteredUsers = allUsers.where((user) {
  final searchLower = searchQuery.toLowerCase();
  return user.fullName.toLowerCase().contains(searchLower) ||
         user.email.toLowerCase().contains(searchLower) ||
         (user.department?.toLowerCase().contains(searchLower) ?? false);
}).toList();
```

---

## Profile & Settings

### What it does
- View personal profile information
- Edit profile (name, phone, profile picture)
- Change app language (English/Arabic)
- Change app theme (Light/Dark/System)
- Toggle notifications
- Sign out
- Seed demo data (for testing)

### Where to find the code

| File | Purpose |
|------|---------|
| `lib/screens/profile/profile_screen.dart` | Profile view |
| `lib/screens/profile/edit_profile_screen.dart` | Edit profile form |
| `lib/providers/app_provider.dart` | Language & theme settings |

### How it works

**Profile Sections:**
```
1. Profile Header
   - Profile picture
   - Full name
   - Email
   - Position & Department

2. Personal Information
   - First Name
   - Last Name
   - Phone Number
   - Join Date
   - Last Login

3. Work Information
   - Department
   - Position
   - Roles

4. Settings
   - Language (English/Arabic)
   - Theme (Light/Dark/System)
   - Notifications toggle

5. Actions
   - Seed Demo Data (for testing)
   - Help & Support
   - Privacy Policy
   - Sign Out
```

**Changing Language:**
```dart
// In app_provider.dart
void changeLanguage(String languageCode) {
  _locale = Locale(languageCode);
  _savePreferences();  // Save to device
  notifyListeners();   // Update UI
}

// Usage in profile_screen.dart
appProvider.changeLanguage('ar');  // Switch to Arabic
appProvider.changeLanguage('en');  // Switch to English
```

**Changing Theme:**
```dart
// In app_provider.dart
void changeTheme(ThemeMode mode) {
  _themeMode = mode;
  _savePreferences();
  notifyListeners();
}

// Options: ThemeMode.light, ThemeMode.dark, ThemeMode.system
```

---

## Notifications

### What it does
- Receive alerts for meetings, announcements, workflows, messages
- Mark notifications as read
- Navigate to related content when tapped

### Where to find the code

| File | Purpose |
|------|---------|
| `lib/screens/notifications/notifications_screen.dart` | Notifications list |
| `lib/services/notification_service.dart` | Database operations |
| `lib/models/notification_model.dart` | Data structure |

### How it works

**Notification Data Structure:**
```dart
class NotificationModel {
  String id;
  String userId;          // Who receives it
  String title;           // Notification title
  String titleAr;         // Arabic title
  String body;            // Notification content
  String bodyAr;          // Arabic content
  String type;            // meeting, announcement, workflow, message, document
  Map<String, dynamic> data;  // Related IDs (meetingId, workflowId, etc.)
  bool isRead;
  DateTime createdAt;
}
```

**Notification Types:**
```
1. Meeting Notifications
   - New meeting scheduled
   - Meeting reminder
   - Meeting cancelled

2. Announcement Notifications
   - New company announcement

3. Workflow Notifications
   - New request submitted (for approvers)
   - Request approved/rejected (for submitters)
   - Comment added

4. Message Notifications
   - New direct message
   - New group message

5. Document Notifications
   - Document shared with you
   - Access request approved
```

**Notification Badge (in app bar):**
```dart
// Shows count of unread notifications
StreamBuilder<List<NotificationModel>>(
  stream: NotificationService().getUnreadNotifications(userId),
  builder: (context, snapshot) {
    final unreadCount = snapshot.data?.length ?? 0;
    return Badge(
      label: Text('$unreadCount'),
      isLabelVisible: unreadCount > 0,
      child: Icon(Icons.notifications),
    );
  },
)
```

---

## AI Chatbot

### What it does
- Answer questions about the app
- Help users navigate features
- Provide information assistance

### Where to find the code

| File | Purpose |
|------|---------|
| `lib/screens/chatbot/chatbot_screen.dart` | Chat interface |
| `lib/services/chatbot_service.dart` | AI integration |

### How it works

**Chatbot Integration:**
```dart
// Uses Google Gemini AI
class ChatbotService {
  final GenerativeModel _model;

  Future<String> sendMessage(String userMessage) async {
    final response = await _model.generateContent([
      Content.text(userMessage)
    ]);
    return response.text ?? 'Sorry, I could not understand.';
  }
}
```

---

## Language Support (Arabic/English)

### What it does
- Full Arabic and English support
- Right-to-Left (RTL) layout for Arabic
- Translated content throughout app

### Where to find the code

| File | Purpose |
|------|---------|
| `lib/providers/app_provider.dart` | Language state management |
| All screen files | `isRTL` checks for translations |

### How it works

**RTL Detection:**
```dart
// In any screen
final isRTL = appProvider.isRTL;  // true if Arabic

// Using isRTL for translations
Text(isRTL ? 'مرحبا' : 'Hello')

// Dynamic text direction
Directionality(
  textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
  child: MyWidget(),
)
```

**Data with Translations:**
```dart
// Models have both English and Arabic fields
class MeetingModel {
  String title;     // English: "Q4 Planning Meeting"
  String titleAr;   // Arabic: "اجتماع تخطيط الربع الرابع"
}

// Display based on language
Text(isRTL ? meeting.titleAr : meeting.title)
```

---

## Demo Data Seeder

### What it does
Populates the app with sample data for testing/demonstration purposes.

### Where to find the code

| File | Purpose |
|------|---------|
| `lib/utils/demo_data_seeder.dart` | Creates demo data |
| `lib/screens/profile/profile_screen.dart` | Button to trigger seeding |

### How to use

1. Open the app and login
2. Go to **Profile** tab (bottom right)
3. Scroll to **Actions** section
4. Tap **"Seed Demo Data"**
5. Confirm in the dialog
6. Wait for completion

### What data is created

```dart
// Demo Users (5 users)
- Basmah Alhamidi (221410363) - Engineering, Senior Developer
- Nouf AlGhanem (221410281) - HR, HR Manager
- Dima Althenayan (221410087) - Finance, Financial Analyst
- Leen Al Fawaz (222310838) - Marketing, Marketing Director
- Jana AlZmami (221410306) - IT Support, IT Manager

// Demo Meetings (5 meetings)
- Q4 Planning Meeting
- Product Launch Review
- Weekly Team Standup
- Budget Review Meeting
- IT Infrastructure Update

// Demo Announcements (6 announcements)
- Company Holiday Notice
- New Employee Onboarding
- System Maintenance Scheduled
- Q3 Performance Results
- New Marketing Campaign
- Health & Safety Training

// Demo Documents (7 documents)
- Employee Handbook 2024
- IT Security Guidelines
- Annual Report 2023
- Leave Request Form
- Brand Guidelines
- Expense Reimbursement Policy
- Project Proposal Template

// Demo Workflows (5 workflows)
- Annual Leave Request
- Equipment Purchase Request
- Travel Expense Claim
- New Project Approval
- Sick Leave Request

// Demo Chats (4 chats)
- 2 Direct messages
- 2 Group chats

// Demo Notifications (8 notifications)
- Various types for different users
```

---

## Firebase Database Structure

### Collections Overview

```
Firestore Database
├── users/                    # User accounts
│   └── {userId}/
│       ├── id, email, firstName, lastName
│       ├── department, position, roles
│       └── isActive, createdAt, lastLogin
│
├── meetings/                 # Meeting schedules
│   └── {meetingId}/
│       ├── title, titleAr, description
│       ├── date, startTime, endTime, location
│       ├── organizerId, organizerName
│       └── attendees[], status, isActive
│
├── announcements/            # Company announcements
│   └── {announcementId}/
│       ├── title, titleAr, content, contentAr
│       ├── authorId, authorName, department
│       ├── priority, category
│       └── isPinned, createdAt, expiresAt
│
├── documents/                # Document metadata
│   └── {documentId}/
│       ├── title, description, category
│       ├── fileUrl, fileName, fileType, fileSize
│       ├── uploadedById, uploadedByName
│       └── allowedRoles[], allowedDepartments[]
│
├── document_requests/        # Access requests
│   └── {requestId}/
│       ├── documentId, requesterId, requesterName
│       └── status, reason, createdAt
│
├── workflows/                # Workflow requests
│   └── {workflowId}/
│       ├── title, titleAr, description
│       ├── type, status, priority
│       ├── initiatorId, assigneeId
│       ├── department, dueDate
│       ├── steps[], comments[]
│       └── currentStepIndex
│
├── chats/                    # Chat rooms
│   └── {chatId}/
│       ├── type (direct/group), name
│       ├── participants[], participantNames{}
│       └── lastMessage, lastMessageAt
│
├── messages/                 # Chat messages
│   └── {messageId}/
│       ├── chatId, senderId, senderName
│       ├── content, sentAt
│       └── isRead
│
└── notifications/            # User notifications
    └── {notificationId}/
        ├── userId, title, titleAr
        ├── body, bodyAr, type
        ├── data{}, isRead
        └── createdAt
```

### Firebase Storage Structure

```
Firebase Storage
└── documents/
    └── {userId}/
        └── {timestamp}_{filename}
            # Uploaded document files
```

---

## State Management (Providers)

The app uses the Provider package for state management. Providers hold app-wide data and notify widgets when data changes.

### Providers Overview

| Provider | Purpose | Key Data |
|----------|---------|----------|
| `AuthProvider` | User authentication | currentUser, isLoggedIn |
| `AppProvider` | App settings | locale, themeMode |
| `MeetingProvider` | Meeting data | meetings list |

### How Providers Work

```dart
// 1. Define a provider
class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Future<void> signIn(String email, String password) async {
    // ... authentication logic ...
    _currentUser = user;
    notifyListeners();  // Tell widgets to rebuild
  }
}

// 2. Provide it to the app (in main.dart)
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => AppProvider()),
  ],
  child: MyApp(),
)

// 3. Use it in widgets
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    final user = authProvider.currentUser;
    return Text('Hello, ${user?.fullName}');
  },
)
```

---

## Navigation (GoRouter)

The app uses GoRouter for navigation between screens.

### Routes Configuration

```dart
// In main.dart or routes.dart
GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => RegisterScreen()),
    GoRoute(path: '/home', builder: (_, __) => HomeScreen()),
    GoRoute(path: '/workflow', builder: (_, __) => WorkflowScreen()),
    GoRoute(path: '/directory', builder: (_, __) => DirectoryScreen()),
    GoRoute(path: '/messaging', builder: (_, __) => MessagingScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => NotificationsScreen()),
    GoRoute(path: '/chatbot', builder: (_, __) => ChatbotScreen()),
  ],
)
```

### Navigation Examples

```dart
// Go to a screen
context.go('/home');

// Go with replacement (can't go back)
context.go('/login');

// Push (can go back)
context.push('/notifications');

// Go back
context.pop();
```

---

## Quick Reference: Common Operations

### How to add a new feature screen:

1. Create screen file in `lib/screens/{feature}/`
2. Create model in `lib/models/{feature}_model.dart`
3. Create service in `lib/services/{feature}_service.dart`
4. Add route in main.dart GoRouter
5. Add navigation button/link where needed

### How to add a new database collection:

1. Define model class with `fromMap()` and `toMap()` methods
2. Create service class with CRUD operations
3. Use StreamBuilder for real-time data display

### How to add translations:

1. Add `titleAr` field to model alongside `title`
2. In UI: `Text(isRTL ? item.titleAr : item.title)`

---

## Troubleshooting

### Data not showing:
1. Check Firestore rules allow read access
2. Check collection/document path is correct
3. Check query filters match data
4. Look at console for error messages

### Build errors:
1. Run `flutter clean`
2. Run `flutter pub get`
3. Check for missing imports
4. Check for syntax errors


#
