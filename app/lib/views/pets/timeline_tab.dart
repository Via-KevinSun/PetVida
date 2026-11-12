import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../repositories/pet_repository.dart';
import '../../viewmodels/timeline_viewmodel.dart';
import '../widgets/common.dart';

const _icons = {
  'vaccine': Icons.vaccines_rounded, 'weight': Icons.monitor_weight_rounded, 'symptom': Icons.healing_rounded,
  'diet': Icons.restaurant_rounded, 'prescription': Icons.medication_rounded, 'recommendation': Icons.tips_and_updates_rounded,
  'suggestion': Icons.lightbulb_outline_rounded, 'image': Icons.photo_rounded,
};

class TimelineTab extends StatelessWidget {
  final String petId;
  const TimelineTab({super.key, required this.petId});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (c) => TimelineViewModel(c.read<PetRepository>(), petId)..load(),
        child: const _Body(),
      );
}

class _Body extends StatelessWidget {
  const _Body();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TimelineViewModel>();
    final c = Theme.of(context).colorScheme;
    return Column(children: [
      SizedBox(
        height: 52,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
          Padding(padding: const EdgeInsets.all(4), child: ChoiceChip(label: const Text('Tudo'), selected: vm.selected.isEmpty, onSelected: (_) => vm.clear())),
          for (final e in TimelineViewModel.filters.entries)
            Padding(
              padding: const EdgeInsets.all(4),
              child: FilterChip(label: Text(e.value), selected: vm.selected.contains(e.key), onSelected: (_) => vm.toggle(e.key)),
            ),
        ]),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: vm.load,
          child: AsyncBody(
            loading: vm.loading, error: vm.error, isEmpty: vm.events.isEmpty, onRetry: vm.load,
            empty: ListView(children: const [SizedBox(height: 80), EmptyState(icon: Icons.timeline, message: 'A timeline ainda está vazia.')]),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: vm.events.length,
              itemBuilder: (_, i) {
                final e = vm.events[i];
                return IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Column(children: [
                      CircleAvatar(radius: 18, backgroundColor: c.primaryContainer, child: Icon(_icons[e.kind], size: 18, color: c.primary)),
                      if (i < vm.events.length - 1) Expanded(child: Container(width: 2, color: Colors.teal.shade50)),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(fmtDateTime(e.at.toIso8601String()), style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400)),
                            const SizedBox(height: 2),
                            Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            if (e.description != null && e.description!.isNotEmpty) Text(e.description!),
                            if (e.vetName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'Dr(a). ${e.vetName}${e.vetActive == false ? ' · veterinário desligado' : ''}',
                                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: e.vetActive == false ? Colors.orange.shade800 : Colors.blueGrey.shade500),
                                ),
                              ),
                            if (e.imageUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: ClipRRect(borderRadius: BorderRadius.circular(12),
                                    child: Image.network(e.imageUrl!, height: 150, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 60, child: Icon(Icons.broken_image_outlined)))),
                              ),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                );
              },
            ),
          ),
        ),
      ),
    ]);
  }
}
