import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/models.dart';

/// Apenas notificações LOCAIS (sem Firebase). Em Web não há notificações do sistema:
/// os lembretes aparecem dentro do app.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool get supported => !kIsWeb;

  Future<void> init() async {
    if (!supported || _ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ));
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _ready = true;
  }

  /// Cancela tudo e reagenda a partir da lista do servidor (idempotente).
  Future<void> scheduleAll(List<Reminder> reminders) async {
    if (!supported) return;
    await init();
    await _plugin.cancelAll();
    final items = <(Reminder, DateTime)>[];
    for (final r in reminders) {
      for (final t in r.occurrences()) {
        items.add((r, t));
      }
    }
    items.sort((a, b) => a.$2.compareTo(b.$2));
    var id = 1;
    for (final (r, time) in items.take(60)) {
      await _schedule(id++, r, time);
    }
  }

  Future<void> _schedule(int id, Reminder r, DateTime when) async {
    // Instante absoluto (UTC) — independente do fuso do dispositivo.
    final tzWhen = tz.TZDateTime.from(when, tz.UTC);
    await _plugin.zonedSchedule(
      id,
      '${r.petName} · ${r.title}',
      r.subtitle ?? _body(r),
      tzWhen,
      const NotificationDetails(
        android: AndroidNotificationDetails('petvida_reminders', 'Lembretes PetVida',
            channelDescription: 'Vacinas, medicações e rotinas', importance: Importance.high, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  String _body(Reminder r) =>
      r.type == 'vaccine' ? 'Vacina agendada para hoje' : r.type == 'dose' ? 'Hora da medicação' : 'Hora da rotina';
}
