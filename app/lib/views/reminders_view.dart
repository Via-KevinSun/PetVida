import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/format.dart';
import '../core/notification_service.dart';
import '../models/models.dart';
import '../repositories/vet_repository.dart';
import '../viewmodels/reminders_viewmodel.dart';
import 'widgets/common.dart';

class RemindersView extends StatelessWidget {
  final bool active;
  const RemindersView({super.key, required this.active});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (c) => RemindersViewModel(c.read<VetRepository>(), c.read<NotificationService>())..load(),
        child: _Body(active: active),
      );
}

class _Body extends StatefulWidget {
  final bool active;
  const _Body({required this.active});
  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  @override
  void didUpdateWidget(covariant _Body old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      // adia para depois da construção do frame, para não "sujar" a tela durante o build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<RemindersViewModel>().load();
      });
    }
  }

  static const _icons = {'vaccine': Icons.vaccines_rounded, 'dose': Icons.medication_rounded, 'routine': Icons.schedule_rounded};

  String _dayLabel(DateTime t) {
    final n = DateTime.now();
    final d = DateTime(t.year, t.month, t.day).difference(DateTime(n.year, n.month, n.day)).inDays;
    return d == 0 ? 'Hoje' : d == 1 ? 'Amanhã' : fmtDate(t.toIso8601String());
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RemindersViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Lembretes')),
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: AsyncBody(
          loading: vm.loading, error: vm.error, isEmpty: vm.upcoming.isEmpty, onRetry: vm.load,
          empty: ListView(children: const [
            SizedBox(height: 120),
            EmptyState(icon: Icons.notifications_none, message: 'Sem lembretes próximos.\nAdicione vacinas, rotinas ou receba prescrições.'),
          ]),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (!vm.notificationsSupported)
              Card(
                color: Colors.amber.shade50,
                child: const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Na versão Web os lembretes aparecem apenas aqui. As notificações no dispositivo funcionam em Android e iOS.',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
            for (var i = 0; i < vm.upcoming.length; i++) ...[
              if (i == 0 || _dayLabel(vm.upcoming[i].$2) != _dayLabel(vm.upcoming[i - 1].$2))
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 14, 4, 4),
                  child: Text(_dayLabel(vm.upcoming[i].$2), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              _tile(context, vm, vm.upcoming[i].$1, vm.upcoming[i].$2),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, RemindersViewModel vm, Reminder r, DateTime t) => Card(
        child: ListTile(
          leading: CircleAvatar(backgroundColor: Colors.teal.shade50, child: Icon(_icons[r.type], color: Colors.teal)),
          title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${r.petName} · ${two(t.hour)}:${two(t.minute)}${r.subtitle != null ? ' · ${r.subtitle}' : ''}'),
          trailing: r.type == 'dose'
              ? TextButton(
                  onPressed: () async {
                    if (!await vm.markDone(r) && context.mounted) snack(context, vm.error ?? 'Erro', error: true);
                  },
                  child: const Text('Dada'))
              : null,
        ),
      );
}
