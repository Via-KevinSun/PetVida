import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../repositories/pet_repository.dart';
import '../../viewmodels/pets_viewmodel.dart';
import '../widgets/common.dart';
import 'connections_tab.dart';
import 'gallery_tab.dart';
import 'health_tab.dart';
import 'notes_tab.dart';
import 'pet_form_view.dart';
import 'timeline_tab.dart';

/// Vista do pet. isVet = true -> somente leitura + recomendações/prescrições.
class PetDetailView extends StatefulWidget {
  final Pet pet;
  final bool isVet;
  const PetDetailView({super.key, required this.pet, this.isVet = false});
  @override
  State<PetDetailView> createState() => _PetDetailViewState();
}

class _PetDetailViewState extends State<PetDetailView> {
  late Pet _pet = widget.pet;

  Future<void> _edit() async {
    final repo = context.read<PetRepository>();
    final vm = PetsViewModel(repo);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => PetFormView(vm: vm, pet: _pet)));
    try {
      final p = await repo.pet(_pet.id);
      if (mounted) setState(() => _pet = p);
    } catch (_) {}
  }

  Future<void> _delete() async {
    if (!await confirm(context, 'Excluir ${_pet.name}?', 'Todos os registos de saúde deste cão serão apagados. Esta ação não pode ser desfeita.', action: 'Excluir')) return;
    await context.read<PetRepository>().delete(_pet.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const Tab(text: 'Saúde'), const Tab(text: 'Timeline'), const Tab(text: 'Veterinário'), const Tab(text: 'Galeria'),
      if (!widget.isVet) const Tab(text: 'Vets ligados'),
    ];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_pet.name),
          actions: widget.isVet
              ? null
              : [
                  IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _edit),
                  IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
                ],
          bottom: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: tabs),
        ),
        body: Column(children: [
          _Header(pet: _pet, showOwner: widget.isVet),
          Expanded(
            child: TabBarView(children: [
              HealthTab(pet: _pet, readOnly: widget.isVet),
              TimelineTab(petId: _pet.id),
              NotesTab(petId: _pet.id, isVet: widget.isVet),
              GalleryTab(petId: _pet.id, readOnly: widget.isVet),
              if (!widget.isVet) ConnectionsTab(petId: _pet.id),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Pet pet;
  final bool showOwner;
  const _Header({required this.pet, required this.showOwner});
  @override
  Widget build(BuildContext context) {
    final info = [pet.breed, pet.sexLabel, ageOf(pet.birthDate), fmtKg(pet.weightKg), pet.color]
        .where((e) => e != null && e.isNotEmpty).join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(children: [
        PetAvatar(url: pet.photoUrl, size: 64),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(info.isEmpty ? 'Sem detalhes' : info, style: TextStyle(color: Colors.blueGrey.shade600)),
            if (pet.microchip != null) Text('Microchip: ${pet.microchip}', style: const TextStyle(fontSize: 12)),
            if (showOwner && pet.ownerName != null) Text('Dono: ${pet.ownerName}', style: const TextStyle(fontSize: 12)),
            if (pet.notes != null) Text(pet.notes!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}
