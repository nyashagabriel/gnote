// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Gnote';

  @override
  String get appTagline => 'Domina tu día.';

  @override
  String get syncOfflineSaved => 'Sin conexión: cambios guardados localmente.';

  @override
  String syncPending(int count) {
    return 'Sincronización pendiente ($count)';
  }

  @override
  String syncFailed(int count) {
    return 'Falló la sincronización ($count). Toca para reintentar.';
  }

  @override
  String syncPendingWithCount(int count) {
    return 'Sincronización pendiente ($count)';
  }

  @override
  String get syncRetrying => 'Reintentando sincronización...';
}
