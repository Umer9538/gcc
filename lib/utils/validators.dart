class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }

    final nameRegex = RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$');
    if (!nameRegex.hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }

    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'\s+'), ''))) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }

    return null;
  }

  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    return null;
  }

  static String? validateMeetingTitle(String? value) {
    return validateMinLength(value, 3, 'Meeting title');
  }

  static String? validateMeetingDescription(String? value) {
    return validateMinLength(value, 10, 'Meeting description');
  }

  static String? validateAnnouncementTitle(String? value) {
    return validateMinLength(value, 3, 'Announcement title');
  }

  static String? validateAnnouncementContent(String? value) {
    return validateMinLength(value, 10, 'Announcement content');
  }

  static String? validateDocumentTitle(String? value) {
    return validateMinLength(value, 3, 'Document title');
  }

  static String? validateDocumentDescription(String? value) {
    return validateMinLength(value, 10, 'Document description');
  }

  static String? validateMessageContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Message cannot be empty';
    }
    return null;
  }

  static String? validateDate(DateTime? value, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateFutureDate(DateTime? value, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }

    if (value.isBefore(DateTime.now())) {
      return '$fieldName cannot be in the past';
    }

    return null;
  }

  static String? validateMeetingTime(DateTime? startTime, DateTime? endTime) {
    if (startTime == null || endTime == null) {
      return 'Both start and end times are required';
    }

    if (startTime.isAfter(endTime)) {
      return 'Start time cannot be after end time';
    }

    if (startTime.isBefore(DateTime.now())) {
      return 'Meeting cannot be scheduled in the past';
    }

    return null;
  }
}