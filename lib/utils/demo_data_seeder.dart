import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Demo Data Seeder for GCC Connect App
/// Call DemoDataSeeder.seedAllData() to populate Firebase with demo data
class DemoDataSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String? _currentUserId;
  static String? _currentUserName;

  /// Seeds all demo data
  static Future<void> seedAllData() async {
    print('🚀 Starting to add demo data...');

    // Get current user info
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _currentUserId = currentUser.uid;
      // Try to get user name from Firestore
      try {
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          _currentUserName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
          if (_currentUserName!.isEmpty) {
            _currentUserName = currentUser.email?.split('@').first ?? 'Current User';
          }
        } else {
          _currentUserName = currentUser.email?.split('@').first ?? 'Current User';
        }
      } catch (e) {
        _currentUserName = currentUser.email?.split('@').first ?? 'Current User';
      }
      print('   Current user: $_currentUserName ($_currentUserId)');
    }

    await seedUsers();
    await seedMeetings();
    await seedAnnouncements();
    await seedDocuments();
    await seedWorkflows();
    await seedChats();
    await seedNotifications();

    print('✅ All demo data added successfully!');
  }

  /// Seeds demo users
  static Future<void> seedUsers() async {
    print('👥 Adding demo users...');

    final users = [
      {
        'id': 'demo_user_1',
        'email': 'basmah.alhamidi@gcc.com',
        'firstName': 'Basmah',
        'lastName': 'Alhamidi',
        'phoneNumber': '+966 50 123 4567',
        'department': 'Engineering',
        'position': 'Senior Developer',
        'roles': ['employee'],
        'isActive': true,
        'studentId': '221410363',
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
      },
      {
        'id': 'demo_user_2',
        'email': 'nouf.alghanem@gcc.com',
        'firstName': 'Nouf',
        'lastName': 'AlGhanem',
        'phoneNumber': '+966 55 234 5678',
        'department': 'Human Resources',
        'position': 'HR Manager',
        'roles': ['employee', 'manager'],
        'isActive': true,
        'studentId': '221410281',
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
      },
      {
        'id': 'demo_user_3',
        'email': 'dima.althenayan@gcc.com',
        'firstName': 'Dima',
        'lastName': 'Althenayan',
        'phoneNumber': '+966 54 345 6789',
        'department': 'Finance',
        'position': 'Financial Analyst',
        'roles': ['employee'],
        'isActive': true,
        'studentId': '221410087',
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
      },
      {
        'id': 'demo_user_4',
        'email': 'leen.alfawaz@gcc.com',
        'firstName': 'Leen',
        'lastName': 'Al Fawaz',
        'phoneNumber': '+966 56 456 7890',
        'department': 'Marketing',
        'position': 'Marketing Director',
        'roles': ['employee', 'manager'],
        'isActive': true,
        'studentId': '222310838',
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
      },
      {
        'id': 'demo_user_5',
        'email': 'jana.alzmami@gcc.com',
        'firstName': 'Jana',
        'lastName': 'AlZmami',
        'phoneNumber': '+966 59 567 8901',
        'department': 'IT Support',
        'position': 'IT Manager',
        'roles': ['employee', 'admin'],
        'isActive': true,
        'studentId': '221410306',
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
      },
    ];

    for (var user in users) {
      await _firestore.collection('users').doc(user['id'] as String).set(user);
    }
    print('   ✓ Added ${users.length} demo users');
  }

  /// Seeds demo meetings
  static Future<void> seedMeetings() async {
    print('📅 Adding demo meetings...');

    final now = DateTime.now();
    final meetings = [
      {
        'id': 'meeting_1',
        'title': 'Q4 Planning Meeting',
        'titleAr': 'اجتماع تخطيط الربع الرابع',
        'description': 'Discuss Q4 goals and project allocations for all departments.',
        'descriptionAr': 'مناقشة أهداف الربع الرابع وتوزيع المشاريع لجميع الأقسام.',
        'date': Timestamp.fromDate(now.add(const Duration(days: 1))),
        'startTime': '10:00 AM',
        'endTime': '11:30 AM',
        'location': 'Conference Room A',
        'locationAr': 'قاعة المؤتمرات أ',
        'organizerId': 'demo_user_2',
        'organizerName': 'Nouf AlGhanem',
        'attendees': ['demo_user_1', 'demo_user_3', 'demo_user_4', 'demo_user_5'],
        'status': 'scheduled',
        'createdAt': Timestamp.now(),
        'isActive': true,
      },
      {
        'id': 'meeting_2',
        'title': 'Product Launch Review',
        'titleAr': 'مراجعة إطلاق المنتج',
        'description': 'Review the upcoming product launch strategy and marketing materials.',
        'descriptionAr': 'مراجعة استراتيجية إطلاق المنتج القادم والمواد التسويقية.',
        'date': Timestamp.fromDate(now.add(const Duration(days: 2))),
        'startTime': '2:00 PM',
        'endTime': '3:30 PM',
        'location': 'Meeting Room B',
        'locationAr': 'غرفة الاجتماعات ب',
        'organizerId': 'demo_user_4',
        'organizerName': 'Leen Al Fawaz',
        'attendees': ['demo_user_1', 'demo_user_2'],
        'status': 'scheduled',
        'createdAt': Timestamp.now(),
        'isActive': true,
      },
      {
        'id': 'meeting_3',
        'title': 'Weekly Team Standup',
        'titleAr': 'اجتماع الفريق الأسبوعي',
        'description': 'Weekly sync meeting for engineering team updates.',
        'descriptionAr': 'اجتماع المزامنة الأسبوعي لتحديثات فريق الهندسة.',
        'date': Timestamp.fromDate(now),
        'startTime': '9:00 AM',
        'endTime': '9:30 AM',
        'location': 'Virtual - Microsoft Teams',
        'locationAr': 'افتراضي - مايكروسوفت تيمز',
        'organizerId': 'demo_user_1',
        'organizerName': 'Basmah Alhamidi',
        'attendees': ['demo_user_5'],
        'status': 'scheduled',
        'createdAt': Timestamp.now(),
        'isActive': true,
      },
      {
        'id': 'meeting_4',
        'title': 'Budget Review Meeting',
        'titleAr': 'اجتماع مراجعة الميزانية',
        'description': 'Annual budget review and allocation for next fiscal year.',
        'descriptionAr': 'مراجعة الميزانية السنوية والتخصيص للسنة المالية القادمة.',
        'date': Timestamp.fromDate(now.add(const Duration(days: 3))),
        'startTime': '11:00 AM',
        'endTime': '12:30 PM',
        'location': 'Executive Boardroom',
        'locationAr': 'قاعة مجلس الإدارة',
        'organizerId': 'demo_user_3',
        'organizerName': 'Dima Althenayan',
        'attendees': ['demo_user_2', 'demo_user_4', 'demo_user_5'],
        'status': 'scheduled',
        'createdAt': Timestamp.now(),
        'isActive': true,
      },
      {
        'id': 'meeting_5',
        'title': 'IT Infrastructure Update',
        'titleAr': 'تحديث البنية التحتية لتقنية المعلومات',
        'description': 'Discussion on upcoming IT infrastructure improvements.',
        'descriptionAr': 'مناقشة تحسينات البنية التحتية لتقنية المعلومات.',
        'date': Timestamp.fromDate(now.add(const Duration(days: 5))),
        'startTime': '3:00 PM',
        'endTime': '4:00 PM',
        'location': 'IT Department',
        'locationAr': 'قسم تقنية المعلومات',
        'organizerId': 'demo_user_5',
        'organizerName': 'Jana AlZmami',
        'attendees': ['demo_user_1', 'demo_user_2', 'demo_user_3', 'demo_user_4'],
        'status': 'scheduled',
        'createdAt': Timestamp.now(),
        'isActive': true,
      },
    ];

    for (var meeting in meetings) {
      await _firestore.collection('meetings').doc(meeting['id'] as String).set(meeting);
    }
    print('   ✓ Added ${meetings.length} demo meetings');
  }

  /// Seeds demo announcements
  static Future<void> seedAnnouncements() async {
    print('📢 Adding demo announcements...');

    final announcements = [
      {
        'id': 'announcement_1',
        'title': 'Company Holiday Notice',
        'titleAr': 'إشعار عطلة الشركة',
        'content': 'Please be informed that the office will be closed on December 25th and 26th for the holiday season.',
        'contentAr': 'يرجى العلم أن المكتب سيكون مغلقاً يومي 25 و 26 ديسمبر بمناسبة موسم الأعياد.',
        'authorId': 'demo_user_2',
        'authorName': 'Nouf AlGhanem',
        'department': 'Human Resources',
        'priority': 'high',
        'category': 'general',
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'isActive': true,
        'isPinned': true,
      },
      {
        'id': 'announcement_2',
        'title': 'New Employee Onboarding',
        'titleAr': 'تأهيل الموظفين الجدد',
        'content': 'We are pleased to welcome 5 new team members. Join us for a welcome reception Monday at 3 PM.',
        'contentAr': 'يسعدنا الترحيب بـ 5 أعضاء جدد. انضموا إلينا في حفل الترحيب يوم الاثنين الساعة 3 مساءً.',
        'authorId': 'demo_user_2',
        'authorName': 'Nouf AlGhanem',
        'department': 'Human Resources',
        'priority': 'medium',
        'category': 'hr',
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'isActive': true,
        'isPinned': false,
      },
      {
        'id': 'announcement_3',
        'title': 'System Maintenance Scheduled',
        'titleAr': 'صيانة النظام المجدولة',
        'content': 'System maintenance this Saturday from 10 PM to 2 AM. Some services may be unavailable.',
        'contentAr': 'صيانة النظام يوم السبت من 10 مساءً حتى 2 صباحاً. قد تكون بعض الخدمات غير متاحة.',
        'authorId': 'demo_user_5',
        'authorName': 'Jana AlZmami',
        'department': 'IT Support',
        'priority': 'high',
        'category': 'it',
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5))),
        'isActive': true,
        'isPinned': true,
      },
      {
        'id': 'announcement_4',
        'title': 'Q3 Performance Results',
        'titleAr': 'نتائج أداء الربع الثالث',
        'content': 'We exceeded our Q3 targets by 15%! Thank you all for your dedication.',
        'contentAr': 'تجاوزنا أهداف الربع الثالث بنسبة 15%! شكراً لتفانيكم.',
        'authorId': 'demo_user_3',
        'authorName': 'Dima Althenayan',
        'department': 'Finance',
        'priority': 'medium',
        'category': 'general',
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 14))),
        'isActive': true,
        'isPinned': false,
      },
      {
        'id': 'announcement_5',
        'title': 'New Marketing Campaign',
        'titleAr': 'حملة تسويقية جديدة',
        'content': 'Our new campaign "Innovation Forward" launches next week. Share on social media!',
        'contentAr': 'حملتنا الجديدة "الابتكار نحو الأمام" تنطلق الأسبوع المقبل. شاركوها!',
        'authorId': 'demo_user_4',
        'authorName': 'Leen Al Fawaz',
        'department': 'Marketing',
        'priority': 'medium',
        'category': 'marketing',
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 21))),
        'isActive': true,
        'isPinned': false,
      },
      {
        'id': 'announcement_6',
        'title': 'Health & Safety Training',
        'titleAr': 'تدريب الصحة والسلامة',
        'content': 'Mandatory training next Wednesday. All employees must attend.',
        'contentAr': 'تدريب إلزامي يوم الأربعاء القادم. يجب حضور جميع الموظفين.',
        'authorId': 'demo_user_2',
        'authorName': 'Nouf AlGhanem',
        'department': 'Human Resources',
        'priority': 'high',
        'category': 'hr',
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 10))),
        'isActive': true,
        'isPinned': true,
      },
    ];

    for (var announcement in announcements) {
      await _firestore.collection('announcements').doc(announcement['id'] as String).set(announcement);
    }
    print('   ✓ Added ${announcements.length} demo announcements');
  }

  /// Seeds demo documents
  static Future<void> seedDocuments() async {
    print('📄 Adding demo documents...');

    final documents = [
      {
        'id': 'doc_1',
        'title': 'Employee Handbook 2024',
        'description': 'Complete guide covering company policies, benefits, and procedures.',
        'fileUrl': 'https://example.com/docs/employee_handbook.pdf',
        'fileName': 'Employee_Handbook_2024.pdf',
        'fileType': 'pdf',
        'fileSize': 2500000.0,
        'uploadedById': 'demo_user_2',
        'uploadedByName': 'Nouf AlGhanem',
        'allowedRoles': <String>[],
        'allowedDepartments': <String>[],
        'category': 'DocumentCategory.policies',
        'createdAt': Timestamp.now(),
        'isActive': true,
      },
      {
        'id': 'doc_2',
        'title': 'IT Security Guidelines',
        'description': 'Security protocols and best practices.',
        'fileUrl': 'https://example.com/docs/it_security.pdf',
        'fileName': 'IT_Security_Guidelines.pdf',
        'fileType': 'pdf',
        'fileSize': 1800000.0,
        'uploadedById': 'demo_user_5',
        'uploadedByName': 'Jana AlZmami',
        'allowedRoles': <String>[],
        'allowedDepartments': <String>[],
        'category': 'DocumentCategory.procedures',
        'createdAt': Timestamp.now(),
        'isActive': true,
      },
      {
        'id': 'doc_3',
        'title': 'Annual Report 2023',
        'description': 'Company annual financial and operational report.',
        'fileUrl': 'https://example.com/docs/annual_report.pdf',
        'fileName': 'Annual_Report_2023.pdf',
        'fileType': 'pdf',
        'fileSize': 5200000.0,
        'uploadedById': 'demo_user_3',
        'uploadedByName': 'Dima Althenayan',
        'allowedRoles': ['manager', 'admin'],
        'allowedDepartments': <String>[],
        'category': 'DocumentCategory.reports',
        'createdAt': Timestamp.now(),
        'isActive': true,
      },
      {
        'id': 'doc_4',
        'title': 'Leave Request Form',
        'description': 'Standard form for requesting annual or sick leave.',
        'fileUrl': 'https://example.com/docs/leave_form.docx',
        'fileName': 'Leave_Request_Form.docx',
        'fileType': 'docx',
        'fileSize': 45000.0,
        'uploadedById': 'demo_user_2',
        'uploadedByName': 'Nouf AlGhanem',
        'allowedRoles': <String>[],
        'allowedDepartments': <String>[],
        'category': 'DocumentCategory.forms',
        'createdAt': Timestamp.now(),
        'isActive': true,
      },
      {
        'id': 'doc_5',
        'title': 'Brand Guidelines',
        'description': 'Official brand guidelines including logo usage.',
        'fileUrl': 'https://example.com/docs/brand_guidelines.pdf',
        'fileName': 'Brand_Guidelines.pdf',
        'fileType': 'pdf',
        'fileSize': 8500000.0,
        'uploadedById': 'demo_user_4',
        'uploadedByName': 'Leen Al Fawaz',
        'allowedRoles': <String>[],
        'allowedDepartments': ['Marketing'],
        'category': 'DocumentCategory.general',
        'createdAt': Timestamp.now(),
        'isActive': true,
      },
      {
        'id': 'doc_6',
        'title': 'Expense Reimbursement Policy',
        'description': 'Guidelines for submitting expense claims.',
        'fileUrl': 'https://example.com/docs/expense_policy.pdf',
        'fileName': 'Expense_Reimbursement_Policy.pdf',
        'fileType': 'pdf',
        'fileSize': 980000.0,
        'uploadedById': 'demo_user_3',
        'uploadedByName': 'Dima Althenayan',
        'allowedRoles': <String>[],
        'allowedDepartments': <String>[],
        'category': 'DocumentCategory.policies',
        'createdAt': Timestamp.now(),
        'isActive': true,
      },
      {
        'id': 'doc_7',
        'title': 'Project Proposal Template',
        'description': 'Standard template for project proposals.',
        'fileUrl': 'https://example.com/docs/project_template.docx',
        'fileName': 'Project_Proposal_Template.docx',
        'fileType': 'docx',
        'fileSize': 125000.0,
        'uploadedById': 'demo_user_1',
        'uploadedByName': 'Basmah Alhamidi',
        'allowedRoles': <String>[],
        'allowedDepartments': <String>[],
        'category': 'DocumentCategory.forms',
        'createdAt': Timestamp.now(),
        'isActive': true,
      },
    ];

    for (var doc in documents) {
      await _firestore.collection('documents').doc(doc['id'] as String).set(doc);
    }
    print('   ✓ Added ${documents.length} demo documents');
  }

  /// Seeds demo workflows
  static Future<void> seedWorkflows() async {
    print('🔄 Adding demo workflows...');

    final currentId = _currentUserId ?? 'demo_user_1';
    final currentName = _currentUserName ?? 'Current User';

    final workflows = [
      // Workflows for current user (My Workflows)
      {
        'id': 'workflow_current_1',
        'title': 'Annual Leave Request',
        'titleAr': 'طلب إجازة سنوية',
        'description': 'Request for 5 days annual leave from Dec 20-25.',
        'descriptionAr': 'طلب إجازة سنوية لمدة 5 أيام من 20-25 ديسمبر.',
        'type': 'WorkflowType.documentRequest',
        'status': 'WorkflowStatus.pending',
        'priority': 'medium',
        'initiatorId': currentId,
        'initiatorName': currentName,
        'assigneeId': 'demo_user_2',
        'assigneeName': 'Nouf AlGhanem',
        'department': 'General',
        'data': <String, dynamic>{},
        'createdAt': Timestamp.now(),
        'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
        'currentStepIndex': 0,
        'steps': [
          {'id': 'step_1', 'title': 'Manager Approval', 'description': 'Waiting for manager approval', 'assigneeId': 'demo_user_2', 'assigneeName': 'Nouf AlGhanem', 'status': 'WorkflowStatus.pending'}
        ],
      },
      {
        'id': 'workflow_current_2',
        'title': 'Equipment Purchase Request',
        'titleAr': 'طلب شراء معدات',
        'description': 'Request to purchase new laptop for development.',
        'descriptionAr': 'طلب شراء جهاز محمول جديد للتطوير.',
        'type': 'WorkflowType.documentRequest',
        'status': 'WorkflowStatus.inProgress',
        'priority': 'high',
        'initiatorId': currentId,
        'initiatorName': currentName,
        'assigneeId': 'demo_user_3',
        'assigneeName': 'Dima Althenayan',
        'department': 'IT',
        'data': <String, dynamic>{},
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
        'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5))),
        'currentStepIndex': 1,
        'steps': [
          {'id': 'step_1', 'title': 'IT Approval', 'description': 'IT Manager review', 'status': 'WorkflowStatus.completed'},
          {'id': 'step_2', 'title': 'Finance Approval', 'description': 'Finance review', 'assigneeId': 'demo_user_3', 'assigneeName': 'Dima Althenayan', 'status': 'WorkflowStatus.pending'}
        ],
      },
      {
        'id': 'workflow_current_3',
        'title': 'Travel Expense Claim',
        'titleAr': 'مطالبة مصاريف السفر',
        'description': 'Reimbursement for conference travel expenses.',
        'descriptionAr': 'طلب تعويض مصاريف السفر للمؤتمر.',
        'type': 'WorkflowType.documentRequest',
        'status': 'WorkflowStatus.completed',
        'priority': 'low',
        'initiatorId': currentId,
        'initiatorName': currentName,
        'assigneeId': 'demo_user_3',
        'assigneeName': 'Dima Althenayan',
        'department': 'Finance',
        'data': <String, dynamic>{},
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
        'completedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
        'currentStepIndex': 2,
        'steps': [
          {'id': 'step_1', 'title': 'Manager Approval', 'description': 'Manager review', 'status': 'WorkflowStatus.completed'},
          {'id': 'step_2', 'title': 'Finance Review', 'description': 'Finance processing', 'status': 'WorkflowStatus.completed'}
        ],
      },
      {
        'id': 'workflow_current_4',
        'title': 'New Project Approval',
        'titleAr': 'موافقة مشروع جديد',
        'description': 'Approval for new mobile app project.',
        'descriptionAr': 'طلب موافقة لمشروع تطبيق جوال جديد.',
        'type': 'WorkflowType.documentRequest',
        'status': 'WorkflowStatus.approved',
        'priority': 'high',
        'initiatorId': currentId,
        'initiatorName': currentName,
        'assigneeId': 'demo_user_2',
        'assigneeName': 'Nouf AlGhanem',
        'department': 'Engineering',
        'data': <String, dynamic>{},
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
        'completedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'currentStepIndex': 1,
        'steps': [
          {'id': 'step_1', 'title': 'HR Review', 'description': 'HR department review', 'status': 'WorkflowStatus.completed'}
        ],
      },
      {
        'id': 'workflow_current_5',
        'title': 'Sick Leave Request',
        'titleAr': 'طلب إجازة مرضية',
        'description': 'Sick leave for 2 days.',
        'descriptionAr': 'طلب إجازة مرضية لمدة يومين.',
        'type': 'WorkflowType.documentRequest',
        'status': 'WorkflowStatus.rejected',
        'priority': 'medium',
        'initiatorId': currentId,
        'initiatorName': currentName,
        'assigneeId': 'demo_user_2',
        'assigneeName': 'Nouf AlGhanem',
        'department': 'HR',
        'data': <String, dynamic>{},
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
        'completedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 8))),
        'currentStepIndex': 1,
        'steps': [
          {'id': 'step_1', 'title': 'HR Approval', 'description': 'HR review', 'status': 'WorkflowStatus.rejected', 'notes': 'Please provide medical certificate'}
        ],
      },
      // Workflows assigned to current user (Assigned tab)
      {
        'id': 'workflow_assigned_1',
        'title': 'Document Access Request',
        'titleAr': 'طلب الوصول للمستند',
        'description': 'Request access to confidential financial reports.',
        'descriptionAr': 'طلب الوصول للتقارير المالية السرية.',
        'type': 'WorkflowType.documentRequest',
        'status': 'WorkflowStatus.pending',
        'priority': 'high',
        'initiatorId': 'demo_user_4',
        'initiatorName': 'Leen Al Fawaz',
        'assigneeId': currentId,
        'assigneeName': currentName,
        'department': 'Marketing',
        'data': <String, dynamic>{},
        'createdAt': Timestamp.now(),
        'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 2))),
        'currentStepIndex': 0,
        'steps': [
          {'id': 'step_1', 'title': 'Review Request', 'description': 'Review document access request', 'assigneeId': currentId, 'assigneeName': currentName, 'status': 'WorkflowStatus.pending'}
        ],
      },
      {
        'id': 'workflow_assigned_2',
        'title': 'Meeting Room Booking',
        'titleAr': 'حجز غرفة اجتماعات',
        'description': 'Request for conference room booking.',
        'descriptionAr': 'طلب حجز قاعة المؤتمرات.',
        'type': 'WorkflowType.meetingRequest',
        'status': 'WorkflowStatus.pending',
        'priority': 'medium',
        'initiatorId': 'demo_user_5',
        'initiatorName': 'Jana AlZmami',
        'assigneeId': currentId,
        'assigneeName': currentName,
        'department': 'IT Support',
        'data': <String, dynamic>{},
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 3))),
        'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        'currentStepIndex': 0,
        'steps': [
          {'id': 'step_1', 'title': 'Approve Booking', 'description': 'Approve meeting room reservation', 'assigneeId': currentId, 'assigneeName': currentName, 'status': 'WorkflowStatus.pending'}
        ],
      },
    ];

    for (var workflow in workflows) {
      await _firestore.collection('workflows').doc(workflow['id'] as String).set(workflow);
    }
    print('   ✓ Added ${workflows.length} demo workflows');
  }

  /// Seeds demo chats
  static Future<void> seedChats() async {
    print('💬 Adding demo chats...');

    final currentId = _currentUserId ?? 'demo_user_1';
    final currentName = _currentUserName ?? 'Current User';

    final chats = [
      {
        'id': 'chat_current_1',
        'type': 'direct',
        'participants': [currentId, 'demo_user_2'],
        'participantNames': {currentId: currentName, 'demo_user_2': 'Nouf AlGhanem'},
        'lastMessage': 'Thank you for approving my leave request!',
        'lastMessageAt': Timestamp.now(),
        'lastMessageBy': currentId,
        'createdAt': Timestamp.now(),
        'isActive': true,
      },
      {
        'id': 'chat_current_2',
        'type': 'direct',
        'participants': [currentId, 'demo_user_5'],
        'participantNames': {currentId: currentName, 'demo_user_5': 'Jana AlZmami'},
        'lastMessage': 'The new server is ready for deployment.',
        'lastMessageAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
        'lastMessageBy': 'demo_user_5',
        'createdAt': Timestamp.now(),
        'isActive': true,
      },
      {
        'id': 'chat_current_3',
        'type': 'direct',
        'participants': [currentId, 'demo_user_3'],
        'participantNames': {currentId: currentName, 'demo_user_3': 'Dima Althenayan'},
        'lastMessage': 'I reviewed your expense claim. It looks good!',
        'lastMessageAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'lastMessageBy': 'demo_user_3',
        'createdAt': Timestamp.now(),
        'isActive': true,
      },
      {
        'id': 'chat_current_4',
        'type': 'group',
        'name': 'Project Team',
        'nameAr': 'فريق المشروع',
        'participants': [currentId, 'demo_user_1', 'demo_user_5'],
        'participantNames': {currentId: currentName, 'demo_user_1': 'Basmah Alhamidi', 'demo_user_5': 'Jana AlZmami'},
        'lastMessage': 'Sprint planning tomorrow at 10 AM.',
        'lastMessageAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 3))),
        'lastMessageBy': 'demo_user_1',
        'createdAt': Timestamp.now(),
        'isActive': true,
      },
      {
        'id': 'chat_current_5',
        'type': 'group',
        'name': 'All Staff',
        'nameAr': 'جميع الموظفين',
        'participants': [currentId, 'demo_user_2', 'demo_user_3', 'demo_user_4', 'demo_user_5'],
        'participantNames': {
          currentId: currentName,
          'demo_user_2': 'Nouf AlGhanem',
          'demo_user_3': 'Dima Althenayan',
          'demo_user_4': 'Leen Al Fawaz',
          'demo_user_5': 'Jana AlZmami'
        },
        'lastMessage': 'Remember: System maintenance this Saturday.',
        'lastMessageAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 12))),
        'lastMessageBy': 'demo_user_5',
        'createdAt': Timestamp.now(),
        'isActive': true,
      },
    ];

    for (var chat in chats) {
      await _firestore.collection('chats').doc(chat['id'] as String).set(chat);
    }
    print('   ✓ Added ${chats.length} demo chats');
  }

  /// Seeds demo notifications
  static Future<void> seedNotifications() async {
    print('🔔 Adding demo notifications...');

    final currentId = _currentUserId ?? 'demo_user_1';

    final notifications = [
      // Notifications for current user
      {
        'id': 'notif_current_1',
        'userId': currentId,
        'title': 'Leave Request Approved',
        'body': 'Your annual leave request for Dec 20-25 has been approved by Nouf AlGhanem.',
        'type': 'workflow',
        'priority': 'normal',
        'data': {'workflowId': 'workflow_current_1'},
        'isRead': false,
        'createdAt': Timestamp.now(),
      },
      {
        'id': 'notif_current_2',
        'userId': currentId,
        'title': 'New Meeting Scheduled',
        'body': 'Q4 Planning Meeting scheduled for tomorrow at 10:00 AM in Conference Room A.',
        'type': 'meeting',
        'priority': 'normal',
        'data': {'meetingId': 'meeting_1'},
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
      },
      {
        'id': 'notif_current_3',
        'userId': currentId,
        'title': 'Company Holiday Notice',
        'body': 'Office will be closed on December 25th and 26th for the holiday season.',
        'type': 'announcement',
        'priority': 'high',
        'data': {'announcementId': 'announcement_1'},
        'isRead': true,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      },
      {
        'id': 'notif_current_4',
        'userId': currentId,
        'title': 'New Message from Jana AlZmami',
        'body': 'The new server is ready for deployment. Please review.',
        'type': 'message',
        'priority': 'normal',
        'data': {'chatId': 'chat_2'},
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
      },
      {
        'id': 'notif_current_5',
        'userId': currentId,
        'title': 'Workflow Assigned to You',
        'body': 'Leen Al Fawaz submitted a document access request that requires your approval.',
        'type': 'workflow',
        'priority': 'high',
        'data': {'workflowId': 'workflow_assigned_1'},
        'isRead': false,
        'createdAt': Timestamp.now(),
      },
      {
        'id': 'notif_current_6',
        'userId': currentId,
        'title': 'Equipment Purchase In Progress',
        'body': 'Your equipment purchase request is now being reviewed by Finance.',
        'type': 'workflow',
        'priority': 'normal',
        'data': {'workflowId': 'workflow_current_2'},
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5))),
      },
      {
        'id': 'notif_current_7',
        'userId': currentId,
        'title': 'System Maintenance Scheduled',
        'body': 'System maintenance this Saturday from 10 PM to 2 AM.',
        'type': 'announcement',
        'priority': 'high',
        'data': {'announcementId': 'announcement_3'},
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 12))),
      },
      {
        'id': 'notif_current_8',
        'userId': currentId,
        'title': 'New Document Available',
        'body': 'Employee Handbook 2024 has been uploaded and is now available.',
        'type': 'document',
        'priority': 'normal',
        'data': {'documentId': 'doc_1'},
        'isRead': true,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      },
      {
        'id': 'notif_current_9',
        'userId': currentId,
        'title': 'Meeting Reminder',
        'body': 'Weekly Team Standup starts in 15 minutes.',
        'type': 'meeting',
        'priority': 'high',
        'data': {'meetingId': 'meeting_3'},
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 30))),
      },
      {
        'id': 'notif_current_10',
        'userId': currentId,
        'title': 'Expense Claim Processed',
        'body': 'Your travel expense claim has been approved and payment is being processed.',
        'type': 'workflow',
        'priority': 'normal',
        'data': {'workflowId': 'workflow_current_3'},
        'isRead': true,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
      },
    ];

    for (var notification in notifications) {
      await _firestore.collection('notifications').doc(notification['id'] as String).set(notification);
    }
    print('   ✓ Added ${notifications.length} demo notifications');
  }
}
