import '../core/notification_service.dart';
import '../models/models.dart';
import '../repositories/vet_repository.dart';
import 'base_viewmodel.dart';

class RemindersViewModel extends BaseViewModel {
  final VetRepository _repo;
  final NotificationService _notifications;
  RemindersViewModel(this._repo, this._notifications);

  /// Ocorrências concretas ordenadas (lembrete + instante).
  List<(Reminder, DateTime)> upcoming = [];
  bool get notificationsSupported => _notifications.supported;

  Future<void> load() => run(() async {
        final list = await _repo.reminders();
        upcoming = [for (final r in list) for (final t in r.occurrences()) (r, t)]..sort((a, b) => a.$2.compareTo(b.$2));
        try {
          await _notifications.scheduleAll(list); // falha de permissão não deve quebrar a lista
        } catch (_) {}
      });

  Future<bool> markDone(Reminder r) => run(() async {
        await _repo.markDose(r.id, true);
        await load();
      }, showLoading: false);
}
