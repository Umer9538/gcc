import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../constants/app_constants.dart';
import '../models/meeting_model.dart';
import '../utils/date_utils.dart';

enum CalendarView { month, week }

class CalendarWidget extends StatefulWidget {
  final List<MeetingModel> meetings;
  final Function(DateTime) onDateSelected;
  final Function(DateTime)? onDateTapped;
  final Function(MeetingModel)? onMeetingTapped;
  final Function(DateTime)? onCreateMeeting;
  final DateTime? selectedDate;

  const CalendarWidget({
    super.key,
    required this.meetings,
    required this.onDateSelected,
    this.onDateTapped,
    this.onMeetingTapped,
    this.onCreateMeeting,
    this.selectedDate,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _currentDate;
  late DateTime _selectedDate;
  CalendarView _currentView = CalendarView.month;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _pageController = PageController(initialPage: 1000);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final isRTL = appProvider.isRTL;

        return Column(
          children: [
            _buildCalendarHeader(isRTL),
            _buildCalendarViewToggle(isRTL),
            Expanded(
              child: _currentView == CalendarView.month
                  ? _buildMonthView(isRTL)
                  : _buildWeekView(isRTL),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarHeader(bool isRTL) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppConstants.defaultBorderRadius),
          bottomRight: Radius.circular(AppConstants.defaultBorderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              isRTL ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
              color: Colors.white,
            ),
            onPressed: _previousMonth,
          ),
          Expanded(
            child: Text(
              _getHeaderText(isRTL),
              style: AppTextStyles.heading2.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(
              isRTL ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
              color: Colors.white,
            ),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarViewToggle(bool isRTL) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              text: isRTL ? 'شهري' : 'Month',
              isSelected: _currentView == CalendarView.month,
              onTap: () => setState(() => _currentView = CalendarView.month),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              text: isRTL ? 'أسبوعي' : 'Week',
              isSelected: _currentView == CalendarView.week,
              onTap: () => setState(() => _currentView = CalendarView.week),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondaryColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMonthView(bool isRTL) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        final offset = index - 1000;
        setState(() {
          _currentDate = DateTime(_currentDate.year, _currentDate.month + offset, 1);
        });
      },
      itemBuilder: (context, index) {
        final offset = index - 1000;
        final monthDate = DateTime(_currentDate.year, _currentDate.month + offset, 1);
        return _buildMonthCalendar(monthDate, isRTL);
      },
    );
  }

  Widget _buildMonthCalendar(DateTime monthDate, bool isRTL) {
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);
    final firstDayOfWeek = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    return Column(
      children: [
        _buildWeekdayHeaders(isRTL),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppConstants.smallPadding),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: 42, // 6 weeks * 7 days
            itemBuilder: (context, index) {
              final dayIndex = index - firstDayOfWeek;
              if (dayIndex < 0 || dayIndex >= daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(monthDate.year, monthDate.month, dayIndex + 1);
              final meetings = _getMeetingsForDate(date);
              final isSelected = _isSameDay(date, _selectedDate);
              final isToday = _isSameDay(date, DateTime.now());

              return _buildCalendarDay(
                date: date,
                meetings: meetings,
                isSelected: isSelected,
                isToday: isToday,
                isRTL: isRTL,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekView(bool isRTL) {
    final startOfWeek = _getStartOfWeek(_selectedDate);

    return Column(
      children: [
        _buildWeekdayHeaders(isRTL),
        Expanded(
          child: Row(
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final meetings = _getMeetingsForDate(date);
              final isSelected = _isSameDay(date, _selectedDate);
              final isToday = _isSameDay(date, DateTime.now());

              return Expanded(
                child: _buildWeekDayColumn(
                  date: date,
                  meetings: meetings,
                  isSelected: isSelected,
                  isToday: isToday,
                  isRTL: isRTL,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders(bool isRTL) {
    final weekdays = isRTL
        ? ['أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت']
        : ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: weekdays
            .map(
              (day) => Expanded(
                child: Text(
                  day,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCalendarDay({
    required DateTime date,
    required List<MeetingModel> meetings,
    required bool isSelected,
    required bool isToday,
    required bool isRTL,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
        widget.onDateSelected(date);
        widget.onDateTapped?.call(date);
      },
      onLongPress: () {
        widget.onCreateMeeting?.call(date);
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor
              : isToday
                  ? AppColors.primaryColor.withValues(alpha: 0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday && !isSelected
              ? Border.all(color: AppColors.primaryColor, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? AppColors.primaryColor
                        : AppColors.textPrimaryColor,
                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (meetings.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (meetings.length <= 3)
                    ...meetings.map((meeting) => Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: _getMeetingColor(meeting.status),
                            shape: BoxShape.circle,
                          ),
                        ))
                  else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${meetings.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekDayColumn({
    required DateTime date,
    required List<MeetingModel> meetings,
    required bool isSelected,
    required bool isToday,
    required bool isRTL,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryColor
                  : isToday
                      ? AppColors.primaryColor.withValues(alpha: 0.1)
                      : AppColors.surfaceColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              '${date.day}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? AppColors.primaryColor
                        : AppColors.textPrimaryColor,
                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Meetings
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(4),
              itemCount: meetings.length,
              itemBuilder: (context, index) {
                final meeting = meetings[index];
                return GestureDetector(
                  onTap: () => widget.onMeetingTapped?.call(meeting),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getMeetingColor(meeting.status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _getMeetingColor(meeting.status),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meeting.title,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          AppDateUtils.formatTime(meeting.startTime),
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<MeetingModel> _getMeetingsForDate(DateTime date) {
    return widget.meetings.where((meeting) {
      return _isSameDay(meeting.startTime, date);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Color _getMeetingColor(MeetingStatus status) {
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

  String _getHeaderText(bool isRTL) {
    if (_currentView == CalendarView.month) {
      return isRTL
          ? _getArabicMonthYear(_currentDate)
          : '${_getMonthName(_currentDate.month)} ${_currentDate.year}';
    } else {
      final startOfWeek = _getStartOfWeek(_selectedDate);
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      if (isRTL) {
        return '${startOfWeek.day} - ${endOfWeek.day} ${_getArabicMonthName(startOfWeek.month)} ${startOfWeek.year}';
      } else {
        return '${startOfWeek.day} - ${endOfWeek.day} ${_getMonthName(startOfWeek.month)} ${startOfWeek.year}';
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String _getArabicMonthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }

  String _getArabicMonthYear(DateTime date) {
    return '${_getArabicMonthName(date.month)} ${date.year}';
  }

  DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday % 7; // Sunday = 0
    return date.subtract(Duration(days: weekday));
  }

  void _previousMonth() {
    setState(() {
      if (_currentView == CalendarView.month) {
        _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
      } else {
        _selectedDate = _selectedDate.subtract(const Duration(days: 7));
      }
    });
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextMonth() {
    setState(() {
      if (_currentView == CalendarView.month) {
        _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
      } else {
        _selectedDate = _selectedDate.add(const Duration(days: 7));
      }
    });
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}