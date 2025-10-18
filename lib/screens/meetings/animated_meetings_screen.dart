import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../constants/app_constants.dart';
import '../../services/meeting_service.dart';
import '../../services/user_service.dart';
import '../../models/meeting_model.dart';
import '../../models/user_model.dart';
import '../../utils/date_utils.dart';
import 'calendar_screen.dart';

class AnimatedMeetingsScreen extends StatefulWidget {
  const AnimatedMeetingsScreen({super.key});

  @override
  State<AnimatedMeetingsScreen> createState() => _AnimatedMeetingsScreenState();
}

class _AnimatedMeetingsScreenState extends State<AnimatedMeetingsScreen> with SingleTickerProviderStateMixin {
  final MeetingService _meetingService = MeetingService();
  final UserService _userService = UserService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = kIsWeb || size.width > 800;

    return Consumer2<AppProvider, app_auth.AuthProvider>(
      builder: (context, appProvider, authProvider, child) {
        final isRTL = appProvider.isRTL;
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final currentUser = authProvider.currentUser;

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            title: FadeIn(
              child: Text(
                isRTL ? 'الاجتماعات' : 'Meetings',
                style: AppTextStyles.heading2.copyWith(color: Colors.white),
              ),
            ),
            backgroundColor: AppColors.primaryColor,
            actions: [
              FadeIn(
                delay: const Duration(milliseconds: 200),
                child: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showCreateMeetingDialog(context, isRTL, currentUser),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              isScrollable: true,
              tabs: [
                Tab(text: isRTL ? 'القادمة' : 'Upcoming'),
                Tab(text: isRTL ? 'اليوم' : 'Today'),
                Tab(text: isRTL ? 'السابقة' : 'Past'),
                Tab(text: isRTL ? 'التقويم' : 'Calendar'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildUpcomingMeetings(userId, isRTL, isWeb),
              _buildTodayMeetings(userId, isRTL, isWeb),
              _buildPastMeetings(userId, isRTL, isWeb),
              const CalendarScreen(),
            ],
          ),
          floatingActionButton: FadeInUp(
            delay: const Duration(milliseconds: 500),
            child: FloatingActionButton(
              onPressed: () => _showCreateMeetingDialog(context, isRTL, currentUser),
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingMeetings(String userId, bool isRTL, bool isWeb) {
    return StreamBuilder<List<MeetingModel>>(
      stream: _meetingService.getUpcomingMeetingsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer(isWeb);
        }

        if (snapshot.hasError) {
          return FadeIn(
            child: Center(
              child: Text(
                isRTL ? 'حدث خطأ في تحميل الاجتماعات' : 'Error loading meetings',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(isRTL, 'upcoming', isWeb);
        }

        return _buildMeetingsList(snapshot.data!, isRTL, isWeb);
      },
    );
  }

  Widget _buildTodayMeetings(String userId, bool isRTL, bool isWeb) {
    return StreamBuilder<List<MeetingModel>>(
      stream: _meetingService.getTodaysMeetingsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer(isWeb);
        }

        if (snapshot.hasError) {
          return FadeIn(
            child: Center(
              child: Text(
                isRTL ? 'حدث خطأ في تحميل الاجتماعات' : 'Error loading meetings',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(isRTL, 'today', isWeb);
        }

        return _buildMeetingsList(snapshot.data!, isRTL, isWeb);
      },
    );
  }

  Widget _buildPastMeetings(String userId, bool isRTL, bool isWeb) {
    return StreamBuilder<List<MeetingModel>>(
      stream: _meetingService.getPastMeetingsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer(isWeb);
        }

        if (snapshot.hasError) {
          return FadeIn(
            child: Center(
              child: Text(
                isRTL ? 'حدث خطأ في تحميل الاجتماعات' : 'Error loading meetings',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(isRTL, 'past', isWeb);
        }

        return _buildMeetingsList(snapshot.data!, isRTL, isWeb);
      },
    );
  }

  Widget _buildMeetingsList(List<MeetingModel> meetings, bool isRTL, bool isWeb) {
    return AnimationLimiter(
      child: ListView.builder(
        padding: EdgeInsets.all(isWeb ? 24 : 16),
        itemCount: meetings.length,
        itemBuilder: (context, index) {
          final meeting = meetings[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              horizontalOffset: 50,
              child: FadeInAnimation(
                child: _buildMeetingCard(meeting, isRTL, isWeb),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeetingCard(MeetingModel meeting, bool isRTL, bool isWeb) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Card(
        margin: EdgeInsets.only(bottom: isWeb ? 20 : 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
        ),
        child: InkWell(
          onTap: () => _showMeetingDetails(context, meeting, isRTL),
          borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
          child: Padding(
            padding: EdgeInsets.all(isWeb ? 20 : 16),
            child: Row(
              children: [
                Container(
                  width: isWeb ? 60 : 50,
                  height: isWeb ? 60 : 50,
                  decoration: BoxDecoration(
                    color: _getStatusColor(meeting.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                  ),
                  child: Icon(
                    Icons.event,
                    color: _getStatusColor(meeting.status),
                    size: isWeb ? 30 : 24,
                  ),
                ),
                SizedBox(width: isWeb ? 20 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isWeb ? 18 : 16,
                          color: AppColors.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: isWeb ? 8 : 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: isWeb ? 16 : 14,
                            color: AppColors.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${AppDateUtils.formatDate(meeting.startTime)} • ${AppDateUtils.formatTime(meeting.startTime)} - ${AppDateUtils.formatTime(meeting.endTime)}',
                              style: TextStyle(
                                fontSize: isWeb ? 14 : 12,
                                color: AppColors.textSecondaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isWeb ? 6 : 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: isWeb ? 16 : 14,
                            color: AppColors.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              meeting.location,
                              style: TextStyle(
                                fontSize: isWeb ? 14 : 12,
                                color: AppColors.textSecondaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isWeb ? 6 : 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: isWeb ? 16 : 14,
                            color: AppColors.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              meeting.organizerName,
                              style: TextStyle(
                                fontSize: isWeb ? 14 : 12,
                                color: AppColors.textSecondaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'view') {
                      _showMeetingDetails(context, meeting, isRTL);
                    } else if (value == 'delete') {
                      _deleteMeeting(meeting.id, isRTL);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          const Icon(Icons.visibility_outlined, size: 20),
                          const SizedBox(width: 12),
                          Text(isRTL ? 'عرض التفاصيل' : 'View Details'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          const SizedBox(width: 12),
                          Text(
                            isRTL ? 'حذف' : 'Delete',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isWeb) {
    return ListView.builder(
      padding: EdgeInsets.all(isWeb ? 24 : 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: EdgeInsets.only(bottom: isWeb ? 20 : 16),
            child: Container(
              padding: EdgeInsets.all(isWeb ? 20 : 16),
              child: Row(
                children: [
                  Container(
                    width: isWeb ? 60 : 50,
                    height: isWeb ? 60 : 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                    ),
                  ),
                  SizedBox(width: isWeb ? 20 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: isWeb ? 18 : 16,
                          width: double.infinity,
                          color: Colors.white,
                        ),
                        SizedBox(height: isWeb ? 8 : 6),
                        Container(
                          height: isWeb ? 14 : 12,
                          width: 200,
                          color: Colors.white,
                        ),
                        SizedBox(height: isWeb ? 6 : 4),
                        Container(
                          height: isWeb ? 14 : 12,
                          width: 150,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isRTL, String type, bool isWeb) {
    String message;
    switch (type) {
      case 'upcoming':
        message = isRTL ? 'لا توجد اجتماعات قادمة' : 'No upcoming meetings';
        break;
      case 'today':
        message = isRTL ? 'لا توجد اجتماعات اليوم' : 'No meetings today';
        break;
      case 'past':
        message = isRTL ? 'لا توجد اجتماعات سابقة' : 'No past meetings';
        break;
      default:
        message = isRTL ? 'لا توجد اجتماعات' : 'No meetings';
    }

    return FadeIn(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: isWeb ? 80 : 64,
              color: AppColors.textLightColor,
            ),
            SizedBox(height: isWeb ? 24 : 20),
            Text(
              message,
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryColor,
              ),
            ),
            SizedBox(height: isWeb ? 12 : 8),
            Text(
              isRTL
                  ? 'انقر على + لإنشاء اجتماع جديد'
                  : 'Tap + to create a new meeting',
              style: TextStyle(
                fontSize: isWeb ? 16 : 14,
                color: AppColors.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(MeetingStatus status) {
    switch (status) {
      case MeetingStatus.scheduled:
        return AppColors.primaryColor;
      case MeetingStatus.inProgress:
        return AppColors.gentleGreen;
      case MeetingStatus.completed:
        return Colors.grey;
      case MeetingStatus.cancelled:
        return Colors.red;
    }
  }

  void _showMeetingDetails(BuildContext context, MeetingModel meeting, bool isRTL) {
    showDialog(
      context: context,
      builder: (context) => FadeInDown(
        duration: const Duration(milliseconds: 300),
        child: AlertDialog(
          title: Text(meeting.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(
                  Icons.description,
                  isRTL ? 'الوصف' : 'Description',
                  meeting.description,
                ),
                _buildDetailRow(
                  Icons.calendar_today,
                  isRTL ? 'التاريخ' : 'Date',
                  AppDateUtils.formatDate(meeting.startTime),
                ),
                _buildDetailRow(
                  Icons.access_time,
                  isRTL ? 'الوقت' : 'Time',
                  '${AppDateUtils.formatTime(meeting.startTime)} - ${AppDateUtils.formatTime(meeting.endTime)}',
                ),
                _buildDetailRow(
                  Icons.location_on,
                  isRTL ? 'المكان' : 'Location',
                  meeting.location,
                ),
                _buildDetailRow(
                  Icons.person,
                  isRTL ? 'المنظم' : 'Organizer',
                  meeting.organizerName,
                ),
                _buildDetailRow(
                  Icons.people,
                  isRTL ? 'الحضور' : 'Attendees',
                  meeting.attendeeNames.join(', '),
                ),
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
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryColor,
                  ),
                ),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateMeetingDialog(BuildContext context, bool isRTL, UserModel? currentUser) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
    List<UserModel> selectedAttendees = [];

    showDialog(
      context: context,
      builder: (context) => FadeInDown(
        duration: const Duration(milliseconds: 300),
        child: StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(isRTL ? 'إنشاء اجتماع جديد' : 'Create New Meeting'),
            content: SingleChildScrollView(
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
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: isRTL ? 'الوصف' : 'Description',
                      prefixIcon: const Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: isRTL ? 'المكان' : 'Location',
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(isRTL ? 'التاريخ' : 'Date'),
                    subtitle: Text(AppDateUtils.formatDate(selectedDate)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text(isRTL ? 'وقت البداية' : 'Start Time'),
                    subtitle: Text(startTime.format(context)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (time != null) {
                        setState(() {
                          startTime = time;
                        });
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time_filled),
                    title: Text(isRTL ? 'وقت النهاية' : 'End Time'),
                    subtitle: Text(endTime.format(context)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (time != null) {
                        setState(() {
                          endTime = time;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(isRTL ? 'إلغاء' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty || locationController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isRTL ? 'يرجى ملء جميع الحقول المطلوبة' : 'Please fill all required fields'),
                      ),
                    );
                    return;
                  }

                  final startDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    startTime.hour,
                    startTime.minute,
                  );

                  final endDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    endTime.hour,
                    endTime.minute,
                  );

                  try {
                    await _meetingService.createMeeting(
                      title: titleController.text,
                      description: descriptionController.text,
                      startTime: startDateTime,
                      endTime: endDateTime,
                      location: locationController.text,
                      organizerId: currentUser?.id ?? '',
                      organizerName: currentUser?.fullName ?? 'Unknown',
                      attendeeIds: selectedAttendees.map((u) => u.id).toList(),
                      attendeeNames: selectedAttendees.map((u) => u.fullName).toList(),
                    );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isRTL ? 'تم إنشاء الاجتماع بنجاح' : 'Meeting created successfully'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isRTL ? 'حدث خطأ في إنشاء الاجتماع' : 'Error creating meeting'),
                      ),
                    );
                  }
                },
                child: Text(isRTL ? 'إنشاء' : 'Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteMeeting(String meetingId, bool isRTL) async {
    try {
      await _meetingService.deleteMeeting(meetingId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRTL ? 'تم حذف الاجتماع' : 'Meeting deleted'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRTL ? 'حدث خطأ في حذف الاجتماع' : 'Error deleting meeting'),
        ),
      );
    }
  }
}
