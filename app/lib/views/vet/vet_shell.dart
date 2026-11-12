import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../repositories/pet_repository.dart';
import '../../repositories/vet_repository.dart';
import '../../viewmodels/pets_viewmodel.dart';
import '../../viewmodels/vet_invites_viewmodel.dart';
import '../pets/pet_detail_view.dart';
import '../profile_view.dart';
import '../widgets/common.dart';

class VetShell extends StatelessWidget {
  const VetShell({super.key});
  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (c) => PetsViewModel(c.read<PetRepository>())..load()),
          ChangeNotifierProvider(create: (c) => VetInvitesViewModel(c.read<VetRepository>())..load()),
        ],
        child: const _Shell(),
      );
}

class _Shell extends StatefulWidget {
  const _Shell();
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int _i = 0;
  @override
  Widget build(BuildContext context) {
    final n = context.watch<VetInvitesViewModel>().invites.length;
    return Scaffold(
      body: IndexedStack(index: _i, children: const [_Patients(), _Invites(), ProfileView()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i, onDestinationSelected: (i) => setState(() => _i = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.pets_outlined), selectedIcon: Icon(Icons.pets), label: 'Pacientes'),
          NavigationDestination(
              icon: Badge(isLabelVisible: n > 0, label: Text('$n'), child: const Icon(Icons.mail_outline)),
              selectedIcon: const Icon(Icons.mail), label: 'Convites'),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _Patients extends StatelessWidget {
  const _Patients();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PetsViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Meus pacientes')),
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: AsyncBody(
          loading: vm.loading, error: vm.error, isEmpty: vm.pets.isEmpty, onRetry: vm.load,
          empty: ListView(children: const [
            SizedBox(height: 100),
            EmptyState(icon: Icons.pets_rounded, message: 'Sem pacientes ligados.\nAceite um convite de um dono para começar.'),
          ]),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            for (final p in vm.pets)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: PetAvatar(url: p.photoUrl, size: 56),
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text([p.breed, ageOf(p.birthDate), if (p.ownerName != null) 'Dono: ${p.ownerName}'].where((e) => e != null && e.isNotEmpty).join(' · ')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PetDetailView(pet: p, isVet: true))),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _Invites extends StatelessWidget {
  const _Invites();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VetInvitesViewModel>();
    Future<void> respond(VetInvite i, bool accept) async {
      final ok = await vm.respond(i.id, accept);
      if (!context.mounted) return;
      if (ok && accept) context.read<PetsViewModel>().load();
      snack(context, ok ? (accept ? 'Convite aceite' : 'Convite recusado') : vm.error!, error: !ok);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Convites')),
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: AsyncBody(
          loading: vm.loading, error: vm.error, isEmpty: vm.invites.isEmpty, onRetry: vm.load,
          empty: ListView(children: const [SizedBox(height: 100), EmptyState(icon: Icons.mail_outline, message: 'Sem convites pendentes.')]),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            for (final i in vm.invites)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      PetAvatar(url: i.photoUrl, size: 52),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(i.petName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('${i.ownerName} convidou-o para acompanhar este pet', style: const TextStyle(fontSize: 13)),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: OutlinedButton(onPressed: () => respond(i, false), child: const Text('Recusar'))),
                      const SizedBox(width: 10),
                      Expanded(child: FilledButton(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                          onPressed: () => respond(i, true), child: const Text('Aceitar'))),
                    ]),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
