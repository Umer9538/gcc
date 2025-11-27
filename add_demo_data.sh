#!/bin/bash

# Demo Data Script for GCC Connect App
# This script adds demo data to Firebase Firestore using the Firebase CLI

PROJECT_ID="gcc-connect-44b69"

echo "🚀 Starting to add demo data to GCC Connect..."
echo ""

echo "👥 Adding demo users..."

# Demo User 1 - Basmah Alhamidi
firebase firestore:delete --project "$PROJECT_ID" -r "users/demo_user_1" 2>/dev/null
firebase firestore:delete --project "$PROJECT_ID" -r "users/demo_user_2" 2>/dev/null
firebase firestore:delete --project "$PROJECT_ID" -r "users/demo_user_3" 2>/dev/null
firebase firestore:delete --project "$PROJECT_ID" -r "users/demo_user_4" 2>/dev/null
firebase firestore:delete --project "$PROJECT_ID" -r "users/demo_user_5" 2>/dev/null

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "users/demo_user_1"
{
  "id": "demo_user_1",
  "email": "basmah.alhamidi@gcc.com",
  "firstName": "Basmah",
  "lastName": "Alhamidi",
  "phoneNumber": "+966 50 123 4567",
  "department": "Engineering",
  "position": "Senior Developer",
  "roles": ["employee"],
  "isActive": true,
  "studentId": "221410363"
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "users/demo_user_2"
{
  "id": "demo_user_2",
  "email": "nouf.alghanem@gcc.com",
  "firstName": "Nouf",
  "lastName": "AlGhanem",
  "phoneNumber": "+966 55 234 5678",
  "department": "Human Resources",
  "position": "HR Manager",
  "roles": ["employee", "manager"],
  "isActive": true,
  "studentId": "221410281"
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "users/demo_user_3"
{
  "id": "demo_user_3",
  "email": "dima.althenayan@gcc.com",
  "firstName": "Dima",
  "lastName": "Althenayan",
  "phoneNumber": "+966 54 345 6789",
  "department": "Finance",
  "position": "Financial Analyst",
  "roles": ["employee"],
  "isActive": true,
  "studentId": "221410087"
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "users/demo_user_4"
{
  "id": "demo_user_4",
  "email": "leen.alfawaz@gcc.com",
  "firstName": "Leen",
  "lastName": "Al Fawaz",
  "phoneNumber": "+966 56 456 7890",
  "department": "Marketing",
  "position": "Marketing Director",
  "roles": ["employee", "manager"],
  "isActive": true,
  "studentId": "222310838"
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "users/demo_user_5"
{
  "id": "demo_user_5",
  "email": "jana.alzmami@gcc.com",
  "firstName": "Jana",
  "lastName": "AlZmami",
  "phoneNumber": "+966 59 567 8901",
  "department": "IT Support",
  "position": "IT Manager",
  "roles": ["employee", "admin"],
  "isActive": true,
  "studentId": "221410306"
}
EOF

echo "   ✓ Added 5 demo users"

echo ""
echo "📅 Adding demo meetings..."

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "meetings/meeting_1"
{
  "id": "meeting_1",
  "title": "Q4 Planning Meeting",
  "titleAr": "اجتماع تخطيط الربع الرابع",
  "description": "Discuss Q4 goals and project allocations for all departments.",
  "descriptionAr": "مناقشة أهداف الربع الرابع وتوزيع المشاريع لجميع الأقسام.",
  "startTime": "10:00 AM",
  "endTime": "11:30 AM",
  "location": "Conference Room A",
  "locationAr": "قاعة المؤتمرات أ",
  "organizerId": "demo_user_2",
  "organizerName": "Nouf AlGhanem",
  "attendees": ["demo_user_1", "demo_user_3", "demo_user_4", "demo_user_5"],
  "status": "scheduled",
  "isActive": true
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "meetings/meeting_2"
{
  "id": "meeting_2",
  "title": "Product Launch Review",
  "titleAr": "مراجعة إطلاق المنتج",
  "description": "Review the upcoming product launch strategy and marketing materials.",
  "descriptionAr": "مراجعة استراتيجية إطلاق المنتج القادم والمواد التسويقية.",
  "startTime": "2:00 PM",
  "endTime": "3:30 PM",
  "location": "Meeting Room B",
  "locationAr": "غرفة الاجتماعات ب",
  "organizerId": "demo_user_4",
  "organizerName": "Leen Al Fawaz",
  "attendees": ["demo_user_1", "demo_user_2"],
  "status": "scheduled",
  "isActive": true
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "meetings/meeting_3"
{
  "id": "meeting_3",
  "title": "Weekly Team Standup",
  "titleAr": "اجتماع الفريق الأسبوعي",
  "description": "Weekly sync meeting for engineering team updates.",
  "descriptionAr": "اجتماع المزامنة الأسبوعي لتحديثات فريق الهندسة.",
  "startTime": "9:00 AM",
  "endTime": "9:30 AM",
  "location": "Virtual - Microsoft Teams",
  "locationAr": "افتراضي - مايكروسوفت تيمز",
  "organizerId": "demo_user_1",
  "organizerName": "Basmah Alhamidi",
  "attendees": ["demo_user_5"],
  "status": "scheduled",
  "isActive": true
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "meetings/meeting_4"
{
  "id": "meeting_4",
  "title": "Budget Review Meeting",
  "titleAr": "اجتماع مراجعة الميزانية",
  "description": "Annual budget review and allocation for next fiscal year.",
  "descriptionAr": "مراجعة الميزانية السنوية والتخصيص للسنة المالية القادمة.",
  "startTime": "11:00 AM",
  "endTime": "12:30 PM",
  "location": "Executive Boardroom",
  "locationAr": "قاعة مجلس الإدارة",
  "organizerId": "demo_user_3",
  "organizerName": "Dima Althenayan",
  "attendees": ["demo_user_2", "demo_user_4", "demo_user_5"],
  "status": "scheduled",
  "isActive": true
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "meetings/meeting_5"
{
  "id": "meeting_5",
  "title": "IT Infrastructure Update",
  "titleAr": "تحديث البنية التحتية لتقنية المعلومات",
  "description": "Discussion on upcoming IT infrastructure improvements and security updates.",
  "descriptionAr": "مناقشة تحسينات البنية التحتية لتقنية المعلومات والتحديثات الأمنية القادمة.",
  "startTime": "3:00 PM",
  "endTime": "4:00 PM",
  "location": "IT Department",
  "locationAr": "قسم تقنية المعلومات",
  "organizerId": "demo_user_5",
  "organizerName": "Jana AlZmami",
  "attendees": ["demo_user_1", "demo_user_2", "demo_user_3", "demo_user_4"],
  "status": "scheduled",
  "isActive": true
}
EOF

echo "   ✓ Added 5 demo meetings"

echo ""
echo "📢 Adding demo announcements..."

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "announcements/announcement_1"
{
  "id": "announcement_1",
  "title": "Company Holiday Notice",
  "titleAr": "إشعار عطلة الشركة",
  "content": "Please be informed that the office will be closed on December 25th and 26th for the holiday season. All employees are requested to complete pending tasks before the break.",
  "contentAr": "يرجى العلم أن المكتب سيكون مغلقاً يومي 25 و 26 ديسمبر بمناسبة موسم الأعياد. يرجى من جميع الموظفين إكمال المهام المعلقة قبل الإجازة.",
  "authorId": "demo_user_2",
  "authorName": "Nouf AlGhanem",
  "department": "Human Resources",
  "priority": "high",
  "category": "general",
  "isActive": true,
  "isPinned": true
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "announcements/announcement_2"
{
  "id": "announcement_2",
  "title": "New Employee Onboarding",
  "titleAr": "تأهيل الموظفين الجدد",
  "content": "We are pleased to welcome 5 new team members joining us this month. Please join us for a welcome reception in the main hall on Monday at 3 PM.",
  "contentAr": "يسعدنا الترحيب بـ 5 أعضاء جدد ينضمون إلينا هذا الشهر. يرجى الانضمام إلينا في حفل الترحيب في القاعة الرئيسية يوم الاثنين الساعة 3 مساءً.",
  "authorId": "demo_user_2",
  "authorName": "Nouf AlGhanem",
  "department": "Human Resources",
  "priority": "medium",
  "category": "hr",
  "isActive": true,
  "isPinned": false
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "announcements/announcement_3"
{
  "id": "announcement_3",
  "title": "System Maintenance Scheduled",
  "titleAr": "صيانة النظام المجدولة",
  "content": "The IT department will perform system maintenance this Saturday from 10 PM to 2 AM. Some services may be temporarily unavailable during this time.",
  "contentAr": "سيقوم قسم تقنية المعلومات بإجراء صيانة للنظام يوم السبت من الساعة 10 مساءً حتى 2 صباحاً. قد تكون بعض الخدمات غير متاحة مؤقتاً خلال هذه الفترة.",
  "authorId": "demo_user_5",
  "authorName": "Jana AlZmami",
  "department": "IT Support",
  "priority": "high",
  "category": "it",
  "isActive": true,
  "isPinned": true
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "announcements/announcement_4"
{
  "id": "announcement_4",
  "title": "Q3 Performance Results",
  "titleAr": "نتائج أداء الربع الثالث",
  "content": "We are excited to announce that we have exceeded our Q3 targets by 15 percent. Thank you to all team members for your dedication and hard work.",
  "contentAr": "يسعدنا أن نعلن أننا تجاوزنا أهداف الربع الثالث بنسبة 15%. شكراً لجميع أعضاء الفريق على تفانيكم وعملكم الجاد.",
  "authorId": "demo_user_3",
  "authorName": "Dima Althenayan",
  "department": "Finance",
  "priority": "medium",
  "category": "general",
  "isActive": true,
  "isPinned": false
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "announcements/announcement_5"
{
  "id": "announcement_5",
  "title": "New Marketing Campaign Launch",
  "titleAr": "إطلاق حملة تسويقية جديدة",
  "content": "Our new digital marketing campaign Innovation Forward will launch next week. All departments are encouraged to share the campaign materials on their social media.",
  "contentAr": "ستنطلق حملتنا التسويقية الرقمية الجديدة الابتكار نحو الأمام الأسبوع المقبل. نشجع جميع الأقسام على مشاركة مواد الحملة على وسائل التواصل الاجتماعي.",
  "authorId": "demo_user_4",
  "authorName": "Leen Al Fawaz",
  "department": "Marketing",
  "priority": "medium",
  "category": "marketing",
  "isActive": true,
  "isPinned": false
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "announcements/announcement_6"
{
  "id": "announcement_6",
  "title": "Health and Safety Training",
  "titleAr": "تدريب الصحة والسلامة",
  "content": "Mandatory health and safety training will be conducted next Wednesday. All employees must attend. Please register through the HR portal.",
  "contentAr": "سيتم إجراء تدريب إلزامي للصحة والسلامة يوم الأربعاء القادم. يجب على جميع الموظفين الحضور. يرجى التسجيل من خلال بوابة الموارد البشرية.",
  "authorId": "demo_user_2",
  "authorName": "Nouf AlGhanem",
  "department": "Human Resources",
  "priority": "high",
  "category": "hr",
  "isActive": true,
  "isPinned": true
}
EOF

echo "   ✓ Added 6 demo announcements"

echo ""
echo "📄 Adding demo documents..."

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "documents/doc_1"
{
  "id": "doc_1",
  "title": "Employee Handbook 2024",
  "description": "Complete guide for all employees covering company policies, benefits, and procedures.",
  "fileUrl": "https://example.com/docs/employee_handbook.pdf",
  "fileName": "Employee_Handbook_2024.pdf",
  "fileType": "pdf",
  "fileSize": 2500000,
  "uploadedById": "demo_user_2",
  "uploadedByName": "Nouf AlGhanem",
  "allowedRoles": [],
  "allowedDepartments": [],
  "category": "DocumentCategory.policies",
  "isActive": true
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "documents/doc_2"
{
  "id": "doc_2",
  "title": "IT Security Guidelines",
  "description": "Security protocols and best practices for all employees.",
  "fileUrl": "https://example.com/docs/it_security.pdf",
  "fileName": "IT_Security_Guidelines.pdf",
  "fileType": "pdf",
  "fileSize": 1800000,
  "uploadedById": "demo_user_5",
  "uploadedByName": "Jana AlZmami",
  "allowedRoles": [],
  "allowedDepartments": [],
  "category": "DocumentCategory.procedures",
  "isActive": true
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "documents/doc_3"
{
  "id": "doc_3",
  "title": "Annual Report 2023",
  "description": "Company annual financial and operational report.",
  "fileUrl": "https://example.com/docs/annual_report.pdf",
  "fileName": "Annual_Report_2023.pdf",
  "fileType": "pdf",
  "fileSize": 5200000,
  "uploadedById": "demo_user_3",
  "uploadedByName": "Dima Althenayan",
  "allowedRoles": ["manager", "admin"],
  "allowedDepartments": [],
  "category": "DocumentCategory.reports",
  "isActive": true
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "documents/doc_4"
{
  "id": "doc_4",
  "title": "Leave Request Form",
  "description": "Standard form for requesting annual or sick leave.",
  "fileUrl": "https://example.com/docs/leave_form.docx",
  "fileName": "Leave_Request_Form.docx",
  "fileType": "docx",
  "fileSize": 45000,
  "uploadedById": "demo_user_2",
  "uploadedByName": "Nouf AlGhanem",
  "allowedRoles": [],
  "allowedDepartments": [],
  "category": "DocumentCategory.forms",
  "isActive": true
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "documents/doc_5"
{
  "id": "doc_5",
  "title": "Brand Guidelines",
  "description": "Official brand guidelines including logo usage, colors, and typography.",
  "fileUrl": "https://example.com/docs/brand_guidelines.pdf",
  "fileName": "Brand_Guidelines.pdf",
  "fileType": "pdf",
  "fileSize": 8500000,
  "uploadedById": "demo_user_4",
  "uploadedByName": "Leen Al Fawaz",
  "allowedRoles": [],
  "allowedDepartments": ["Marketing"],
  "category": "DocumentCategory.general",
  "isActive": true
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "documents/doc_6"
{
  "id": "doc_6",
  "title": "Expense Reimbursement Policy",
  "description": "Guidelines for submitting expense claims and reimbursements.",
  "fileUrl": "https://example.com/docs/expense_policy.pdf",
  "fileName": "Expense_Reimbursement_Policy.pdf",
  "fileType": "pdf",
  "fileSize": 980000,
  "uploadedById": "demo_user_3",
  "uploadedByName": "Dima Althenayan",
  "allowedRoles": [],
  "allowedDepartments": [],
  "category": "DocumentCategory.policies",
  "isActive": true
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "documents/doc_7"
{
  "id": "doc_7",
  "title": "Project Proposal Template",
  "description": "Standard template for submitting new project proposals.",
  "fileUrl": "https://example.com/docs/project_template.docx",
  "fileName": "Project_Proposal_Template.docx",
  "fileType": "docx",
  "fileSize": 125000,
  "uploadedById": "demo_user_1",
  "uploadedByName": "Basmah Alhamidi",
  "allowedRoles": [],
  "allowedDepartments": [],
  "category": "DocumentCategory.forms",
  "isActive": true
}
EOF

echo "   ✓ Added 7 demo documents"

echo ""
echo "🔄 Adding demo workflows..."

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "workflows/workflow_1"
{
  "id": "workflow_1",
  "title": "Annual Leave Request",
  "titleAr": "طلب إجازة سنوية",
  "description": "Request for 5 days annual leave from Dec 20-25 for family vacation.",
  "descriptionAr": "طلب إجازة سنوية لمدة 5 أيام من 20-25 ديسمبر لقضاء إجازة عائلية.",
  "type": "WorkflowType.leaveRequest",
  "status": "WorkflowStatus.pending",
  "priority": "WorkflowPriority.medium",
  "initiatorId": "demo_user_1",
  "initiatorName": "Basmah Alhamidi",
  "assigneeId": "demo_user_2",
  "assigneeName": "Nouf AlGhanem",
  "department": "Engineering",
  "currentStepIndex": 0,
  "steps": [{"id": "step_1", "title": "Manager Approval", "titleAr": "موافقة المدير", "assigneeId": "demo_user_2", "assigneeName": "Nouf AlGhanem", "status": "WorkflowStatus.pending", "order": 0}],
  "attachments": [],
  "comments": []
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "workflows/workflow_2"
{
  "id": "workflow_2",
  "title": "Equipment Purchase Request",
  "titleAr": "طلب شراء معدات",
  "description": "Request to purchase new laptops for the development team (5 units).",
  "descriptionAr": "طلب شراء أجهزة كمبيوتر محمولة جديدة لفريق التطوير (5 وحدات).",
  "type": "WorkflowType.purchaseRequest",
  "status": "WorkflowStatus.inProgress",
  "priority": "WorkflowPriority.high",
  "initiatorId": "demo_user_5",
  "initiatorName": "Jana AlZmami",
  "assigneeId": "demo_user_3",
  "assigneeName": "Dima Althenayan",
  "department": "IT Support",
  "currentStepIndex": 1,
  "steps": [{"id": "step_1", "title": "IT Manager Approval", "assigneeId": "demo_user_5", "assigneeName": "Jana AlZmami", "status": "WorkflowStatus.completed", "order": 0}, {"id": "step_2", "title": "Finance Approval", "assigneeId": "demo_user_3", "assigneeName": "Dima Althenayan", "status": "WorkflowStatus.pending", "order": 1}],
  "attachments": [],
  "comments": [{"id": "comment_1", "userId": "demo_user_5", "userName": "Jana AlZmami", "content": "Approved from IT side. Budget allocation confirmed."}]
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "workflows/workflow_3"
{
  "id": "workflow_3",
  "title": "Travel Expense Claim",
  "titleAr": "مطالبة مصاريف السفر",
  "description": "Reimbursement request for business trip to Dubai (Nov 15-18).",
  "descriptionAr": "طلب تعويض لرحلة العمل إلى دبي (15-18 نوفمبر).",
  "type": "WorkflowType.expenseClaim",
  "status": "WorkflowStatus.completed",
  "priority": "WorkflowPriority.low",
  "initiatorId": "demo_user_4",
  "initiatorName": "Leen Al Fawaz",
  "assigneeId": "demo_user_3",
  "assigneeName": "Dima Althenayan",
  "department": "Marketing",
  "currentStepIndex": 2,
  "steps": [{"id": "step_1", "title": "Department Manager Approval", "status": "WorkflowStatus.completed", "order": 0}, {"id": "step_2", "title": "Finance Review", "status": "WorkflowStatus.completed", "order": 1}],
  "attachments": [],
  "comments": [{"id": "comment_1", "userId": "demo_user_3", "userName": "Dima Althenayan", "content": "All receipts verified. Payment processed."}]
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "workflows/workflow_4"
{
  "id": "workflow_4",
  "title": "New Project Approval",
  "titleAr": "موافقة مشروع جديد",
  "description": "Approval request for new mobile app development project.",
  "descriptionAr": "طلب موافقة لمشروع تطوير تطبيق جوال جديد.",
  "type": "WorkflowType.approval",
  "status": "WorkflowStatus.pending",
  "priority": "WorkflowPriority.high",
  "initiatorId": "demo_user_1",
  "initiatorName": "Basmah Alhamidi",
  "assigneeId": "demo_user_2",
  "assigneeName": "Nouf AlGhanem",
  "department": "Engineering",
  "currentStepIndex": 0,
  "steps": [{"id": "step_1", "title": "HR Review", "assigneeId": "demo_user_2", "assigneeName": "Nouf AlGhanem", "status": "WorkflowStatus.pending", "order": 0}, {"id": "step_2", "title": "Budget Approval", "assigneeId": "demo_user_3", "assigneeName": "Dima Althenayan", "status": "WorkflowStatus.pending", "order": 1}],
  "attachments": [],
  "comments": []
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "workflows/workflow_5"
{
  "id": "workflow_5",
  "title": "Sick Leave Request",
  "titleAr": "طلب إجازة مرضية",
  "description": "Sick leave request for 2 days due to medical appointment.",
  "descriptionAr": "طلب إجازة مرضية لمدة يومين بسبب موعد طبي.",
  "type": "WorkflowType.leaveRequest",
  "status": "WorkflowStatus.approved",
  "priority": "WorkflowPriority.medium",
  "initiatorId": "demo_user_3",
  "initiatorName": "Dima Althenayan",
  "assigneeId": "demo_user_2",
  "assigneeName": "Nouf AlGhanem",
  "department": "Finance",
  "currentStepIndex": 1,
  "steps": [{"id": "step_1", "title": "HR Approval", "assigneeId": "demo_user_2", "assigneeName": "Nouf AlGhanem", "status": "WorkflowStatus.completed", "order": 0}],
  "attachments": [],
  "comments": [{"id": "comment_1", "userId": "demo_user_2", "userName": "Nouf AlGhanem", "content": "Approved. Get well soon!"}]
}
EOF

echo "   ✓ Added 5 demo workflows"

echo ""
echo "💬 Adding demo chats..."

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "chats/chat_1"
{
  "id": "chat_1",
  "type": "direct",
  "participants": ["demo_user_1", "demo_user_2"],
  "lastMessage": "Thank you for approving my leave request!",
  "lastMessageBy": "demo_user_1",
  "isActive": true
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "chats/chat_2"
{
  "id": "chat_2",
  "type": "direct",
  "participants": ["demo_user_1", "demo_user_5"],
  "lastMessage": "The new server is ready for deployment.",
  "lastMessageBy": "demo_user_5",
  "isActive": true
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "chats/chat_3"
{
  "id": "chat_3",
  "type": "group",
  "name": "Engineering Team",
  "nameAr": "فريق الهندسة",
  "participants": ["demo_user_1", "demo_user_5"],
  "lastMessage": "Sprint planning meeting tomorrow at 10 AM.",
  "lastMessageBy": "demo_user_1",
  "isActive": true
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "chats/chat_4"
{
  "id": "chat_4",
  "type": "group",
  "name": "Management Team",
  "nameAr": "فريق الإدارة",
  "participants": ["demo_user_2", "demo_user_3", "demo_user_4", "demo_user_5"],
  "lastMessage": "Q4 targets have been finalized.",
  "lastMessageBy": "demo_user_3",
  "isActive": true
}
EOF

echo "   ✓ Added 4 demo chats"

echo ""
echo "🔔 Adding demo notifications..."

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "notifications/notif_1"
{
  "id": "notif_1",
  "userId": "demo_user_1",
  "title": "Leave Request Approved",
  "titleAr": "تمت الموافقة على طلب الإجازة",
  "body": "Your annual leave request for Dec 20-25 has been approved.",
  "bodyAr": "تمت الموافقة على طلب إجازتك السنوية من 20-25 ديسمبر.",
  "type": "NotificationType.workflow",
  "isRead": false
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "notifications/notif_2"
{
  "id": "notif_2",
  "userId": "demo_user_1",
  "title": "New Meeting Scheduled",
  "titleAr": "تم جدولة اجتماع جديد",
  "body": "Q4 Planning Meeting scheduled for tomorrow at 10:00 AM.",
  "bodyAr": "تم جدولة اجتماع تخطيط الربع الرابع غداً الساعة 10:00 صباحاً.",
  "type": "NotificationType.meeting",
  "isRead": false
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "notifications/notif_3"
{
  "id": "notif_3",
  "userId": "demo_user_1",
  "title": "New Announcement",
  "titleAr": "إعلان جديد",
  "body": "Company Holiday Notice: Office closed Dec 25-26.",
  "bodyAr": "إشعار عطلة الشركة: المكتب مغلق 25-26 ديسمبر.",
  "type": "NotificationType.announcement",
  "isRead": true
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "notifications/notif_4"
{
  "id": "notif_4",
  "userId": "demo_user_1",
  "title": "New Message",
  "titleAr": "رسالة جديدة",
  "body": "Jana AlZmami: The new server is ready for deployment.",
  "bodyAr": "جنى الزمامي: الخادم الجديد جاهز للنشر.",
  "type": "NotificationType.message",
  "isRead": false
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "notifications/notif_5"
{
  "id": "notif_5",
  "userId": "demo_user_1",
  "title": "Document Shared",
  "titleAr": "تمت مشاركة مستند",
  "body": "New document Employee Handbook 2024 is now available.",
  "bodyAr": "مستند جديد دليل الموظفين 2024 متاح الآن.",
  "type": "NotificationType.document",
  "isRead": true
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "notifications/notif_6"
{
  "id": "notif_6",
  "userId": "demo_user_2",
  "title": "Workflow Pending Approval",
  "titleAr": "سير عمل بانتظار الموافقة",
  "body": "Basmah Alhamidi submitted a leave request for your approval.",
  "bodyAr": "قدمت بسمة الحميدي طلب إجازة بانتظار موافقتك.",
  "type": "NotificationType.workflow",
  "isRead": false
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "notifications/notif_7"
{
  "id": "notif_7",
  "userId": "demo_user_3",
  "title": "Purchase Request Pending",
  "titleAr": "طلب شراء معلق",
  "body": "Equipment purchase request from IT department needs your approval.",
  "bodyAr": "طلب شراء معدات من قسم تقنية المعلومات يحتاج موافقتك.",
  "type": "NotificationType.workflow",
  "isRead": false
}
EOF

cat <<EOF | firebase firestore:set --project "$PROJECT_ID" "notifications/notif_8"
{
  "id": "notif_8",
  "userId": "demo_user_1",
  "title": "System Maintenance Alert",
  "titleAr": "تنبيه صيانة النظام",
  "body": "Scheduled maintenance this Saturday 10 PM - 2 AM.",
  "bodyAr": "صيانة مجدولة هذا السبت من 10 مساءً حتى 2 صباحاً.",
  "type": "NotificationType.announcement",
  "isRead": false
}
EOF

echo "   ✓ Added 8 demo notifications"

echo ""
echo "✅ All demo data added successfully!"
echo ""
echo "📱 Demo Data Summary:"
echo "   • 5 Users:"
echo "     - Basmah Alhamidi (221410363) - Engineering"
echo "     - Nouf AlGhanem (221410281) - HR Manager"
echo "     - Dima Althenayan (221410087) - Finance"
echo "     - Leen Al Fawaz (222310838) - Marketing"
echo "     - Jana AlZmami (221410306) - IT Manager"
echo "   • 5 Meetings"
echo "   • 6 Announcements"
echo "   • 7 Documents"
echo "   • 5 Workflows"
echo "   • 4 Chats"
echo "   • 8 Notifications"
echo ""
echo "🎉 You can now demo all functionalities in the app!"
