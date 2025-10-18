import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../constants/app_constants.dart';
import '../../services/document_service.dart';
import '../../models/document_model.dart';
import '../../utils/date_utils.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
              tabs: [
                Tab(text: isRTL ? 'المتاحة' : 'Available'),
                Tab(text: isRTL ? 'الطلبات' : 'Requests'),
                Tab(text: isRTL ? 'الإحصائيات' : 'Stats'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAvailableDocumentsTab(userId, currentUser, isRTL),
              _buildRequestsTab(userId, currentUser, isRTL),
              _buildStatsTab(userId, currentUser, isRTL),
            ],
          ),
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
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
    return StreamBuilder<List<DocumentRequestModel>>(
      stream: _documentService.getUserDocumentRequests(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
    return StreamBuilder<List<DocumentRequestModel>>(
      stream: _documentService.getPendingRequestsForUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
    return FutureBuilder<Map<String, int>>(
      future: _documentService.getDocumentStats(
        userId: userId,
        userDepartment: currentUser?.department ?? '',
        userRoles: currentUser?.roles ?? [],
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
}