import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../constants/app_constants.dart';
import '../services/meeting_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class QuickMeetingDialog extends StatefulWidget {
  final UserModel currentUser;
  final DateTime? selectedDate;
  final DateTime? selectedTime;

  const QuickMeetingDialog({
    super.key,
    required this.currentUser,
    this.selectedDate,
    this.selectedTime,
  });

  @override
  State<QuickMeetingDialog> createState() => _QuickMeetingDialogState();
}

class _QuickMeetingDialogState extends State<QuickMeetingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final MeetingService _meetingService = MeetingService();
  final UserService _userService = UserService();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
  List<UserModel> _selectedAttendees = [];
  List<UserModel> _availableUsers = [];
  bool _isLoading = false;
  bool _setReminder = true;
  int _reminderMinutes = 15;

  @override
  void initState() {
    super.initState();

    // Initialize with provided date/time
    if (widget.selectedDate != null) {
      _selectedDate = widget.selectedDate!;
    }

    if (widget.selectedTime != null) {
      _startTime = TimeOfDay.fromDateTime(widget.selectedTime!);
      _endTime = TimeOfDay(
        hour: _startTime.hour + 1,
        minute: _startTime.minute,
      );
    }

    _loadUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userService.getAllUsersExcept(widget.currentUser.id);
      setState(() {
        _availableUsers = users;
      });
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final isRTL = appProvider.isRTL;

        return AlertDialog(
          title: Text(isRTL ? 'اجتماع سريع' : 'Quick Meeting'),
          content: SizedBox(
            width: double.maxFinite,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: isRTL ? 'عنوان الاجتماع *' : 'Meeting Title *',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return isRTL ? 'مطلوب عنوان الاجتماع' : 'Meeting title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: isRTL ? 'الوصف' : 'Description',
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),

                    // Date and Time
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text(isRTL ? 'التاريخ' : 'Date'),
                            subtitle: Text(_formatDate(_selectedDate, isRTL)),
                            leading: const Icon(Icons.calendar_today),
                            onTap: _selectDate,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text(isRTL ? 'وقت البداية' : 'Start Time'),
                            subtitle: Text(_startTime.format(context)),
                            leading: const Icon(Icons.access_time),
                            onTap: () => _selectTime(true),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(isRTL ? 'وقت النهاية' : 'End Time'),
                            subtitle: Text(_endTime.format(context)),
                            leading: const Icon(Icons.access_time_filled),
                            onTap: () => _selectTime(false),
                          ),
                        ),
                      ],
                    ),

                    // Location
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: isRTL ? 'المكان' : 'Location',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),

                    // Attendees
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderColor),
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isRTL ? 'المشاركون' : 'Attendees',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _showAttendeeSelector,
                                  icon: const Icon(Icons.add),
                                  label: Text(isRTL ? 'إضافة' : 'Add'),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedAttendees.isNotEmpty)
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: _selectedAttendees.length,
                                itemBuilder: (context, index) {
                                  final attendee = _selectedAttendees[index];
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
                                      child: Text(
                                        _getInitials(attendee.fullName),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    title: Text(
                                      attendee.fullName,
                                      style: AppTextStyles.bodySmall,
                                    ),
                                    subtitle: Text(
                                      attendee.department,
                                      style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () {
                                        setState(() {
                                          _selectedAttendees.removeAt(index);
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                isRTL ? 'لم يتم اختيار مشاركين' : 'No attendees selected',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),

                    // Reminder
                    Row(
                      children: [
                        Checkbox(
                          value: _setReminder,
                          onChanged: (value) {
                            setState(() {
                              _setReminder = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(isRTL ? 'تعيين تذكير' : 'Set reminder'),
                        ),
                        if (_setReminder)
                          DropdownButton<int>(
                            value: _reminderMinutes,
                            items: [5, 10, 15, 30, 60].map((minutes) {
                              return DropdownMenuItem(
                                value: minutes,
                                child: Text(
                                  isRTL
                                    ? '$minutes دقيقة قبل'
                                    : '$minutes min before',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _reminderMinutes = value ?? 15;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(isRTL ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _createMeeting,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isRTL ? 'إنشاء' : 'Create'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date, bool isRTL) {
    if (isRTL) {
      final months = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );

    if (time != null) {
      setState(() {
        if (isStartTime) {
          _startTime = time;
          // Auto-adjust end time to be at least 30 minutes after start
          final startMinutes = time.hour * 60 + time.minute;
          final endMinutes = _endTime.hour * 60 + _endTime.minute;

          if (endMinutes <= startMinutes) {
            _endTime = TimeOfDay(
              hour: (startMinutes + 30) ~/ 60,
              minute: (startMinutes + 30) % 60,
            );
          }
        } else {
          _endTime = time;
        }
      });
    }
  }

  void _showAttendeeSelector() {
    showDialog(
      context: context,
      builder: (context) => AttendeeSelectionDialog(
        availableUsers: _availableUsers,
        selectedUsers: _selectedAttendees,
        onSelectionChanged: (users) {
          setState(() {
            _selectedAttendees = users;
          });
        },
      ),
    );
  }

  Future<void> _createMeeting() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final reminderTime = _setReminder
          ? startDateTime.subtract(Duration(minutes: _reminderMinutes))
          : null;

      await _meetingService.createMeeting(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startTime: startDateTime,
        endTime: endDateTime,
        location: _locationController.text.trim(),
        organizerId: widget.currentUser.id,
        organizerName: widget.currentUser.fullName,
        attendeeIds: _selectedAttendees.map((u) => u.id).toList(),
        attendeeNames: _selectedAttendees.map((u) => u.fullName).toList(),
        reminderTime: reminderTime,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        final isRTL = Provider.of<AppProvider>(context, listen: false).isRTL;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isRTL ? 'فشل في إنشاء الاجتماع' : 'Failed to create meeting',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class AttendeeSelectionDialog extends StatefulWidget {
  final List<UserModel> availableUsers;
  final List<UserModel> selectedUsers;
  final Function(List<UserModel>) onSelectionChanged;

  const AttendeeSelectionDialog({
    super.key,
    required this.availableUsers,
    required this.selectedUsers,
    required this.onSelectionChanged,
  });

  @override
  State<AttendeeSelectionDialog> createState() => _AttendeeSelectionDialogState();
}

class _AttendeeSelectionDialogState extends State<AttendeeSelectionDialog> {
  final _searchController = TextEditingController();
  List<UserModel> _filteredUsers = [];
  Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _filteredUsers = widget.availableUsers;
    _selectedUserIds = widget.selectedUsers.map((u) => u.id).toSet();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = widget.availableUsers.where((user) {
        return user.fullName.toLowerCase().contains(query) ||
            user.department.toLowerCase().contains(query) ||
            user.position.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final isRTL = appProvider.isRTL;

        return AlertDialog(
          title: Text(isRTL ? 'اختيار المشاركين' : 'Select Attendees'),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: isRTL ? 'البحث عن المستخدمين...' : 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final isSelected = _selectedUserIds.contains(user.id);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedUserIds.add(user.id);
                            } else {
                              _selectedUserIds.remove(user.id);
                            }
                          });
                        },
                        title: Text(user.fullName),
                        subtitle: Text('${user.position} • ${user.department}'),
                        secondary: CircleAvatar(
                          backgroundColor: AppColors.primaryColor.withValues(alpha: 0.2),
                          child: Text(
                            _getInitials(user.fullName),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
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
              onPressed: () {
                final selectedUsers = widget.availableUsers
                    .where((user) => _selectedUserIds.contains(user.id))
                    .toList();
                widget.onSelectionChanged(selectedUsers);
                Navigator.pop(context);
              },
              child: Text(isRTL ? 'تأكيد' : 'Confirm'),
            ),
          ],
        );
      },
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}