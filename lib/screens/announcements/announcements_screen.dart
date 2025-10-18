import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../constants/app_constants.dart';
import '../../services/announcement_service.dart';
import '../../services/user_service.dart';
import '../../models/announcement_model.dart';
import '../../models/user_model.dart';
import '../../utils/date_utils.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final AnnouncementService _announcementService = AnnouncementService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  AnnouncementPriority? _selectedPriority;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
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
              isRTL ? 'الإعلانات' : 'Announcements',
              style: AppTextStyles.heading2.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.primaryColor,
            actions: [
              if (currentUser?.roles.contains('admin') ?? false)
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showCreateAnnouncementDialog(context, isRTL, currentUser),
                ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterDialog(context, isRTL),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: isRTL ? 'البحث في الإعلانات...' : 'Search announcements...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                      borderSide: const BorderSide(color: AppColors.borderColor),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceColor,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),

                // Priority filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        isRTL ? 'الكل' : 'All',
                        _selectedPriority == null,
                        AppColors.primaryColor,
                        onSelected: () {
                          setState(() {
                            _selectedPriority = null;
                          });
                        },
                      ),
                      const SizedBox(width: AppConstants.smallPadding),
                      _buildFilterChip(
                        isRTL ? 'عاجل' : 'High',
                        _selectedPriority == AnnouncementPriority.high,
                        Colors.red,
                        onSelected: () {
                          setState(() {
                            _selectedPriority = AnnouncementPriority.high;
                          });
                        },
                      ),
                      const SizedBox(width: AppConstants.smallPadding),
                      _buildFilterChip(
                        isRTL ? 'عادي' : 'Normal',
                        _selectedPriority == AnnouncementPriority.normal,
                        AppColors.primaryColor,
                        onSelected: () {
                          setState(() {
                            _selectedPriority = AnnouncementPriority.normal;
                          });
                        },
                      ),
                      const SizedBox(width: AppConstants.smallPadding),
                      _buildFilterChip(
                        isRTL ? 'منخفض' : 'Low',
                        _selectedPriority == AnnouncementPriority.low,
                        Colors.grey,
                        onSelected: () {
                          setState(() {
                            _selectedPriority = AnnouncementPriority.low;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),

                // Announcements list
                Expanded(
                  child: StreamBuilder<List<AnnouncementModel>>(
                    stream: _announcementService.getAnnouncementsForUser(
                      userId: userId,
                      userDepartment: currentUser?.department ?? '',
                      userRoles: currentUser?.roles ?? [],
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState(isRTL);
                      }

                      var announcements = snapshot.data!;

                      // Apply filters
                      if (_selectedPriority != null) {
                        announcements = announcements
                            .where((a) => a.priority == _selectedPriority)
                            .toList();
                      }

                      if (_searchQuery.isNotEmpty) {
                        announcements = announcements
                            .where((a) =>
                                a.title.toLowerCase().contains(_searchQuery) ||
                                a.content.toLowerCase().contains(_searchQuery))
                            .toList();
                      }

                      if (announcements.isEmpty) {
                        return _buildEmptyState(isRTL, isFiltered: true);
                      }

                      return ListView.builder(
                        itemCount: announcements.length,
                        itemBuilder: (context, index) {
                          final announcement = announcements[index];
                          final isRead = announcement.readBy.contains(userId);

                          return Card(
                            margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
                            elevation: isRead ? 1 : 3,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getPriorityColor(announcement.priority).withOpacity(0.1),
                                child: Icon(
                                  _getPriorityIcon(announcement.priority),
                                  color: _getPriorityColor(announcement.priority),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      announcement.title,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isRTL ? 'جديد' : 'NEW',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
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
                                    announcement.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.person_outline, size: 12, color: AppColors.textLightColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        announcement.authorName,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textLightColor,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(Icons.access_time, size: 12, color: AppColors.textLightColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppDateUtils.formatDate(announcement.createdAt),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textLightColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () => _showAnnouncementDetails(context, announcement, isRTL, userId),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: (currentUser?.roles.contains('admin') ?? false)
              ? FloatingActionButton(
                  onPressed: () => _showCreateAnnouncementDialog(context, isRTL, currentUser),
                  backgroundColor: AppColors.primaryColor,
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, Color color, {required VoidCallback onSelected}) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : AppColors.textSecondaryColor,
      ),
    );
  }

  Widget _buildEmptyState(bool isRTL, {bool isFiltered = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: AppColors.textLightColor,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            isFiltered
                ? (isRTL ? 'لا توجد نتائج' : 'No results found')
                : (isRTL ? 'لا توجد إعلانات' : 'No announcements'),
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textSecondaryColor,
            ),
          ),
          if (!isFiltered) ...[
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              isRTL
                  ? 'سيتم عرض الإعلانات هنا'
                  : 'Announcements will appear here',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Color _getPriorityColor(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.urgent:
        return Colors.red;
      case AnnouncementPriority.high:
        return Colors.orange;
      case AnnouncementPriority.normal:
        return AppColors.primaryColor;
      case AnnouncementPriority.low:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(AnnouncementPriority priority) {
    switch (priority) {
      case AnnouncementPriority.urgent:
        return Icons.warning;
      case AnnouncementPriority.high:
        return Icons.priority_high;
      case AnnouncementPriority.normal:
        return Icons.announcement;
      case AnnouncementPriority.low:
        return Icons.info_outline;
    }
  }

  void _showAnnouncementDetails(BuildContext context, AnnouncementModel announcement, bool isRTL, String userId) async {
    // Mark as read
    if (!announcement.readBy.contains(userId)) {
      await _announcementService.markAnnouncementAsRead(announcement.id, userId);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getPriorityIcon(announcement.priority),
              color: _getPriorityColor(announcement.priority),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(announcement.title),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                announcement.content,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: AppColors.textLightColor),
                  const SizedBox(width: 4),
                  Text(
                    announcement.authorName,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLightColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.textLightColor),
                  const SizedBox(width: 4),
                  Text(
                    AppDateUtils.formatDate(announcement.createdAt),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLightColor,
                    ),
                  ),
                ],
              ),
              if (announcement.expiryDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer_off, size: 16, color: AppColors.textLightColor),
                    const SizedBox(width: 4),
                    Text(
                      '${isRTL ? "ينتهي في" : "Expires on"} ${AppDateUtils.formatDate(announcement.expiryDate!)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLightColor,
                      ),
                    ),
                  ],
                ),
              ],
              if (announcement.targetGroups.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: announcement.targetGroups.map((group) {
                    return Chip(
                      label: Text(
                        group,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
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

  void _showCreateAnnouncementDialog(BuildContext context, bool isRTL, UserModel? currentUser) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    AnnouncementPriority priority = AnnouncementPriority.normal;
    List<String> selectedGroups = ['all'];
    List<String> selectedDepartments = [];
    DateTime? expiryDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isRTL ? 'إنشاء إعلان جديد' : 'Create New Announcement'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: isRTL ? 'العنوان' : 'Title',
                      prefixIcon: const Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    decoration: InputDecoration(
                      labelText: isRTL ? 'المحتوى' : 'Content',
                      prefixIcon: const Icon(Icons.description),
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<AnnouncementPriority>(
                    value: priority,
                    decoration: InputDecoration(
                      labelText: isRTL ? 'الأولوية' : 'Priority',
                      prefixIcon: const Icon(Icons.priority_high),
                    ),
                    items: AnnouncementPriority.values.map((p) {
                      String label;
                      switch (p) {
                        case AnnouncementPriority.urgent:
                          label = isRTL ? 'طارئ' : 'Urgent';
                          break;
                        case AnnouncementPriority.high:
                          label = isRTL ? 'عاجل' : 'High';
                          break;
                        case AnnouncementPriority.normal:
                          label = isRTL ? 'عادي' : 'Normal';
                          break;
                        case AnnouncementPriority.low:
                          label = isRTL ? 'منخفض' : 'Low';
                          break;
                      }
                      return DropdownMenuItem(
                        value: p,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        priority = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(isRTL ? 'تاريخ الانتهاء (اختياري)' : 'Expiry Date (Optional)'),
                    subtitle: Text(
                      expiryDate != null
                          ? AppDateUtils.formatDate(expiryDate!)
                          : (isRTL ? 'غير محدد' : 'Not set'),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          expiryDate = date;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isRTL ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isRTL ? 'يرجى ملء جميع الحقول المطلوبة' : 'Please fill all required fields'),
                    ),
                  );
                  return;
                }

                try {
                  await _announcementService.createAnnouncement(
                    title: titleController.text,
                    content: contentController.text,
                    authorId: currentUser?.id ?? '',
                    authorName: currentUser?.fullName ?? 'Admin',
                    targetGroups: selectedGroups,
                    targetDepartments: selectedDepartments,
                    priority: priority,
                    expiryDate: expiryDate,
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isRTL ? 'تم إنشاء الإعلان بنجاح' : 'Announcement created successfully'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isRTL ? 'حدث خطأ في إنشاء الإعلان' : 'Error creating announcement'),
                    ),
                  );
                }
              },
              child: Text(isRTL ? 'إنشاء' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, bool isRTL) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'خيارات التصفية' : 'Filter Options'),
        content: Text(isRTL ? 'قريباً...' : 'Coming soon...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRTL ? 'إغلاق' : 'Close'),
          ),
        ],
      ),
    );
  }
}