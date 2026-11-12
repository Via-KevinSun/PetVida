import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../repositories/vet_repository.dart';
import '../../viewmodels/connections_viewmodel.dart';
import '../widgets/common.dart';

class ConnectionsTab extends StatelessWidget {
  final String petId;
  const ConnectionsTab({super.key, required this.petId});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (c) => ConnectionsViewModel(c.read<VetRepository>(), petId)..load(),
        child: const _Body(),
      );
}

class _Body extends StatelessWidget {
  const _Body();

  Future<void> _invite(BuildContext context, ConnectionsViewModel vm) async {
    final ctrl = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Convidar veterinário'),
        content: TextField(controller: ctrl, keyboardType: TextInputType.emailAddress, autofocus: true,
            decoration: const InputDecoration(labelText: 'E-mail do veterinário')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(90, 42)),
              onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Convidar')),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    final ok = await vm.invite(email);
    if (context.mounted) snack(context, ok ? 'Convite enviado' : vm.error!, error: !ok);
  }

  Color _color(String s) => switch (s) {
        'accepted' => Colors.green, 'pending' => Colors.orange, _ => Colors.blueGrey,
      };

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ConnectionsViewModel>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _invite(context, vm), icon: const Icon(Icons.person_add_alt_1), label: const Text('Convidar')),
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: AsyncBody(
          loading: vm.loading, error: vm.error, isEmpty: vm.items.isEmpty, onRetry: vm.load,
          empty: ListView(children: const [
            SizedBox(height: 80),
            EmptyState(icon: Icons.medical_services_outlined, message: 'Nenhum veterinário ligado.\nConvide um por e-mail.'),
          ]),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), children: [
            for (final c in vm.items)
              Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: _color(c.status).withOpacity(.15), child: Icon(Icons.medical_services_outlined, color: _color(c.status))),
                  title: Text(c.vetName ?? c.email),
                  subtitle: Text(c.vetName != null ? '${c.email}\n${c.statusLabel}' : c.statusLabel),
                  isThreeLine: c.vetName != null,
                  trailing: c.status == 'accepted'
                      ? TextButton(
                          onPressed: () async {
                            final ok = await confirm(context, 'Desligar veterinário?',
                                'O veterinário perde o acesso a este pet. As recomendações e prescrições que deixou continuam no histórico.',
                                action: 'Desligar');
                            if (ok && !await vm.disconnect(c.id) && context.mounted) snack(context, vm.error!, error: true);
                          },
                          child: const Text('Desligar'))
                      : null,
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
