class GRoutes {
  GRoutes._();

  static const String anchor = '/';
  static const String daily3 = '/daily3';
  static const String capture = '/capture';
  static const String habit = '/habit';
  static const String responsibility = '/responsibility';
  static const String addPerson = '/responsibility/add';
  static const String addTask = '/daily3/add';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String verifyOtp = '/verify-otp';
  static const String profile = '/profile';
}

class GBoxes {
  GBoxes._();

  static const String users = 'users';
  static const String tasks = 'tasks';
  static const String anchors = 'anchors';
  static const String habits = 'habits';
  static const String people = 'people';
  static const String selections = 'selections';
  static const String meta = 'meta';

  static const String anchorDraftKey = 'anchor_draft';
}

class GTables {
  GTables._();

  static const String tasks = 'tasks';
  static const String anchors = 'anchors';
  static const String habits = 'habits';
  static const String people = 'people';
  static const String selections = 'selections';
}

class GCategories {
  GCategories._();

  static const String career = 'career';
  static const String project = 'project';
  static const String learning = 'learning';
  static const String personal = 'personal';
  static const String other = 'other';

  static const List<String> defaults = [
    career,
    project,
    learning,
    personal,
    other,
  ];
}

class GNotifIds {
  GNotifIds._();

  static const int morningAnchor = 1;
  static const int daily3Reminder = 2;
  static const int habitReminder = 3;
  static const int responsibilityPick = 4;
  static const int captureReview = 5;
}

class GChannels {
  GChannels._();

  static const String anchor = 'gnote_anchor';
  static const String tasks = 'gnote_tasks';
  static const String habit = 'gnote_habit';
  static const String responsibility = 'gnote_responsibility';
}

class GLimits {
  GLimits._();

  static const int maxDailyTasks = 3;
  static const int maxCategories = 20;
  static const int anchorMaxChars = 160;
  static const int taskTitleMax = 80;
  static const int captureItemMax = 200;
  static const int templateMaxChars = 300;
  static const Duration syncDebounce = Duration(seconds: 3);
  static const Duration notifCheckInterval = Duration(minutes: 15);
}

class GJson {
  GJson._();

  static String str(Map<String, dynamic> json, String key,
      {String fallback = ''}) {
    final v = json[key];
    if (v == null) return fallback;
    return v.toString();
  }

  static int integer(Map<String, dynamic> json, String key,
      {int fallback = 0}) {
    final v = json[key];
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }

  static bool boolean(Map<String, dynamic> json, String key,
      {bool fallback = false}) {
    final v = json[key];
    if (v == null) return fallback;
    if (v is bool) return v;
    return v.toString().toLowerCase() == 'true';
  }

  static DateTime? dateTimeOrNull(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static DateTime dateTime(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v == null) return DateTime.now();
    return DateTime.tryParse(v.toString()) ?? DateTime.now();
  }
}
