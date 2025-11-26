import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../constants/app_constants.dart';
import '../../services/document_service.dart';
import '../../models/document_model.dart';
import '../../utils/date_utils.dart';
import '../../widgets/shimmer_loading.dart';
import '../../services/permissions_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:html' as html show FileUploadInputElement, File, FileReader, Blob, Url, AnchorElement;

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> with SingleTickerProviderStateMixin {
  final DocumentService _documentService = DocumentService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  DocumentCategory _selectedCategory = DocumentCategory.general;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
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
              isRTL ? 'إدارة الوثائق' : 'Document Management',
              style: AppTextStyles.heading2.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.primaryColor,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              isScrollable: true,
              tabs: [
                Tab(text: isRTL ? 'المتاحة' : 'Available'),
                Tab(text: isRTL ? 'النماذج' : 'Templates'),
                Tab(text: isRTL ? 'الطلبات' : 'Requests'),
                Tab(text: isRTL ? 'الإحصائيات' : 'Stats'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAvailableDocumentsTab(userId, currentUser, isRTL),
              _buildTemplatesTab(isRTL),
              _buildRequestsTab(userId, currentUser, isRTL),
              _buildStatsTab(userId, currentUser, isRTL),
            ],
          ),
          floatingActionButton: currentUser != null
              ? FutureBuilder<bool>(
                  future: PermissionsService().hasPermission(
                    currentUser,
                    Permission.uploadDocuments,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data == true) {
                      return FloatingActionButton.extended(
                        onPressed: () => _showUploadDocumentDialog(currentUser, isRTL),
                        backgroundColor: AppColors.primaryColor,
                        icon: const Icon(Icons.upload_file, color: Colors.white),
                        label: Text(
                          isRTL ? 'رفع وثيقة' : 'Upload Document',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildAvailableDocumentsTab(String userId, currentUser, bool isRTL) {
    return Column(
      children: [
        // Search and Filter Section
        Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          color: AppColors.surfaceColor,
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: isRTL ? 'البحث في الوثائق...' : 'Search documents...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    borderSide: const BorderSide(color: AppColors.borderColor),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),

              // Category Filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: DocumentCategory.values.map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_getCategoryName(category, isRTL)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        selectedColor: AppColors.primaryColor.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primaryColor,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Documents List
        Expanded(
          child: StreamBuilder<List<DocumentModel>>(
            stream: _documentService.getDocumentsForUser(
              userId: userId,
              userDepartment: currentUser?.department ?? '',
              userRoles: currentUser?.roles ?? [],
            ),
            builder: (context, snapshot) {
              final size = MediaQuery.of(context).size;
              final isWeb = kIsWeb || size.width > 800;

              if (snapshot.connectionState == ConnectionState.waiting) {
                return ShimmerLoading.listItem(isWeb: isWeb, count: 5);
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState(
                  isRTL ? 'لا توجد وثائق متاحة' : 'No documents available',
                  isRTL ? 'لا توجد وثائق يمكنك الوصول إليها حالياً' : 'No documents you can access currently',
                  Icons.description_outlined,
                );
              }

              List<DocumentModel> documents = snapshot.data!;

              // Apply category filter
              if (_selectedCategory != DocumentCategory.general) {
                documents = documents.where((doc) => doc.category == _selectedCategory).toList();
              }

              // Apply search filter
              if (_searchQuery.isNotEmpty) {
                documents = documents.where((doc) {
                  final query = _searchQuery.toLowerCase();
                  return doc.title.toLowerCase().contains(query) ||
                      doc.description.toLowerCase().contains(query) ||
                      doc.fileName.toLowerCase().contains(query);
                }).toList();
              }

              if (documents.isEmpty) {
                return _buildEmptyState(
                  isRTL ? 'لا توجد نتائج' : 'No results found',
                  isRTL ? 'حاول تعديل البحث أو الفلتر' : 'Try adjusting your search or filter',
                  Icons.search_off,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final document = documents[index];
                  return _buildDocumentCard(document, isRTL, currentUser);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab(String userId, currentUser, bool isRTL) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: AppColors.primaryColor,
            unselectedLabelColor: AppColors.textSecondaryColor,
            tabs: [
              Tab(text: isRTL ? 'طلباتي' : 'My Requests'),
              Tab(text: isRTL ? 'للمراجعة' : 'To Review'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildMyRequestsTab(userId, isRTL),
                _buildRequestsToReviewTab(userId, isRTL),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRequestsTab(String userId, bool isRTL) {
    final size = MediaQuery.of(context).size;
    final isWeb = kIsWeb || size.width > 800;

    return StreamBuilder<List<DocumentRequestModel>>(
      stream: _documentService.getUserDocumentRequests(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ShimmerLoading.listItem(isWeb: isWeb, count: 5);
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            isRTL ? 'لا توجد طلبات' : 'No requests',
            isRTL ? 'لم تقم بإرسال أي طلبات للوصول للوثائق' : 'You haven\'t made any document access requests',
            Icons.request_page_outlined,
          );
        }

        final requests = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildRequestCard(request, isRTL, false);
          },
        );
      },
    );
  }

  Widget _buildRequestsToReviewTab(String userId, bool isRTL) {
    final size = MediaQuery.of(context).size;
    final isWeb = kIsWeb || size.width > 800;

    return StreamBuilder<List<DocumentRequestModel>>(
      stream: _documentService.getPendingRequestsForUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ShimmerLoading.listItem(isWeb: isWeb, count: 5);
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            isRTL ? 'لا توجد طلبات للمراجعة' : 'No requests to review',
            isRTL ? 'لا توجد طلبات للوصول لوثائقك' : 'No pending requests for your documents',
            Icons.rate_review_outlined,
          );
        }

        final requests = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildRequestCard(request, isRTL, true);
          },
        );
      },
    );
  }

  Widget _buildStatsTab(String userId, currentUser, bool isRTL) {
    final size = MediaQuery.of(context).size;
    final isWeb = kIsWeb || size.width > 800;

    return FutureBuilder<Map<String, int>>(
      future: _documentService.getDocumentStats(
        userId: userId,
        userDepartment: currentUser?.department ?? '',
        userRoles: currentUser?.roles ?? [],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ShimmerLoading.gridItem(isWeb: isWeb, count: 4, crossAxisCount: 2);
        }

        if (!snapshot.hasData) {
          return _buildEmptyState(
            isRTL ? 'خطأ في تحميل الإحصائيات' : 'Error loading stats',
            isRTL ? 'حاول مرة أخرى لاحقاً' : 'Please try again later',
            Icons.error_outline,
          );
        }

        final stats = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              _buildStatCard(
                isRTL ? 'الوثائق المتاحة' : 'Available Documents',
                stats['accessibleDocuments'] ?? 0,
                Icons.description,
                AppColors.primaryColor,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildStatCard(
                isRTL ? 'الطلبات المعلقة' : 'Pending Requests',
                stats['pendingRequests'] ?? 0,
                Icons.pending_actions,
                AppColors.warningColor,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildStatCard(
                isRTL ? 'الطلبات المقبولة' : 'Approved Requests',
                stats['approvedRequests'] ?? 0,
                Icons.check_circle,
                AppColors.successColor,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildStatCard(
                isRTL ? 'الطلبات المرفوضة' : 'Rejected Requests',
                stats['rejectedRequests'] ?? 0,
                Icons.cancel,
                AppColors.errorColor,
              ),
              if ((stats['requestsToReview'] ?? 0) > 0) ...[
                const SizedBox(height: AppConstants.defaultPadding),
                _buildStatCard(
                  isRTL ? 'طلبات للمراجعة' : 'Requests to Review',
                  stats['requestsToReview'] ?? 0,
                  Icons.rate_review,
                  AppColors.infoColor,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplatesTab(bool isRTL) {
    final templates = [
      {
        'id': 'vacation_leave_en',
        'title': 'Vacation Leave Request',
        'titleAr': 'طلب إجازة',
        'description': 'Official vacation leave request form',
        'descriptionAr': 'نموذج طلب إجازة رسمي',
        'icon': Icons.beach_access,
        'color': AppColors.gentleGreen,
        'content': '''
VACATION LEAVE REQUEST FORM

Employee Name: _______________________
Employee ID: _______________________
Department: _______________________
Position: _______________________

Leave Type:
☐ Annual Leave
☐ Sick Leave
☐ Emergency Leave
☐ Unpaid Leave
☐ Other: _______________________

Leave Period:
From: ___/___/______
To: ___/___/______
Total Days: _______

Reason for Leave:
_______________________________________________
_______________________________________________
_______________________________________________

Contact Information During Leave:
Phone: _______________________
Email: _______________________

Work Handover:
Tasks delegated to: _______________________
Handover notes: _______________________

Employee Signature: _____________ Date: ___/___/______

APPROVAL SECTION:
☐ Approved  ☐ Rejected

Manager Name: _______________________
Manager Signature: _____________ Date: ___/___/______

HR Approval: _______________________
Date: ___/___/______
''',
        'contentAr': '''
نموذج طلب إجازة

اسم الموظف: _______________________
الرقم الوظيفي: _______________________
القسم: _______________________
المسمى الوظيفي: _______________________

نوع الإجازة:
☐ إجازة سنوية
☐ إجازة مرضية
☐ إجازة طارئة
☐ إجازة بدون راتب
☐ أخرى: _______________________

فترة الإجازة:
من: ___/___/______
إلى: ___/___/______
إجمالي الأيام: _______

سبب الإجازة:
_______________________________________________
_______________________________________________
_______________________________________________

معلومات الاتصال خلال الإجازة:
الهاتف: _______________________
البريد الإلكتروني: _______________________

تسليم العمل:
المهام المفوضة إلى: _______________________
ملاحظات التسليم: _______________________

توقيع الموظف: _____________ التاريخ: ___/___/______

قسم الموافقة:
☐ موافق  ☐ مرفوض

اسم المدير: _______________________
توقيع المدير: _____________ التاريخ: ___/___/______

موافقة الموارد البشرية: _______________________
التاريخ: ___/___/______
''',
      },
      {
        'id': 'promotion_request_en',
        'title': 'Promotion Request',
        'titleAr': 'طلب ترقية',
        'description': 'Official promotion request form',
        'descriptionAr': 'نموذج طلب ترقية رسمي',
        'icon': Icons.trending_up,
        'color': AppColors.gentlePurple,
        'content': '''
PROMOTION REQUEST FORM

EMPLOYEE INFORMATION:
Full Name: _______________________
Employee ID: _______________________
Current Department: _______________________
Current Position: _______________________
Date of Joining: ___/___/______
Years of Service: _______

REQUESTED PROMOTION:
Desired Position: _______________________
Desired Department: _______________________

QUALIFICATIONS & ACHIEVEMENTS:

Educational Background:
_______________________________________________
_______________________________________________

Professional Certifications:
_______________________________________________
_______________________________________________

Key Achievements in Current Role:
1. _______________________________________________
2. _______________________________________________
3. _______________________________________________
4. _______________________________________________
5. _______________________________________________

Projects Completed:
_______________________________________________
_______________________________________________

Training Programs Attended:
_______________________________________________
_______________________________________________

JUSTIFICATION FOR PROMOTION:
_______________________________________________
_______________________________________________
_______________________________________________
_______________________________________________

CAREER GOALS:
_______________________________________________
_______________________________________________

Employee Signature: _____________ Date: ___/___/______

MANAGER RECOMMENDATION:
☐ Strongly Recommend  ☐ Recommend  ☐ Do Not Recommend

Comments:
_______________________________________________
_______________________________________________

Manager Name: _______________________
Manager Signature: _____________ Date: ___/___/______

HR REVIEW:
☐ Approved  ☐ Pending Review  ☐ Rejected

HR Comments:
_______________________________________________

HR Representative: _______________________
Date: ___/___/______

FINAL APPROVAL:
☐ Approved  ☐ Rejected

Effective Date: ___/___/______
New Position: _______________________
New Salary Grade: _______________________

Authorized Signature: _______________________
Date: ___/___/______
''',
        'contentAr': '''
نموذج طلب ترقية

معلومات الموظف:
الاسم الكامل: _______________________
الرقم الوظيفي: _______________________
القسم الحالي: _______________________
المسمى الوظيفي الحالي: _______________________
تاريخ الالتحاق: ___/___/______
سنوات الخدمة: _______

الترقية المطلوبة:
المسمى الوظيفي المطلوب: _______________________
القسم المطلوب: _______________________

المؤهلات والإنجازات:

الخلفية التعليمية:
_______________________________________________
_______________________________________________

الشهادات المهنية:
_______________________________________________
_______________________________________________

الإنجازات الرئيسية في الدور الحالي:
1. _______________________________________________
2. _______________________________________________
3. _______________________________________________
4. _______________________________________________
5. _______________________________________________

المشاريع المنجزة:
_______________________________________________
_______________________________________________

البرامج التدريبية:
_______________________________________________
_______________________________________________

مبررات طلب الترقية:
_______________________________________________
_______________________________________________
_______________________________________________
_______________________________________________

الأهداف المهنية:
_______________________________________________
_______________________________________________

توقيع الموظف: _____________ التاريخ: ___/___/______

توصية المدير:
☐ أوصي بشدة  ☐ أوصي  ☐ لا أوصي

التعليقات:
_______________________________________________
_______________________________________________

اسم المدير: _______________________
توقيع المدير: _____________ التاريخ: ___/___/______

مراجعة الموارد البشرية:
☐ موافق  ☐ قيد المراجعة  ☐ مرفوض

تعليقات الموارد البشرية:
_______________________________________________

ممثل الموارد البشرية: _______________________
التاريخ: ___/___/______

الموافقة النهائية:
☐ موافق  ☐ مرفوض

تاريخ السريان: ___/___/______
المسمى الوظيفي الجديد: _______________________
الدرجة الوظيفية الجديدة: _______________________

التوقيع المعتمد: _______________________
التاريخ: ___/___/______
''',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: (template['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        template['icon'] as IconData,
                        color: template['color'] as Color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: AppConstants.defaultPadding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isRTL ? template['titleAr'] as String : template['title'] as String,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isRTL ? template['descriptionAr'] as String : template['description'] as String,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showTemplatePreview(
                          isRTL ? template['titleAr'] as String : template['title'] as String,
                          template['content'] as String,
                          isRTL,
                          false,
                        ),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: Text(isRTL ? 'عرض (EN)' : 'View (EN)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: template['color'] as Color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showTemplatePreview(
                          template['titleAr'] as String,
                          template['contentAr'] as String,
                          isRTL,
                          true,
                        ),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: Text(isRTL ? 'عرض (AR)' : 'View (AR)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: template['color'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadTemplate(
                          template['title'] as String,
                          template['content'] as String,
                          isRTL,
                        ),
                        icon: const Icon(Icons.download, size: 18),
                        label: Text(isRTL ? 'تحميل (EN)' : 'Download (EN)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: template['color'] as Color,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadTemplate(
                          template['titleAr'] as String,
                          template['contentAr'] as String,
                          isRTL,
                        ),
                        icon: const Icon(Icons.download, size: 18),
                        label: Text(isRTL ? 'تحميل (AR)' : 'Download (AR)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: template['color'] as Color,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTemplatePreview(String title, String content, bool isRTL, bool isArabic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            ),
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

  void _downloadTemplate(String title, String content, bool isRTL) {
    if (kIsWeb) {
      // For web, create a downloadable text file
      final bytes = content.codeUnits;
      final blob = html.Blob([bytes], 'text/plain', 'native');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', '${title.replaceAll(' ', '_')}.txt')
        ..click();
      html.Url.revokeObjectUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRTL ? 'جاري تحميل النموذج...' : 'Downloading template...'),
          backgroundColor: AppColors.successColor,
        ),
      );
    } else {
      // For mobile, show a message (would need path_provider for actual download)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRTL ? 'عرض النموذج على الشاشة' : 'Template preview shown'),
          backgroundColor: AppColors.infoColor,
        ),
      );
      _showTemplatePreview(title, content, isRTL, title.contains('طلب'));
    }
  }

  Widget _buildDocumentCard(DocumentModel document, bool isRTL, currentUser) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(document.category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(document.category),
                    color: _getCategoryColor(document.category),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        document.description,
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleDocumentAction(value, document, currentUser, isRTL),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          const Icon(Icons.visibility),
                          const SizedBox(width: 8),
                          Text(isRTL ? 'عرض' : 'View'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          const Icon(Icons.download),
                          const SizedBox(width: 8),
                          Text(isRTL ? 'تحميل' : 'Download'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'request',
                      child: Row(
                        children: [
                          const Icon(Icons.request_page),
                          const SizedBox(width: 8),
                          Text(isRTL ? 'طلب الوصول' : 'Request Access'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildInfoChip(
                  Icons.file_present,
                  document.fileName,
                  AppColors.primaryColor,
                ),
                _buildInfoChip(
                  Icons.file_copy,
                  document.fileType.toUpperCase(),
                  AppColors.secondaryColor,
                ),
                _buildInfoChip(
                  Icons.folder,
                  _getCategoryName(document.category, isRTL),
                  _getCategoryColor(document.category),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${isRTL ? 'رفع بواسطة' : 'Uploaded by'}: ${document.uploadedByName}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryColor,
                  ),
                ),
                Text(
                  AppDateUtils.formatDate(document.createdAt, locale: isRTL ? 'ar' : 'en'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(DocumentRequestModel request, bool isRTL, bool canReview) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(request.status),
                    color: _getStatusColor(request.status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.defaultPadding),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.documentTitle,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        canReview
                            ? '${isRTL ? 'مطلوب من' : 'Requested by'}: ${request.requesterName}'
                            : '${isRTL ? 'الحالة' : 'Status'}: ${_getStatusText(request.status, isRTL)}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (canReview && request.status == RequestStatus.pending)
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleRequestAction(value, request, isRTL),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'approve',
                        child: Row(
                          children: [
                            const Icon(Icons.check, color: AppColors.successColor),
                            const SizedBox(width: 8),
                            Text(isRTL ? 'قبول' : 'Approve'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'reject',
                        child: Row(
                          children: [
                            const Icon(Icons.close, color: AppColors.errorColor),
                            const SizedBox(width: 8),
                            Text(isRTL ? 'رفض' : 'Reject'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRTL ? 'سبب الطلب:' : 'Reason:',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.reason,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppDateUtils.formatDate(request.requestedAt, locale: isRTL ? 'ar' : 'en'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryColor,
                  ),
                ),
                if (request.approvedAt != null)
                  Text(
                    '${isRTL ? 'تمت المراجعة' : 'Reviewed'}: ${AppDateUtils.formatDate(request.approvedAt!, locale: isRTL ? 'ar' : 'en')}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryColor,
                    ),
                  ),
              ],
            ),
            if (request.rejectionReason != null) ...[
              const SizedBox(height: AppConstants.smallPadding),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isRTL ? 'سبب الرفض' : 'Rejection reason'}: ${request.rejectionReason}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.errorColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.toString(),
                    style: AppTextStyles.heading3.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(fontSize: 12, color: color),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
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
            title,
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

  String _getCategoryName(DocumentCategory category, bool isRTL) {
    switch (category) {
      case DocumentCategory.reports:
        return isRTL ? 'التقارير' : 'Reports';
      case DocumentCategory.policies:
        return isRTL ? 'السياسات' : 'Policies';
      case DocumentCategory.procedures:
        return isRTL ? 'الإجراءات' : 'Procedures';
      case DocumentCategory.forms:
        return isRTL ? 'النماذج' : 'Forms';
      case DocumentCategory.general:
        return isRTL ? 'عام' : 'General';
    }
  }

  IconData _getCategoryIcon(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.reports:
        return Icons.assessment;
      case DocumentCategory.policies:
        return Icons.policy;
      case DocumentCategory.procedures:
        return Icons.list_alt;
      case DocumentCategory.forms:
        return Icons.article;
      case DocumentCategory.general:
        return Icons.description;
    }
  }

  Color _getCategoryColor(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.reports:
        return AppColors.gentlePurple;
      case DocumentCategory.policies:
        return AppColors.gentleOrange;
      case DocumentCategory.procedures:
        return AppColors.gentleGreen;
      case DocumentCategory.forms:
        return AppColors.gentlePink;
      case DocumentCategory.general:
        return AppColors.primaryColor;
    }
  }

  IconData _getStatusIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Icons.schedule;
      case RequestStatus.approved:
        return Icons.check_circle;
      case RequestStatus.rejected:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return AppColors.warningColor;
      case RequestStatus.approved:
        return AppColors.successColor;
      case RequestStatus.rejected:
        return AppColors.errorColor;
    }
  }

  String _getStatusText(RequestStatus status, bool isRTL) {
    switch (status) {
      case RequestStatus.pending:
        return isRTL ? 'معلق' : 'Pending';
      case RequestStatus.approved:
        return isRTL ? 'مقبول' : 'Approved';
      case RequestStatus.rejected:
        return isRTL ? 'مرفوض' : 'Rejected';
    }
  }

  void _handleDocumentAction(String action, DocumentModel document, currentUser, bool isRTL) async {
    switch (action) {
      case 'view':
      case 'download':
        await _openDocument(document.fileUrl);
        break;
      case 'request':
        await _showRequestAccessDialog(document, currentUser, isRTL);
        break;
    }
  }

  void _handleRequestAction(String action, DocumentRequestModel request, bool isRTL) async {
    final currentUser = Provider.of<app_auth.AuthProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    switch (action) {
      case 'approve':
        await _documentService.approveDocumentRequest(
          requestId: request.id,
          approvedById: currentUser.id,
          approvedByName: currentUser.fullName,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isRTL ? 'تم قبول الطلب' : 'Request approved'),
              backgroundColor: AppColors.successColor,
            ),
          );
        }
        break;
      case 'reject':
        await _showRejectDialog(request, currentUser, isRTL);
        break;
    }
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showRequestAccessDialog(DocumentModel document, currentUser, bool isRTL) async {
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'طلب الوصول للوثيقة' : 'Request Document Access'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${isRTL ? 'الوثيقة' : 'Document'}: ${document.title}',
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: isRTL ? 'سبب الطلب' : 'Reason for request',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRTL ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isNotEmpty) {
                await _documentService.requestDocumentAccess(
                  documentId: document.id,
                  documentTitle: document.title,
                  requesterId: currentUser.id,
                  requesterName: currentUser.fullName,
                  reason: reasonController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isRTL ? 'تم إرسال الطلب' : 'Request sent'),
                      backgroundColor: AppColors.successColor,
                    ),
                  );
                }
              }
            },
            child: Text(isRTL ? 'إرسال' : 'Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRejectDialog(DocumentRequestModel request, currentUser, bool isRTL) async {
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'رفض الطلب' : 'Reject Request'),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: isRTL ? 'سبب الرفض' : 'Rejection reason',
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRTL ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isNotEmpty) {
                await _documentService.rejectDocumentRequest(
                  requestId: request.id,
                  rejectionReason: reasonController.text.trim(),
                  approvedById: currentUser.id,
                  approvedByName: currentUser.fullName,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isRTL ? 'تم رفض الطلب' : 'Request rejected'),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
            child: Text(isRTL ? 'رفض' : 'Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUploadDocumentDialog(currentUser, bool isRTL) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DocumentCategory selectedCategory = DocumentCategory.general;
    List<String> selectedRoles = [];
    List<String> selectedDepartments = [];
    PlatformFile? selectedFile;
    bool isUploading = false;

    final size = MediaQuery.of(context).size;
    final isWeb = kIsWeb || size.width > 800;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isRTL ? 'رفع وثيقة جديدة' : 'Upload New Document'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: isWeb ? 600 : double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title field
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: isRTL ? 'عنوان الوثيقة *' : 'Document Title *',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description field
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: isRTL ? 'الوصف' : 'Description',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Category dropdown
                  DropdownButtonFormField<DocumentCategory>(
                    value: selectedCategory,
                    decoration: InputDecoration(
                      labelText: isRTL ? 'الفئة *' : 'Category *',
                      border: const OutlineInputBorder(),
                    ),
                    items: DocumentCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(_getCategoryName(category, isRTL)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCategory = value ?? DocumentCategory.general;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // File picker
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.attach_file),
                      title: Text(
                        selectedFile != null
                            ? selectedFile!.name
                            : (isRTL ? 'اختر ملف *' : 'Choose File *'),
                      ),
                      subtitle: selectedFile != null
                          ? Text('${(selectedFile!.size / 1024).toStringAsFixed(2)} KB')
                          : null,
                      trailing: const Icon(Icons.upload_file),
                      onTap: () async {
                        try {
                          if (kIsWeb) {
                            // Use HTML file input for web
                            final uploadInput = html.FileUploadInputElement();
                            uploadInput.accept = '.pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.txt';
                            uploadInput.click();

                            await uploadInput.onChange.first;

                            if (uploadInput.files!.isNotEmpty) {
                              final file = uploadInput.files![0];
                              final reader = html.FileReader();
                              reader.readAsArrayBuffer(file);

                              await reader.onLoad.first;

                              final bytes = reader.result as Uint8List;
                              final fileName = file.name;
                              final fileSize = file.size;
                              final extension = fileName.split('.').last;

                              setDialogState(() {
                                selectedFile = PlatformFile(
                                  name: fileName,
                                  size: fileSize,
                                  bytes: bytes,
                                  path: null,
                                );
                              });
                            }
                          } else {
                            // For mobile, use file_picker
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'],
                            );

                            if (result != null && result.files.isNotEmpty) {
                              setDialogState(() {
                                selectedFile = result.files.first;
                              });
                            }
                          }
                        } catch (e) {
                          print('Error picking file: $e');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isRTL
                                      ? 'فشل في اختيار الملف: $e'
                                      : 'Failed to pick file: $e',
                                ),
                                backgroundColor: AppColors.errorColor,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Allowed Roles (optional)
                  Text(
                    isRTL ? 'السماح للأدوار (اختياري):' : 'Allowed Roles (optional):',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['super_admin', 'admin', 'hr', 'manager', 'employee'].map((role) {
                      return FilterChip(
                        label: Text(_getRoleDisplayName(role, isRTL)),
                        selected: selectedRoles.contains(role),
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedRoles.add(role);
                            } else {
                              selectedRoles.remove(role);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Allowed Departments (optional)
                  Text(
                    isRTL ? 'السماح للأقسام (اختياري):' : 'Allowed Departments (optional):',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: AppConstants.departments.map((dept) {
                      return FilterChip(
                        label: Text(dept),
                        selected: selectedDepartments.contains(dept),
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedDepartments.add(dept);
                            } else {
                              selectedDepartments.remove(dept);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    isRTL
                        ? 'ملاحظة: إذا لم تختر أدوار أو أقسام، ستكون الوثيقة متاحة للجميع'
                        : 'Note: If no roles or departments selected, document will be available to everyone',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  if (isUploading) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        isRTL ? 'جاري رفع الوثيقة...' : 'Uploading document...',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context),
              child: Text(isRTL ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isRTL ? 'الرجاء إدخال عنوان الوثيقة' : 'Please enter document title',
                            ),
                            backgroundColor: AppColors.errorColor,
                          ),
                        );
                        return;
                      }

                      if (selectedFile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isRTL ? 'الرجاء اختيار ملف' : 'Please select a file',
                            ),
                            backgroundColor: AppColors.errorColor,
                          ),
                        );
                        return;
                      }

                      setDialogState(() {
                        isUploading = true;
                      });

                      try {
                        await _documentService.uploadDocument(
                          title: titleController.text.trim(),
                          description: descriptionController.text.trim(),
                          filePath: !kIsWeb ? selectedFile!.path : null,
                          fileBytes: kIsWeb ? selectedFile!.bytes : null,
                          fileName: selectedFile!.name,
                          fileType: selectedFile!.extension ?? '',
                          fileSize: selectedFile!.size.toDouble(),
                          uploadedById: currentUser.id,
                          uploadedByName: currentUser.fullName,
                          allowedRoles: selectedRoles,
                          allowedDepartments: selectedDepartments,
                          category: selectedCategory,
                        );

                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isRTL ? 'تم رفع الوثيقة بنجاح' : 'Document uploaded successfully',
                              ),
                              backgroundColor: AppColors.successColor,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() {
                          isUploading = false;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isRTL
                                    ? 'فشل رفع الوثيقة: $e'
                                    : 'Failed to upload document: $e',
                              ),
                              backgroundColor: AppColors.errorColor,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
              child: Text(
                isRTL ? 'رفع' : 'Upload',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleDisplayName(String role, bool isRTL) {
    switch (role) {
      case 'super_admin':
        return isRTL ? 'مسؤول عام' : 'Super Admin';
      case 'admin':
        return isRTL ? 'مسؤول' : 'Admin';
      case 'hr':
        return isRTL ? 'موارد بشرية' : 'HR';
      case 'manager':
        return isRTL ? 'مدير' : 'Manager';
      case 'employee':
        return isRTL ? 'موظف' : 'Employee';
      default:
        return role;
    }
  }
}