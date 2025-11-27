// Demo Data Script for GCC Connect App
// Run with: dart run add_demo_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  print('🚀 Starting to add demo data...\n');

  try {
    // 1. Add Demo Users
    await addDemoUsers(firestore);

    // 2. Add Demo Meetings
    await addDemoMeetings(firestore);

    // 3. Add Demo Announcements
    await addDemoAnnouncements(firestore);

    // 4. Add Demo Documents
    await addDemoDocuments(firestore);

    // 5. Add Demo Workflows
    await addDemoWorkflows(firestore);

    // 6. Add Demo Messages/Chats
    await addDemoChats(firestore);

    // 7. Add Demo Notifications
    await addDemoNotifications(firestore);

    print('\n✅ All demo data added successfully!');
    print('📱 You can now demo all functionalities in the app.');

  } catch (e) {
    print('❌ Error adding demo data: $e');
  }
}

Future<void> addDemoUsers(FirebaseFirestore firestore) async {
  print('👥 Adding demo users...');

  final users = [
    {
      'id': 'demo_user_1',
      'email': 'ahmed.hassan@gcc.com',
      'firstName': 'Ahmed',
      'lastName': 'Hassan',
      'phoneNumber': '+966 50 123 4567',
      'department': 'Engineering',
      'position': 'Senior Developer',
      'roles': ['employee'],
      'isActive': true,
      'createdAt': Timestamp.now(),
      'lastLogin': Timestamp.now(),
    },
    {
      'id': 'demo_user_2',
      'email': 'fatima.ali@gcc.com',
      'firstName': 'Fatima',
      'lastName': 'Ali',
      'phoneNumber': '+966 55 234 5678',
      'department': 'Human Resources',
      'position': 'HR Manager',
      'roles': ['employee', 'manager'],
      'isActive': true,
      'createdAt': Timestamp.now(),
      'lastLogin': Timestamp.now(),
    },
    {
      'id': 'demo_user_3',
      'email': 'mohammed.salem@gcc.com',
      'firstName': 'Mohammed',
      'lastName': 'Salem',
      'phoneNumber': '+966 54 345 6789',
      'department': 'Finance',
      'position': 'Financial Analyst',
      'roles': ['employee'],
      'isActive': true,
      'createdAt': Timestamp.now(),
      'lastLogin': Timestamp.now(),
    },
    {
      'id': 'demo_user_4',
      'email': 'sara.khan@gcc.com',
      'firstName': 'Sara',
      'lastName': 'Khan',
      'phoneNumber': '+966 56 456 7890',
      'department': 'Marketing',
      'position': 'Marketing Director',
      'roles': ['employee', 'manager'],
      'isActive': true,
      'createdAt': Timestamp.now(),
      'lastLogin': Timestamp.now(),
    },
    {
      'id': 'demo_user_5',
      'email': 'omar.rashid@gcc.com',
      'firstName': 'Omar',
      'lastName': 'Rashid',
      'phoneNumber': '+966 59 567 8901',
      'department': 'IT Support',
      'position': 'IT Manager',
      'roles': ['employee', 'admin'],
      'isActive': true,
      'createdAt': Timestamp.now(),
      'lastLogin': Timestamp.now(),
    },
  ];

  for (var user in users) {
    await firestore.collection('users').doc(user['id'] as String).set(user);
  }
  print('   ✓ Added ${users.length} demo users');
}

Future<void> addDemoMeetings(FirebaseFirestore firestore) async {
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
      'organizerName': 'Fatima Ali',
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
      'organizerName': 'Sara Khan',
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
      'organizerName': 'Ahmed Hassan',
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
      'organizerName': 'Mohammed Salem',
      'attendees': ['demo_user_2', 'demo_user_4', 'demo_user_5'],
      'status': 'scheduled',
      'createdAt': Timestamp.now(),
      'isActive': true,
    },
    {
      'id': 'meeting_5',
      'title': 'IT Infrastructure Update',
      'titleAr': 'تحديث البنية التحتية لتقنية المعلومات',
      'description': 'Discussion on upcoming IT infrastructure improvements and security updates.',
      'descriptionAr': 'مناقشة تحسينات البنية التحتية لتقنية المعلومات والتحديثات الأمنية القادمة.',
      'date': Timestamp.fromDate(now.add(const Duration(days: 5))),
      'startTime': '3:00 PM',
      'endTime': '4:00 PM',
      'location': 'IT Department',
      'locationAr': 'قسم تقنية المعلومات',
      'organizerId': 'demo_user_5',
      'organizerName': 'Omar Rashid',
      'attendees': ['demo_user_1', 'demo_user_2', 'demo_user_3', 'demo_user_4'],
      'status': 'scheduled',
      'createdAt': Timestamp.now(),
      'isActive': true,
    },
  ];

  for (var meeting in meetings) {
    await firestore.collection('meetings').doc(meeting['id'] as String).set(meeting);
  }
  print('   ✓ Added ${meetings.length} demo meetings');
}

Future<void> addDemoAnnouncements(FirebaseFirestore firestore) async {
  print('📢 Adding demo announcements...');

  final announcements = [
    {
      'id': 'announcement_1',
      'title': 'Company Holiday Notice',
      'titleAr': 'إشعار عطلة الشركة',
      'content': 'Please be informed that the office will be closed on December 25th and 26th for the holiday season. All employees are requested to complete pending tasks before the break.',
      'contentAr': 'يرجى العلم أن المكتب سيكون مغلقاً يومي 25 و 26 ديسمبر بمناسبة موسم الأعياد. يرجى من جميع الموظفين إكمال المهام المعلقة قبل الإجازة.',
      'authorId': 'demo_user_2',
      'authorName': 'Fatima Ali',
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
      'content': 'We are pleased to welcome 5 new team members joining us this month. Please join us for a welcome reception in the main hall on Monday at 3 PM.',
      'contentAr': 'يسعدنا الترحيب بـ 5 أعضاء جدد ينضمون إلينا هذا الشهر. يرجى الانضمام إلينا في حفل الترحيب في القاعة الرئيسية يوم الاثنين الساعة 3 مساءً.',
      'authorId': 'demo_user_2',
      'authorName': 'Fatima Ali',
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
      'content': 'The IT department will perform system maintenance this Saturday from 10 PM to 2 AM. Some services may be temporarily unavailable during this time.',
      'contentAr': 'سيقوم قسم تقنية المعلومات بإجراء صيانة للنظام يوم السبت من الساعة 10 مساءً حتى 2 صباحاً. قد تكون بعض الخدمات غير متاحة مؤقتاً خلال هذه الفترة.',
      'authorId': 'demo_user_5',
      'authorName': 'Omar Rashid',
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
      'content': 'We are excited to announce that we have exceeded our Q3 targets by 15%! Thank you to all team members for your dedication and hard work.',
      'contentAr': 'يسعدنا أن نعلن أننا تجاوزنا أهداف الربع الثالث بنسبة 15%! شكراً لجميع أعضاء الفريق على تفانيكم وعملكم الجاد.',
      'authorId': 'demo_user_3',
      'authorName': 'Mohammed Salem',
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
      'title': 'New Marketing Campaign Launch',
      'titleAr': 'إطلاق حملة تسويقية جديدة',
      'content': 'Our new digital marketing campaign "Innovation Forward" will launch next week. All departments are encouraged to share the campaign materials on their social media.',
      'contentAr': 'ستنطلق حملتنا التسويقية الرقمية الجديدة "الابتكار نحو الأمام" الأسبوع المقبل. نشجع جميع الأقسام على مشاركة مواد الحملة على وسائل التواصل الاجتماعي.',
      'authorId': 'demo_user_4',
      'authorName': 'Sara Khan',
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
      'content': 'Mandatory health and safety training will be conducted next Wednesday. All employees must attend. Please register through the HR portal.',
      'contentAr': 'سيتم إجراء تدريب إلزامي للصحة والسلامة يوم الأربعاء القادم. يجب على جميع الموظفين الحضور. يرجى التسجيل من خلال بوابة الموارد البشرية.',
      'authorId': 'demo_user_2',
      'authorName': 'Fatima Ali',
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
    await firestore.collection('announcements').doc(announcement['id'] as String).set(announcement);
  }
  print('   ✓ Added ${announcements.length} demo announcements');
}

Future<void> addDemoDocuments(FirebaseFirestore firestore) async {
  print('📄 Adding demo documents...');

  final documents = [
    {
      'id': 'doc_1',
      'title': 'Employee Handbook 2024',
      'description': 'Complete guide for all employees covering company policies, benefits, and procedures.',
      'fileUrl': 'https://example.com/docs/employee_handbook.pdf',
      'fileName': 'Employee_Handbook_2024.pdf',
      'fileType': 'pdf',
      'fileSize': 2500000.0,
      'uploadedById': 'demo_user_2',
      'uploadedByName': 'Fatima Ali',
      'allowedRoles': [],
      'allowedDepartments': [],
      'category': 'DocumentCategory.policies',
      'createdAt': Timestamp.now(),
      'isActive': true,
    },
    {
      'id': 'doc_2',
      'title': 'IT Security Guidelines',
      'description': 'Security protocols and best practices for all employees.',
      'fileUrl': 'https://example.com/docs/it_security.pdf',
      'fileName': 'IT_Security_Guidelines.pdf',
      'fileType': 'pdf',
      'fileSize': 1800000.0,
      'uploadedById': 'demo_user_5',
      'uploadedByName': 'Omar Rashid',
      'allowedRoles': [],
      'allowedDepartments': [],
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
      'uploadedByName': 'Mohammed Salem',
      'allowedRoles': ['manager', 'admin'],
      'allowedDepartments': [],
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
      'uploadedByName': 'Fatima Ali',
      'allowedRoles': [],
      'allowedDepartments': [],
      'category': 'DocumentCategory.forms',
      'createdAt': Timestamp.now(),
      'isActive': true,
    },
    {
      'id': 'doc_5',
      'title': 'Brand Guidelines',
      'description': 'Official brand guidelines including logo usage, colors, and typography.',
      'fileUrl': 'https://example.com/docs/brand_guidelines.pdf',
      'fileName': 'Brand_Guidelines.pdf',
      'fileType': 'pdf',
      'fileSize': 8500000.0,
      'uploadedById': 'demo_user_4',
      'uploadedByName': 'Sara Khan',
      'allowedRoles': [],
      'allowedDepartments': ['Marketing'],
      'category': 'DocumentCategory.general',
      'createdAt': Timestamp.now(),
      'isActive': true,
    },
    {
      'id': 'doc_6',
      'title': 'Expense Reimbursement Policy',
      'description': 'Guidelines for submitting expense claims and reimbursements.',
      'fileUrl': 'https://example.com/docs/expense_policy.pdf',
      'fileName': 'Expense_Reimbursement_Policy.pdf',
      'fileType': 'pdf',
      'fileSize': 980000.0,
      'uploadedById': 'demo_user_3',
      'uploadedByName': 'Mohammed Salem',
      'allowedRoles': [],
      'allowedDepartments': [],
      'category': 'DocumentCategory.policies',
      'createdAt': Timestamp.now(),
      'isActive': true,
    },
    {
      'id': 'doc_7',
      'title': 'Project Proposal Template',
      'description': 'Standard template for submitting new project proposals.',
      'fileUrl': 'https://example.com/docs/project_template.docx',
      'fileName': 'Project_Proposal_Template.docx',
      'fileType': 'docx',
      'fileSize': 125000.0,
      'uploadedById': 'demo_user_1',
      'uploadedByName': 'Ahmed Hassan',
      'allowedRoles': [],
      'allowedDepartments': [],
      'category': 'DocumentCategory.forms',
      'createdAt': Timestamp.now(),
      'isActive': true,
    },
  ];

  for (var doc in documents) {
    await firestore.collection('documents').doc(doc['id'] as String).set(doc);
  }
  print('   ✓ Added ${documents.length} demo documents');
}

Future<void> addDemoWorkflows(FirebaseFirestore firestore) async {
  print('🔄 Adding demo workflows...');

  final workflows = [
    {
      'id': 'workflow_1',
      'title': 'Annual Leave Request',
      'titleAr': 'طلب إجازة سنوية',
      'description': 'Request for 5 days annual leave from Dec 20-25 for family vacation.',
      'descriptionAr': 'طلب إجازة سنوية لمدة 5 أيام من 20-25 ديسمبر لقضاء إجازة عائلية.',
      'type': 'WorkflowType.leaveRequest',
      'status': 'WorkflowStatus.pending',
      'priority': 'WorkflowPriority.medium',
      'initiatorId': 'demo_user_1',
      'initiatorName': 'Ahmed Hassan',
      'assigneeId': 'demo_user_2',
      'assigneeName': 'Fatima Ali',
      'department': 'Engineering',
      'createdAt': Timestamp.now(),
      'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
      'currentStepIndex': 0,
      'steps': [
        {
          'id': 'step_1',
          'title': 'Manager Approval',
          'titleAr': 'موافقة المدير',
          'assigneeId': 'demo_user_2',
          'assigneeName': 'Fatima Ali',
          'status': 'WorkflowStatus.pending',
          'order': 0,
        },
      ],
      'attachments': [],
      'comments': [],
    },
    {
      'id': 'workflow_2',
      'title': 'Equipment Purchase Request',
      'titleAr': 'طلب شراء معدات',
      'description': 'Request to purchase new laptops for the development team (5 units).',
      'descriptionAr': 'طلب شراء أجهزة كمبيوتر محمولة جديدة لفريق التطوير (5 وحدات).',
      'type': 'WorkflowType.purchaseRequest',
      'status': 'WorkflowStatus.inProgress',
      'priority': 'WorkflowPriority.high',
      'initiatorId': 'demo_user_5',
      'initiatorName': 'Omar Rashid',
      'assigneeId': 'demo_user_3',
      'assigneeName': 'Mohammed Salem',
      'department': 'IT Support',
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 5))),
      'currentStepIndex': 1,
      'steps': [
        {
          'id': 'step_1',
          'title': 'IT Manager Approval',
          'titleAr': 'موافقة مدير تقنية المعلومات',
          'assigneeId': 'demo_user_5',
          'assigneeName': 'Omar Rashid',
          'status': 'WorkflowStatus.completed',
          'completedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
          'order': 0,
        },
        {
          'id': 'step_2',
          'title': 'Finance Approval',
          'titleAr': 'موافقة المالية',
          'assigneeId': 'demo_user_3',
          'assigneeName': 'Mohammed Salem',
          'status': 'WorkflowStatus.pending',
          'order': 1,
        },
      ],
      'attachments': [],
      'comments': [
        {
          'id': 'comment_1',
          'userId': 'demo_user_5',
          'userName': 'Omar Rashid',
          'content': 'Approved from IT side. Budget allocation confirmed.',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        },
      ],
    },
    {
      'id': 'workflow_3',
      'title': 'Travel Expense Claim',
      'titleAr': 'مطالبة مصاريف السفر',
      'description': 'Reimbursement request for business trip to Dubai (Nov 15-18).',
      'descriptionAr': 'طلب تعويض لرحلة العمل إلى دبي (15-18 نوفمبر).',
      'type': 'WorkflowType.expenseClaim',
      'status': 'WorkflowStatus.completed',
      'priority': 'WorkflowPriority.low',
      'initiatorId': 'demo_user_4',
      'initiatorName': 'Sara Khan',
      'assigneeId': 'demo_user_3',
      'assigneeName': 'Mohammed Salem',
      'department': 'Marketing',
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
      'dueDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      'completedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
      'currentStepIndex': 2,
      'steps': [
        {
          'id': 'step_1',
          'title': 'Department Manager Approval',
          'titleAr': 'موافقة مدير القسم',
          'assigneeId': 'demo_user_4',
          'assigneeName': 'Sara Khan',
          'status': 'WorkflowStatus.completed',
          'completedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
          'order': 0,
        },
        {
          'id': 'step_2',
          'title': 'Finance Review',
          'titleAr': 'مراجعة المالية',
          'assigneeId': 'demo_user_3',
          'assigneeName': 'Mohammed Salem',
          'status': 'WorkflowStatus.completed',
          'completedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
          'order': 1,
        },
      ],
      'attachments': [],
      'comments': [
        {
          'id': 'comment_1',
          'userId': 'demo_user_3',
          'userName': 'Mohammed Salem',
          'content': 'All receipts verified. Payment processed.',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
        },
      ],
    },
    {
      'id': 'workflow_4',
      'title': 'New Project Approval',
      'titleAr': 'موافقة مشروع جديد',
      'description': 'Approval request for new mobile app development project.',
      'descriptionAr': 'طلب موافقة لمشروع تطوير تطبيق جوال جديد.',
      'type': 'WorkflowType.approval',
      'status': 'WorkflowStatus.pending',
      'priority': 'WorkflowPriority.high',
      'initiatorId': 'demo_user_1',
      'initiatorName': 'Ahmed Hassan',
      'assigneeId': 'demo_user_2',
      'assigneeName': 'Fatima Ali',
      'department': 'Engineering',
      'createdAt': Timestamp.now(),
      'dueDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
      'currentStepIndex': 0,
      'steps': [
        {
          'id': 'step_1',
          'title': 'HR Review',
          'titleAr': 'مراجعة الموارد البشرية',
          'assigneeId': 'demo_user_2',
          'assigneeName': 'Fatima Ali',
          'status': 'WorkflowStatus.pending',
          'order': 0,
        },
        {
          'id': 'step_2',
          'title': 'Budget Approval',
          'titleAr': 'موافقة الميزانية',
          'assigneeId': 'demo_user_3',
          'assigneeName': 'Mohammed Salem',
          'status': 'WorkflowStatus.pending',
          'order': 1,
        },
      ],
      'attachments': [],
      'comments': [],
    },
    {
      'id': 'workflow_5',
      'title': 'Sick Leave Request',
      'titleAr': 'طلب إجازة مرضية',
      'description': 'Sick leave request for 2 days due to medical appointment.',
      'descriptionAr': 'طلب إجازة مرضية لمدة يومين بسبب موعد طبي.',
      'type': 'WorkflowType.leaveRequest',
      'status': 'WorkflowStatus.approved',
      'priority': 'WorkflowPriority.medium',
      'initiatorId': 'demo_user_3',
      'initiatorName': 'Mohammed Salem',
      'assigneeId': 'demo_user_2',
      'assigneeName': 'Fatima Ali',
      'department': 'Finance',
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
      'dueDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      'completedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
      'currentStepIndex': 1,
      'steps': [
        {
          'id': 'step_1',
          'title': 'HR Approval',
          'titleAr': 'موافقة الموارد البشرية',
          'assigneeId': 'demo_user_2',
          'assigneeName': 'Fatima Ali',
          'status': 'WorkflowStatus.completed',
          'completedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
          'order': 0,
        },
      ],
      'attachments': [],
      'comments': [
        {
          'id': 'comment_1',
          'userId': 'demo_user_2',
          'userName': 'Fatima Ali',
          'content': 'Approved. Get well soon!',
          'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
        },
      ],
    },
  ];

  for (var workflow in workflows) {
    await firestore.collection('workflows').doc(workflow['id'] as String).set(workflow);
  }
  print('   ✓ Added ${workflows.length} demo workflows');
}

Future<void> addDemoChats(FirebaseFirestore firestore) async {
  print('💬 Adding demo chats and messages...');

  // Create chat rooms
  final chats = [
    {
      'id': 'chat_1',
      'type': 'direct',
      'participants': ['demo_user_1', 'demo_user_2'],
      'participantNames': {'demo_user_1': 'Ahmed Hassan', 'demo_user_2': 'Fatima Ali'},
      'lastMessage': 'Thank you for approving my leave request!',
      'lastMessageAt': Timestamp.now(),
      'lastMessageBy': 'demo_user_1',
      'createdAt': Timestamp.now(),
      'isActive': true,
    },
    {
      'id': 'chat_2',
      'type': 'direct',
      'participants': ['demo_user_1', 'demo_user_5'],
      'participantNames': {'demo_user_1': 'Ahmed Hassan', 'demo_user_5': 'Omar Rashid'},
      'lastMessage': 'The new server is ready for deployment.',
      'lastMessageAt': Timestamp.now(),
      'lastMessageBy': 'demo_user_5',
      'createdAt': Timestamp.now(),
      'isActive': true,
    },
    {
      'id': 'chat_3',
      'type': 'group',
      'name': 'Engineering Team',
      'nameAr': 'فريق الهندسة',
      'participants': ['demo_user_1', 'demo_user_5'],
      'participantNames': {'demo_user_1': 'Ahmed Hassan', 'demo_user_5': 'Omar Rashid'},
      'lastMessage': 'Sprint planning meeting tomorrow at 10 AM.',
      'lastMessageAt': Timestamp.now(),
      'lastMessageBy': 'demo_user_1',
      'createdAt': Timestamp.now(),
      'isActive': true,
    },
    {
      'id': 'chat_4',
      'type': 'group',
      'name': 'Management Team',
      'nameAr': 'فريق الإدارة',
      'participants': ['demo_user_2', 'demo_user_3', 'demo_user_4', 'demo_user_5'],
      'participantNames': {
        'demo_user_2': 'Fatima Ali',
        'demo_user_3': 'Mohammed Salem',
        'demo_user_4': 'Sara Khan',
        'demo_user_5': 'Omar Rashid'
      },
      'lastMessage': 'Q4 targets have been finalized.',
      'lastMessageAt': Timestamp.now(),
      'lastMessageBy': 'demo_user_3',
      'createdAt': Timestamp.now(),
      'isActive': true,
    },
  ];

  for (var chat in chats) {
    await firestore.collection('chats').doc(chat['id'] as String).set(chat);
  }

  // Add messages to chats
  final messages = [
    // Chat 1 messages
    {
      'id': 'msg_1_1',
      'chatId': 'chat_1',
      'senderId': 'demo_user_2',
      'senderName': 'Fatima Ali',
      'content': 'Hi Ahmed, I have reviewed your leave request.',
      'type': 'text',
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
      'isRead': true,
    },
    {
      'id': 'msg_1_2',
      'chatId': 'chat_1',
      'senderId': 'demo_user_2',
      'senderName': 'Fatima Ali',
      'content': 'Your annual leave from Dec 20-25 has been approved.',
      'type': 'text',
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1, minutes: 55))),
      'isRead': true,
    },
    {
      'id': 'msg_1_3',
      'chatId': 'chat_1',
      'senderId': 'demo_user_1',
      'senderName': 'Ahmed Hassan',
      'content': 'Thank you for approving my leave request!',
      'type': 'text',
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
      'isRead': true,
    },
    // Chat 2 messages
    {
      'id': 'msg_2_1',
      'chatId': 'chat_2',
      'senderId': 'demo_user_1',
      'senderName': 'Ahmed Hassan',
      'content': 'Omar, when will the new server be ready?',
      'type': 'text',
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 3))),
      'isRead': true,
    },
    {
      'id': 'msg_2_2',
      'chatId': 'chat_2',
      'senderId': 'demo_user_5',
      'senderName': 'Omar Rashid',
      'content': 'I am finishing the configuration now.',
      'type': 'text',
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
      'isRead': true,
    },
    {
      'id': 'msg_2_3',
      'chatId': 'chat_2',
      'senderId': 'demo_user_5',
      'senderName': 'Omar Rashid',
      'content': 'The new server is ready for deployment.',
      'type': 'text',
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 30))),
      'isRead': false,
    },
    // Chat 3 messages (Engineering Team)
    {
      'id': 'msg_3_1',
      'chatId': 'chat_3',
      'senderId': 'demo_user_1',
      'senderName': 'Ahmed Hassan',
      'content': 'Team, we need to discuss the new feature requirements.',
      'type': 'text',
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      'isRead': true,
    },
    {
      'id': 'msg_3_2',
      'chatId': 'chat_3',
      'senderId': 'demo_user_5',
      'senderName': 'Omar Rashid',
      'content': 'I have prepared the technical documentation.',
      'type': 'text',
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5))),
      'isRead': true,
    },
    {
      'id': 'msg_3_3',
      'chatId': 'chat_3',
      'senderId': 'demo_user_1',
      'senderName': 'Ahmed Hassan',
      'content': 'Sprint planning meeting tomorrow at 10 AM.',
      'type': 'text',
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
      'isRead': true,
    },
    // Chat 4 messages (Management Team)
    {
      'id': 'msg_4_1',
      'chatId': 'chat_4',
      'senderId': 'demo_user_2',
      'senderName': 'Fatima Ali',
      'content': 'Good morning everyone. Please review the Q4 planning document.',
      'type': 'text',
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      'isRead': true,
    },
    {
      'id': 'msg_4_2',
      'chatId': 'chat_4',
      'senderId': 'demo_user_4',
      'senderName': 'Sara Khan',
      'content': 'Marketing budget looks good. We can proceed with the campaign.',
      'type': 'text',
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 4))),
      'isRead': true,
    },
    {
      'id': 'msg_4_3',
      'chatId': 'chat_4',
      'senderId': 'demo_user_3',
      'senderName': 'Mohammed Salem',
      'content': 'Q4 targets have been finalized.',
      'type': 'text',
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
      'isRead': true,
    },
  ];

  for (var message in messages) {
    await firestore
        .collection('chats')
        .doc(message['chatId'] as String)
        .collection('messages')
        .doc(message['id'] as String)
        .set(message);
  }

  print('   ✓ Added ${chats.length} demo chats with ${messages.length} messages');
}

Future<void> addDemoNotifications(FirebaseFirestore firestore) async {
  print('🔔 Adding demo notifications...');

  final notifications = [
    {
      'id': 'notif_1',
      'userId': 'demo_user_1',
      'title': 'Leave Request Approved',
      'titleAr': 'تمت الموافقة على طلب الإجازة',
      'body': 'Your annual leave request for Dec 20-25 has been approved.',
      'bodyAr': 'تمت الموافقة على طلب إجازتك السنوية من 20-25 ديسمبر.',
      'type': 'NotificationType.workflow',
      'data': {'workflowId': 'workflow_1'},
      'isRead': false,
      'createdAt': Timestamp.now(),
    },
    {
      'id': 'notif_2',
      'userId': 'demo_user_1',
      'title': 'New Meeting Scheduled',
      'titleAr': 'تم جدولة اجتماع جديد',
      'body': 'Q4 Planning Meeting scheduled for tomorrow at 10:00 AM.',
      'bodyAr': 'تم جدولة اجتماع تخطيط الربع الرابع غداً الساعة 10:00 صباحاً.',
      'type': 'NotificationType.meeting',
      'data': {'meetingId': 'meeting_1'},
      'isRead': false,
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
    },
    {
      'id': 'notif_3',
      'userId': 'demo_user_1',
      'title': 'New Announcement',
      'titleAr': 'إعلان جديد',
      'body': 'Company Holiday Notice: Office closed Dec 25-26.',
      'bodyAr': 'إشعار عطلة الشركة: المكتب مغلق 25-26 ديسمبر.',
      'type': 'NotificationType.announcement',
      'data': {'announcementId': 'announcement_1'},
      'isRead': true,
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 3))),
    },
    {
      'id': 'notif_4',
      'userId': 'demo_user_1',
      'title': 'New Message',
      'titleAr': 'رسالة جديدة',
      'body': 'Omar Rashid: The new server is ready for deployment.',
      'bodyAr': 'عمر راشد: الخادم الجديد جاهز للنشر.',
      'type': 'NotificationType.message',
      'data': {'chatId': 'chat_2'},
      'isRead': false,
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 30))),
    },
    {
      'id': 'notif_5',
      'userId': 'demo_user_1',
      'title': 'Document Shared',
      'titleAr': 'تمت مشاركة مستند',
      'body': 'New document "Employee Handbook 2024" is now available.',
      'bodyAr': 'مستند جديد "دليل الموظفين 2024" متاح الآن.',
      'type': 'NotificationType.document',
      'data': {'documentId': 'doc_1'},
      'isRead': true,
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
    },
    {
      'id': 'notif_6',
      'userId': 'demo_user_2',
      'title': 'Workflow Pending Approval',
      'titleAr': 'سير عمل بانتظار الموافقة',
      'body': 'Ahmed Hassan submitted a leave request for your approval.',
      'bodyAr': 'قدم أحمد حسن طلب إجازة بانتظار موافقتك.',
      'type': 'NotificationType.workflow',
      'data': {'workflowId': 'workflow_1'},
      'isRead': false,
      'createdAt': Timestamp.now(),
    },
    {
      'id': 'notif_7',
      'userId': 'demo_user_3',
      'title': 'Purchase Request Pending',
      'titleAr': 'طلب شراء معلق',
      'body': 'Equipment purchase request from IT department needs your approval.',
      'bodyAr': 'طلب شراء معدات من قسم تقنية المعلومات يحتاج موافقتك.',
      'type': 'NotificationType.workflow',
      'data': {'workflowId': 'workflow_2'},
      'isRead': false,
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
    },
    {
      'id': 'notif_8',
      'userId': 'demo_user_4',
      'title': 'Expense Claim Processed',
      'titleAr': 'تمت معالجة مطالبة المصاريف',
      'body': 'Your travel expense claim has been approved and processed.',
      'bodyAr': 'تمت الموافقة على مطالبة مصاريف السفر ومعالجتها.',
      'type': 'NotificationType.workflow',
      'data': {'workflowId': 'workflow_3'},
      'isRead': true,
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
    },
    {
      'id': 'notif_9',
      'userId': 'demo_user_5',
      'title': 'IT Infrastructure Meeting',
      'titleAr': 'اجتماع البنية التحتية لتقنية المعلومات',
      'body': 'Reminder: IT Infrastructure Update meeting in 2 days.',
      'bodyAr': 'تذكير: اجتماع تحديث البنية التحتية لتقنية المعلومات بعد يومين.',
      'type': 'NotificationType.meeting',
      'data': {'meetingId': 'meeting_5'},
      'isRead': false,
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 5))),
    },
    {
      'id': 'notif_10',
      'userId': 'demo_user_1',
      'title': 'System Maintenance Alert',
      'titleAr': 'تنبيه صيانة النظام',
      'body': 'Scheduled maintenance this Saturday 10 PM - 2 AM.',
      'bodyAr': 'صيانة مجدولة هذا السبت من 10 مساءً حتى 2 صباحاً.',
      'type': 'NotificationType.announcement',
      'data': {'announcementId': 'announcement_3'},
      'isRead': false,
      'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 6))),
    },
  ];

  for (var notification in notifications) {
    await firestore.collection('notifications').doc(notification['id'] as String).set(notification);
  }
  print('   ✓ Added ${notifications.length} demo notifications');
}
