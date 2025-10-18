import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../constants/app_constants.dart';
import '../../services/meeting_service.dart';
import '../../services/user_service.dart';
import '../../models/meeting_model.dart';
import '../../models/user_model.dart';
import '../../utils/date_utils.dart';
import 'calendar_screen.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> with SingleTickerProviderStateMixin {
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
    return Consumer2<AppProvider, app_auth.AuthProvider>(
      builder: (context, appProvider, authProvider, child) {
        final isRTL = appProvider.isRTL;
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final currentUser = authProvider.currentUser;

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            title: Text(
              isRTL ? 'الاجتماعات' : 'Meetings',
              style: AppTextStyles.heading2.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.primaryColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showCreateMeetingDialog(context, isRTL, currentUser),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
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
              _buildUpcomingMeetings(userId, isRTL),
              _buildTodayMeetings(userId, isRTL),
              _buildPastMeetings(userId, isRTL),
              const CalendarScreen(),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateMeetingDialog(context, isRTL, currentUser),
            backgroundColor: AppColors.primaryColor,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingMeetings(String userId, bool isRTL) {
    return StreamBuilder<List<MeetingModel>>(
      stream: _meetingService.getUpcomingMeetingsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              isRTL ? 'حدث خطأ في تحميل الاجتماعات' : 'Error loading meetings',
              style: AppTextStyles.bodyMedium,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(isRTL, 'upcoming');
        }

        return _buildMeetingsList(snapshot.data!, isRTL);
      },
    );
  }

  Widget _buildTodayMeetings(String userId, bool isRTL) {
    return StreamBuilder<List<MeetingModel>>(
      stream: _meetingService.getTodaysMeetingsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              isRTL ? 'حدث خطأ في تحميل الاجتماعات' : 'Error loading meetings',
              style: AppTextStyles.bodyMedium,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(isRTL, 'today');
        }

        return _buildMeetingsList(snapshot.data!, isRTL);
      },
    );
  }

  Widget _buildPastMeetings(String userId, bool isRTL) {
    return StreamBuilder<List<MeetingModel>>(
      stream: _meetingService.getPastMeetingsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              isRTL ? 'حدث خطأ في تحميل الاجتماعات' : 'Error loading meetings',
              style: AppTextStyles.bodyMedium,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(isRTL, 'past');
        }

        return _buildMeetingsList(snapshot.data!, isRTL);
      },
    );
  }

  Widget _buildMeetingsList(List<MeetingModel> meetings, bool isRTL) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: meetings.length,
      itemBuilder: (context, index) {
        final meeting = meetings[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(meeting.status).withValues(alpha: 0.1),
              child: Icon(
                Icons.event,
                color: _getStatusColor(meeting.status),
              ),
            ),
            title: Text(
              meeting.title,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppDateUtils.formatDate(meeting.startTime)} • ${AppDateUtils.formatTime(meeting.startTime)} - ${AppDateUtils.formatTime(meeting.endTime)}',
                  style: AppTextStyles.bodySmall,
                ),
                Text(
                  '📍 ${meeting.location}',
                  style: AppTextStyles.bodySmall,
                ),
                Text(
                  '👤 ${meeting.organizerName}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
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
                  child: Text(isRTL ? 'عرض التفاصيل' : 'View Details'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(isRTL ? 'حذف' : 'Delete'),
                ),
              ],
            ),
            onTap: () => _showMeetingDetails(context, meeting, isRTL),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isRTL, String type) {
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

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 64,
            color: AppColors.textLightColor,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            message,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            isRTL
                ? 'انقر على + لإنشاء اجتماع جديد'
                : 'Tap + to create a new meeting',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
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
      builder: (context) => AlertDialog(
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
      builder: (context) => StatefulBuilder(
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