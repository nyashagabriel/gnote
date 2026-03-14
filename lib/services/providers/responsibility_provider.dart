import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/timezone.dart';
import '../../models/person.dart';
import '../local_db.dart';
import '../sync.dart';
import 'core_providers.dart';

const _uuid = Uuid();

class ResponsibilityState {
  const ResponsibilityState({
    required this.motivators,
    required this.meditators,
    this.selectedMotivator,
    this.selectedMeditator,
  });

  final List<GPerson> motivators;
  final List<GPerson> meditators;
  final GPerson? selectedMotivator;
  final GPerson? selectedMeditator;
}

class ResponsibilityNotifier extends StateNotifier<ResponsibilityState> {
  ResponsibilityNotifier(this._db, this._sync)
      : super(const ResponsibilityState(motivators: [], meditators: [])) {
    _load();
  }

  final LocalDb _db;
  final SyncService _sync;

  void _load() {
    state = ResponsibilityState(
      motivators: _db.getMotivators(),
      meditators: _db.getMeditators(),
      selectedMotivator: state.selectedMotivator,
      selectedMeditator: state.selectedMeditator,
    );
  }

  Future<void> addPerson({
    required String name,
    required String whatsappNumber,
    required String role,
    required String messageTemplate,
    required String userId,
  }) async {
    final person = GPerson(
      id: _uuid.v4(),
      userId: userId,
      name: name.trim(),
      whatsappNumber: whatsappNumber.trim(),
      role: role,
      messageTemplate: messageTemplate.trim(),
      timesSelected: 0,
      createdAt: localNow(),
    );
    await _db.savePerson(person);
    await _sync.pushPerson(person);
    _load();
  }

  Future<void> deletePerson(String personId) async {
    await _db.deletePerson(personId);
    await _sync.deletePerson(personId);
    _load();
  }

  void pickMotivator() {
    final pool = state.motivators.where((p) => !p.selectedToday).toList();
    final pick = pool.isNotEmpty
        ? (pool..shuffle()).first
        : ([...state.motivators]
              ..sort((a, b) => a.timesSelected.compareTo(b.timesSelected)))
            .firstOrNull;
    state = ResponsibilityState(
      motivators: state.motivators,
      meditators: state.meditators,
      selectedMotivator: pick,
      selectedMeditator: state.selectedMeditator,
    );
  }

  void pickMeditator() {
    final pool = state.meditators.where((p) => !p.selectedToday).toList();
    final pick = pool.isNotEmpty
        ? (pool..shuffle()).first
        : ([...state.meditators]
              ..sort((a, b) => a.timesSelected.compareTo(b.timesSelected)))
            .firstOrNull;
    state = ResponsibilityState(
      motivators: state.motivators,
      meditators: state.meditators,
      selectedMotivator: state.selectedMotivator,
      selectedMeditator: pick,
    );
  }

  Future<bool> sendWhatsApp(GPerson person) async {
    final message = Uri.encodeComponent(person.resolvedMessage);
    final number = person.whatsappNumber.replaceAll(' ', '');
    final url = Uri.parse('https://wa.me/$number?text=$message');

    if (!await canLaunchUrl(url)) return false;

    await launchUrl(url, mode: LaunchMode.externalApplication);
    await _db.markPersonSelected(person.id);
    await _sync.pushPerson(
      _db.getAllPeople().firstWhere((p) => p.id == person.id),
    );
    _load();
    return true;
  }
}

final responsibilityProvider =
    StateNotifierProvider<ResponsibilityNotifier, ResponsibilityState>((ref) {
  return ResponsibilityNotifier(
    ref.watch(localDbProvider),
    ref.watch(syncServiceProvider),
  );
});
