import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../repositories/pet_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/pets_viewmodel.dart';
import '../widgets/common.dart';
import 'pet_detail_view.dart';
import 'pet_form_view.dart';

class PetsHomeView extends StatelessWidget {
  const PetsHomeView({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (c) => PetsViewModel(c.read<PetRepository>())..load(),
        child: const _PetsList(),
      );
}

class _PetsList extends StatelessWidget {
  const _PetsList();

  Future<void> _openForm(BuildContext c, PetsViewModel vm, [Pet? pet]) =>
      Navigator.push(c, MaterialPageRoute(builder: (_) => PetFormView(vm: vm, pet: pet)));

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PetsViewModel>();
    final name = context.read<AuthViewModel>().user!.name.split(' ').first;
    return Scaffold(
      appBar: AppBar(title: Text('Olá, $name 🐾')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, vm), icon: const Icon(Icons.add), label: const Text('Novo cão')),
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: AsyncBody(
          loading: vm.loading, error: vm.error, isEmpty: vm.pets.isEmpty, onRetry: vm.load,
          empty: ListView(children: [
            const SizedBox(height: 100),
            EmptyState(icon: Icons.pets_rounded, message: 'Ainda não tem nenhum cão cadastrado.',
                action: FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
                    onPressed: () => _openForm(context, vm), child: const Text('Cadastrar o primeiro'))),
          ]),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: vm.pets.length,
            itemBuilder: (_, i) {
              final p = vm.pets[i];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => PetDetailView(pet: p)));
                    vm.load();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      PetAvatar(url: p.photoUrl, size: 68),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text([p.breed, ageOf(p.birthDate), fmtKg(p.weightKg)].where((e) => e != null && e.isNotEmpty).join(' · '),
                              style: TextStyle(color: Colors.blueGrey.shade500)),
                        ]),
                      ),
                      const Icon(Icons.chevron_right),
                    ]),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
