// ==========================================
// FILE: ./core/constants.dart
// ==========================================

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────
// GNOTE — CONSTANTS
// Single source of truth. Nothing is hardcoded in pages.
// ─────────────────────────────────────────────────────────────

// ── COLOURS ──────────────────────────────────────────────────
class GColors {
  GColors._();

  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceHigh = Color(0xFF242424);
  static const Color border = Color(0xFF2A2A2A);

  // Primaries
  static const Color orange = Color(0xFFF0A500);
  static const Color orangeDim = Color(0x33F0A500);
  static const Color azure = Color(0xFF3FA9F5);
  static const Color azureDim = Color(0x333FA9F5);

  // Semantics
  static const Color success = Color(0xFF52E0A0);
  static const Color successDim = Color(0x2252E0A0);
  static const Color danger = Color(0xFFE05252);
  static const Color dangerDim = Color(0x22E05252);
  static const Color warning = Color(0xFFF0C040);
  static const Color warningDim = Color(0x22F0C040);

  // Text
  static const Color textPrimary = Color(0xFFE8E8E8);
  static const Color textMuted = Color(0xFF9A9A9A);
  static const Color textDisabled = Color(0xFF6A6A6A);

  // Category colours
  static const Map<String, Color> category = {
    'career': azure,
    'project': orange,
    'learning': success,
    'personal': Color(0xFFC05CE0),
    'other': Color(0xFF888888),
  };
}

// ── SPACING ───────────────────────────────────────────────────
class GSpacing {
  GSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const double pagePadding = 20.0;
  static const double cardRadius = 12.0;
  static const double buttonRadius = 10.0;
  static const double inputRadius = 10.0;
}

// ── TYPOGRAPHY ────────────────────────────────────────────────
class GText {
  GText._();

  static const String fontFamily = 'monospace';

  static const TextStyle heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: GColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: GColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: GColors.textPrimary,
    height: 1.6,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: GColors.textMuted,
    letterSpacing: 1.5,
  );

  static const TextStyle muted = TextStyle(
    fontSize: 13,
    color: GColors.textMuted,
    height: 1.5,
  );

  static const TextStyle accent = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: GColors.orange,
  );

  static const TextStyle danger = TextStyle(
    fontSize: 13,
    color: GColors.danger,
  );
}

// ── STRINGS ───────────────────────────────────────────────────
class GStrings {
  GStrings._();

  // App
  static const String appName = 'Gnote';
  static const String appTagline = 'Own your day.';

  // Anchor
  static const String anchorHeader = 'ANCHOR';
  static const String anchorTitle = 'Why did you wake up today?';
  static const String anchorHint = 'Write one honest sentence...';
  static const String anchorSave = 'Lock it in';
  static const String anchorEmpty = 'No anchor set. Start here.';
  static const String anchorSub = 'One sentence. Be honest.';
  static const String anchorLockedAt = 'Locked · ';
  static const String anchorRestored = 'Draft restored';

  // Daily 3
  static const String daily3Header = 'DAILY 3';
  static const String daily3Title = 'Daily 3';
  static const String daily3Sub = 'Three tasks. Locked by 9am. No additions.';
  static const String daily3Limit = 'Three tasks. No more.';
  static const String daily3Add = 'Add task';
  static const String daily3Full = 'Three tasks locked. Focus now.';
  static const String daily3Empty = 'No tasks yet. Add up to 3.';
  static const String daily3Done = 'Day complete. Rest well.';
  static const String daily3LocksIn = 'Locks in ';
  static const String daily3H = 'h ';
  static const String daily3M = 'm';
  static const String daily3Locked = 'LOCKED';
  static const String daily3Slot1 = 'Add your first task';
  static const String daily3Slot2 = 'Add your second task';
  static const String daily3Slot3 = 'Add your third task';

  // Add Task
  static const String addTaskHeader = 'NEW TASK';
  static const String addTaskTitle = 'OWN YOUR DAY.';
  static const String addTaskWhatHint = 'Design the user profile screen';
  static const String addTaskDoneHint = 'Prototype shared and reviewed';
  static const String addTaskByLabel = 'COMPLETE BY';
  static const String addTaskDateLabel = 'DATE';
  static const String addTaskTimeLabel = 'TIME';
  static const String addTaskCategoryLabel = 'CATEGORY';
  static const String addTaskErrWhat = 'Tell me what you will do.';
  static const String addTaskErrDone = "Tell me how you'll know it's done.";
  static const String addTaskSaveBtn = 'Save task';

  // SMART task fields
  static const String smartWhat = 'What exactly will you do?';
  static const String smartDoneWhen = 'How will you know it is done?';
  static const String smartBy = 'By what time today?';
  static const String smartCategory = 'Category';

  // Capture
  static const String captureHeader = 'CAPTURE';
  static const String captureTitle = 'Capture';
  static const String captureSub = 'Everything else. Review Sundays only.';
  static const String captureHint = 'Dump it here...';
  static const String captureAdd = 'Capture it';
  static const String captureEmpty = 'Mind clear. Nothing captured.';
  static const String captureEmptySub = "Things that aren't today live here.";
  static const String captureShare = 'Share list';
  static const String captureReviewMsg =
      'Review day — clear what no longer matters.';

  // Habit
  static const String habitTitle = 'HABIT';
  static const String habitSub = 'One habit. Did it or didn\'t.';
  static const String habitEmpty = 'No habit set. Pick one.';
  static const String habitDone = 'Done today. Streak alive.';
  static const String habitMissed = 'Missed. Reset. Go again.';
  static const String habitAdd = 'Set habit';
  static const String habitStreakLabel = 'streak';
  static const String habitChangeBtn = 'Change habit';
  static const String habitSetBtn = 'Set habit';
  static const String habitMakeItCount = 'One habit. Make it count.';
  static const String habitHint = 'e.g. Read 20 minutes';
  static const String habitReplaceWarn =
      'This replaces your current habit and resets the streak.';
  static const String habitBeginAgain = 'Begin again';
  static const String habitDidItToday = 'I did it today';
  static const String habitDoneForToday = 'Done for today ✓';
  static const String habitNotDoneYet = 'Not done today yet.';
  static const String habitOneAtATime = 'One habit at a time.';
  static const String habitChangeTitle = 'CHANGE HABIT';
  static const String habitSetTitle = 'SET HABIT';

  // Responsibility
  static const String respHeader = 'RESPONSIBILITY';
  static const String respTitle = 'Responsibility';
  static const String respSub = 'Choose your people. We remind you daily.';
  static const String respPickBtn = 'Pick today\'s person';
  static const String respEmpty = 'No people added yet.';
  static const String respAddPerson = 'Add person';
  static const String respNotifTitle = 'Time to reach out';
  static const String respShareVia = 'Send via WhatsApp';
  static const String respMotivatorsHeader = 'MOTIVATORS';
  static const String respMeditatorsHeader = 'MEDITATORS';
  static const String respNoMotivators = 'No motivators yet.';
  static const String respNoMeditators = 'No meditators yet.';
  static const String respAddOne = 'Add one';
  static const String respActiveCount = ' Active';
  static const String respPickMotivatorBtn = "PICK TODAY'S MOTIVATOR";
  static const String respPickMeditatorBtn = "PICK TODAY'S MEDITATOR";
  static const String respNeverPicked = 'Never picked';
  static const String respPickedToday = 'Picked today';
  static const String respLastYesterday = 'Last: yesterday';
  static const String respLastPrefix = 'Last: ';
  static const String respDaysAgoSuffix = ' days ago';
  static const String respPickedPrefix = '✓ ';
  static const String respPickedSuffix = ' PICKED — TAP TO SEND';

  // Add Person
  static const String addPersonHeader = 'NEW PERSON';
  static const String addPersonTitle = 'Build your support circle.';
  static const String addPersonNameLabel = 'Full name';
  static const String addPersonNameHint = 'Alex Rivers';
  static const String addPersonPhoneLabel = 'WhatsApp number';
  static const String addPersonPhoneHint1 =
      'International format — e.g. +263712345678';
  static const String addPersonPhoneHint2 = '+263712345678';
  static const String addPersonRoleLabel = 'ROLE';
  static const String addPersonMsgLabel = 'Message';
  static const String addPersonMsgSub =
      'This message will be sent via WhatsApp.';
  static const String addPersonMsgHint = 'Write a personal message...';
  static const String addPersonSaveBtn = 'Add person';
  static const String errPhoneRequired = 'Phone number is required.';
  static const String errPhonePlus = 'Number must start with + (e.g. +263...)';
  static const String errPhoneShort = 'Number too short.';
  static const String errPhoneDigits = 'Only digits after the + sign.';
  static const String errNameRequired = 'Name is required.';
  static const String errMsgRequired = 'Message cannot be empty.';

  // Roles
  static const String roleMotivator = 'Motivator';
  static const String roleMeditator = 'Meditator';

  // Message templates
  static const Map<String, String> messageTemplates = {
    'Motivator': 'Hey {name} 👋 You\'ve been selected as today\'s Motivator. '
        'Share something that keeps you going — a word, a thought, anything real. '
        'We need it today. 🔥',
    'Meditator': 'Hey {name} 🌿 You\'re today\'s Meditator. '
        'Drop a moment of calm — a reflection, a breath, a reminder to slow down. '
        'Whatever feels true to you. 🙏',
  };

  // Auth / Login / Signup
  static const String authSignIn = 'SIGN IN';
  static const String authSignUp = 'SIGNUP';
  static const String authSignUpLink = 'Sign up';
  static const String authCreateAccount = 'CREATE ACCOUNT';
  static const String authDisplayName = 'Display name';
  static const String authNameHint = 'Your name';
  static const String authEmailLabel = 'Email address';
  static const String authEmailHint = 'hello@example.com';
  static const String authPasswordLabel = 'Password';
  static const String authPasswordHint = '••••••••';
  static const String authStrength = 'STRENGTH: ';
  static const String authWeak = 'WEAK';
  static const String authMod = 'MODERATE';
  static const String authStrong = 'STRONG';
  static const String authVeryStrong = 'VERY STRONG';
  static const String authReqFields = 'All fields are required.';
  static const String authWeakPass = 'Password is too weak.';
  static const String authNoAccountPrompt = "Don't have an account? ";
  static const String authHasAccountPrompt = "Already have an account? ";
  static const String authEmptyFieldsErr =
      'Please enter both email and password.';

  // OTP
  static const String otpCheckInbox = 'CHECK YOUR INBOX';
  static const String otpEnterCode = 'Enter 8-digit code';
  static const String otpCodeHint = '12345678';
  static const String otpSentCode = 'We sent a secure code to\n';
  static const String otpReqCode = 'Please enter the 8-digit code.';
  static const String otpNewCodeSent =
      'A new code has been sent to your email.';
  static const String otpVerifyBtn = 'VERIFY ACCOUNT';
  static const String otpResendBtn = 'Resend code';

  // Profile
  static const String profileHeader = 'PROFILE';
  static const String profileSecAccount = 'Account';
  static const String profileDisplayName = 'Display name';
  static const String profileEmail = 'Email';
  static const String profileTimezone = 'Timezone';
  static const String profileSecPrefs = 'Preferences';
  static const String profileThemeMode = 'Theme mode';
  static const String profileThemeSystem = 'System';
  static const String profileThemeLight = 'Light';
  static const String profileThemeDark = 'Dark';
  static const String profileHabitRem = 'Habit reminder';
  static const String profileSecSession = 'Session';
  static const String profileSignOutBtn = 'Sign out';
  static const String profileVersion = 'Gnote v1.0.0';
  static const String profileHabitSetSnack = 'Habit reminder set to ';
  static const String profileHabitErrSnack = 'Could not update habit reminder.';
  static const String profileSignOutTitle = 'Sign out?';
  static const String profileSignOutSub = 'You will need to sign in again.';
  static const String profileSignOutErr = 'Sign out failed. Try again.';

  // General
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String confirm = 'Confirm';
  static const String loading = 'Loading...';
  static const String errorGeneric = 'Something went wrong. Try again.';
  static const String errNotSignedIn = 'Not signed in.';
  static const String noConnection = 'Offline — changes saved locally.';
  static const String synced = 'Synced.';
}

// ── ROUTES ────────────────────────────────────────────────────
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

// ── HIVE BOXES ────────────────────────────────────────────────
class GBoxes {
  GBoxes._();

  static const String tasks = 'tasks';
  static const String anchors = 'anchors';
  static const String habits = 'habits';
  static const String people = 'people';
  static const String selections = 'selections';
  static const String meta = 'meta';

  // ── Meta keys ─────────────────────────────────────────────
  static const String anchorDraftKey = 'anchor_draft';
}

// ── SUPABASE TABLES ───────────────────────────────────────────
class GTables {
  GTables._();

  static const String tasks = 'tasks';
  static const String anchors = 'anchors';
  static const String habits = 'habits';
  static const String people = 'people';
  static const String selections = 'selections';
}

// ── TASK CATEGORIES ───────────────────────────────────────────
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

// ── NOTIFICATION IDs ─────────────────────────────────────────
class GNotifIds {
  GNotifIds._();

  static const int morningAnchor = 1;
  static const int daily3Reminder = 2;
  static const int habitReminder = 3;
  static const int responsibilityPick = 4;
  static const int captureReview = 5;
}

// ── NOTIFICATION CHANNELS ─────────────────────────────────────
class GChannels {
  GChannels._();
  static const String anchor = 'gnote_anchor';
  static const String tasks = 'gnote_tasks';
  static const String habit = 'gnote_habit';
  static const String responsibility = 'gnote_responsibility';
}

// ── LIMITS ────────────────────────────────────────────────────
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

// ── JSON HELPERS ──────────────────────────────────────────────
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
