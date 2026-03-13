// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Gnote';

  @override
  String get appTagline => 'Own your day.';

  @override
  String get syncOfflineSaved => 'Offline - changes saved locally.';

  @override
  String syncPending(int count) {
    return 'Sync pending ($count)';
  }

  @override
  String syncFailed(int count) {
    return 'Sync failed ($count). Tap to retry.';
  }

  @override
  String syncPendingWithCount(int count) {
    return 'Sync pending ($count)';
  }

  @override
  String get syncRetrying => 'Retrying sync...';
}
