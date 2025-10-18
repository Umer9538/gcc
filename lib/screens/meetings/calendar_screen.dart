import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../constants/app_constants.dart';
import '../../services/meeting_service.dart';
import '../../services/user_service.dart';
import '../../models/meeting_model.dart';
import '../../models/user_model.dart';
import '../../widgets/calendar_widget.dart';
import '../../widgets/quick_meeting_dialog.dart';
import '../../utils/date_utils.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final MeetingService _meetingService = MeetingService();
  final UserService _userService = UserService();
  DateTime _selectedDate = DateTime.now();
  List<MeetingModel> _selectedDateMeetings = [];

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, app_auth.AuthProvider>(
      builder: (context, appProvider, authProvider, child) {
        final isRTL = appProvider.isRTL;
        final currentUser = authProvider.currentUser;

        if (currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            title: Text(
              isRTL ? 'التقويم' : 'Calendar',
              style: AppTextStyles.heading2.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.primaryColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.today),
                onPressed: _goToToday,
                tooltip: isRTL ? 'اليوم' : 'Today',
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showCreateMeetingDialog(context, isRTL, currentUser),
                tooltip: isRTL ? 'إضافة اجتماع' : 'Add Meeting',
              ),
            ],
          ),
          body: Column(
            children: [
              // Calendar Widget
              Expanded(
                flex: 2,
                child: StreamBuilder<List<MeetingModel>>(
                  stream: _meetingService.getUserMeetings(currentUser.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final meetings = snapshot.data ?? [];

                    return CalendarWidget(
                      meetings: meetings,
                      selectedDate: _selectedDate,
                      onDateSelected: _onDateSelected,
                      onMeetingTapped: _onMeetingTapped,
                      onCreateMeeting: (date) => _showCreateMeetingDialog(
                        context,
                        isRTL,
                        currentUser,
                        selectedDate: date,
                      ),
                    );
                  },
                ),
              ),

              // Selected Date Meetings
              Container(
                height: 1,
                color: AppColors.borderColor,
              ),
              Expanded(
                flex: 1,
                child: _buildSelectedDateMeetings(isRTL),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedDateMeetings(bool isRTL) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isRTL
                    ? 'اجتماعات ${AppDateUtils.formatDate(_selectedDate)}'
                    : 'Meetings for ${AppDateUtils.formatDate(_selectedDate)}',
                style: AppTextStyles.heading3,
              ),
              Text(
                '${_selectedDateMeetings.length}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Expanded(
            child: _selectedDateMeetings.isEmpty
                ? _buildEmptyMeetings(isRTL)
                : ListView.builder(
                    itemCount: _selectedDateMeetings.length,
                    itemBuilder: (context, index) {
                      final meeting = _selectedDateMeetings[index];
                      return _buildMeetingCard(meeting, isRTL);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMeetings(bool isRTL) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 48,
            color: AppColors.textLightColor,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            isRTL ? 'لا توجد اجتماعات في هذا اليوم' : 'No meetings on this date',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          TextButton.icon(
            onPressed: () => _showCreateMeetingDialog(
              context,
              isRTL,
              Provider.of<app_auth.AuthProvider>(context, listen: false).currentUser!,
              selectedDate: _selectedDate,
            ),
            icon: const Icon(Icons.add),
            label: Text(isRTL ? 'إضافة اجتماع' : 'Add Meeting'),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(MeetingModel meeting, bool isRTL) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: Container(
          width: 4,
          height: double.infinity,
          decoration: BoxDecoration(
            color: _getMeetingStatusColor(meeting.status),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(
          meeting.title,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${AppDateUtils.formatTime(meeting.startTime)} - ${AppDateUtils.formatTime(meeting.endTime)}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
            if (meeting.location.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      meeting.location,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: AppColors.textSecondaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${meeting.attendeeIds.length} ${isRTL ? 'مشارك' : 'attendees'}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMeetingAction(value, meeting, isRTL),
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
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit),
                  const SizedBox(width: 8),
                  Text(isRTL ? 'تعديل' : 'Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: AppColors.errorColor),
                  const SizedBox(width: 8),
                  Text(
                    isRTL ? 'حذف' : 'Delete',
                    style: const TextStyle(color: AppColors.errorColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _onMeetingTapped(meeting),
      ),
    );
  }

  Color _getMeetingStatusColor(MeetingStatus status) {
    switch (status) {
      case MeetingStatus.scheduled:
        return AppColors.primaryColor;
      case MeetingStatus.inProgress:
        return AppColors.warningColor;
      case MeetingStatus.completed:
        return AppColors.successColor;
      case MeetingStatus.cancelled:
        return AppColors.errorColor;
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadMeetingsForDate(date);
  }

  void _loadMeetingsForDate(DateTime date) {
    final currentUser = Provider.of<app_auth.AuthProvider>(context, listen: false).currentUser;
    if (currentUser == null) return;

    _meetingService.getUserMeetings(currentUser.id).listen((meetings) {
      final filteredMeetings = meetings.where((meeting) {
        return meeting.startTime.year == date.year &&
            meeting.startTime.month == date.month &&
            meeting.startTime.day == date.day;
      }).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      if (mounted) {
        setState(() {
          _selectedDateMeetings = filteredMeetings;
        });
      }
    });
  }

  void _onMeetingTapped(MeetingModel meeting) {
    _showMeetingDetailsDialog(meeting);
  }

  void _showMeetingDetailsDialog(MeetingModel meeting) {
    final isRTL = Provider.of<AppProvider>(context, listen: false).isRTL;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(meeting.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              icon: Icons.description,
              label: isRTL ? 'الوصف' : 'Description',
              value: meeting.description.isEmpty
                  ? (isRTL ? 'لا يوجد وصف' : 'No description')
                  : meeting.description,
            ),
            _buildDetailRow(
              icon: Icons.access_time,
              label: isRTL ? 'الوقت' : 'Time',
              value: '${AppDateUtils.formatTime(meeting.startTime)} - ${AppDateUtils.formatTime(meeting.endTime)}',
            ),
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: isRTL ? 'التاريخ' : 'Date',
              value: AppDateUtils.formatDate(meeting.startTime),
            ),
            if (meeting.location.isNotEmpty)
              _buildDetailRow(
                icon: Icons.location_on,
                label: isRTL ? 'المكان' : 'Location',
                value: meeting.location,
              ),
            _buildDetailRow(
              icon: Icons.person,
              label: isRTL ? 'المنظم' : 'Organizer',
              value: meeting.organizerName,
            ),
            _buildDetailRow(
              icon: Icons.people,
              label: isRTL ? 'المشاركون' : 'Attendees',
              value: '${meeting.attendeeIds.length} ${isRTL ? 'مشارك' : 'attendees'}',
            ),
          ],
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
                    fontWeight: FontWeight.bold,
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

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
    _loadMeetingsForDate(DateTime.now());
  }

  void _handleMeetingAction(String action, MeetingModel meeting, bool isRTL) {
    switch (action) {
      case 'view':
        _showMeetingDetailsDialog(meeting);
        break;
      case 'edit':
        _showEditMeetingDialog(meeting, isRTL);
        break;
      case 'delete':
        _showDeleteMeetingDialog(meeting, isRTL);
        break;
    }
  }

  void _showEditMeetingDialog(MeetingModel meeting, bool isRTL) {
    // TODO: Implement edit meeting dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isRTL ? 'تعديل الاجتماع قريباً' : 'Edit meeting coming soon'),
      ),
    );
  }

  void _showDeleteMeetingDialog(MeetingModel meeting, bool isRTL) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRTL ? 'حذف الاجتماع' : 'Delete Meeting'),
        content: Text(
          isRTL
              ? 'هل أنت متأكد من حذف "${meeting.title}"؟'
              : 'Are you sure you want to delete "${meeting.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isRTL ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _meetingService.deleteMeeting(meeting.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isRTL ? 'تم حذف الاجتماع' : 'Meeting deleted'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isRTL ? 'فشل في حذف الاجتماع' : 'Failed to delete meeting'),
                    ),
                  );
                }
              }
            },
            child: Text(
              isRTL ? 'حذف' : 'Delete',
              style: const TextStyle(color: AppColors.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateMeetingDialog(
    BuildContext context,
    bool isRTL,
    UserModel currentUser, {
    DateTime? selectedDate,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => QuickMeetingDialog(
        currentUser: currentUser,
        selectedDate: selectedDate ?? _selectedDate,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isRTL ? 'تم إنشاء الاجتماع بنجاح' : 'Meeting created successfully'),
        ),
      );
      // Refresh the meetings for the selected date
      _loadMeetingsForDate(_selectedDate);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMeetingsForDate(_selectedDate);
    });
  }
}