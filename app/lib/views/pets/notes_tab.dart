import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../repositories/vet_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/notes_viewmodel.dart';
import '../vet/note_form_view.dart';
import '../widgets/common.dart';

class NotesTab extends StatelessWidget {
  final String petId;
  final bool isVet;
  const NotesTab({super.key, required this.petId, required this.isVet});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (c) => NotesViewModel(c.read<VetRepository>(), petId, c.read<AuthViewModel>().user!.id)..load(),
        child: _Body(isVet: isVet),
      );
}

class _Body extends StatelessWidget {
  final bool isVet;
  const _Body({required this.isVet});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotesViewModel>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isVet
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NoteFormView(vm: vm))),
              icon: const Icon(Icons.add), label: const Text('Nova'))
          : null,
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: AsyncBody(
          loading: vm.loading, error: vm.error, isEmpty: vm.notes.isEmpty, onRetry: vm.load,
          empty: ListView(children: [
            const SizedBox(height: 80),
            EmptyState(icon: Icons.medical_information_outlined,
                message: isVet ? 'Ainda não há recomendações. Crie a primeira!' : 'Sem recomendações ou prescrições de veterinários.'),
          ]),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            itemCount: vm.notes.length,
            itemBuilder: (_, i) => _NoteCard(note: vm.notes[i], isVet: isVet),
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final VetNote note;
  final bool isVet;
  const _NoteCard({required this.note, required this.isVet});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<NotesViewModel>();
    final n = note;
    final canEdit = isVet && n.mine && n.vetActive;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: n.isPrescription ? () => _showDoses(context, vm) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Chip(label: Text(n.typeLabel), visualDensity: VisualDensity.compact),
              const Spacer(),
              if (canEdit)
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => NoteFormView(vm: vm, note: n)));
                    } else if (await confirm(context, 'Excluir', 'Excluir "${n.title}"?', action: 'Excluir')) {
                      if (!await vm.delete(n.id) && context.mounted) snack(context, vm.error!, error: true);
                    }
                  },
                  itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Editar texto')), PopupMenuItem(value: 'delete', child: Text('Excluir'))],
                ),
            ]),
            Text(n.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            if (n.content != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(n.content!)),
            if (n.isPrescription) ...[
              const Divider(height: 22),
              Text('${n.medication} · ${n.dosage}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('A cada ${n.frequencyHours}h durante ${n.durationDays} dias · ${n.totalDoses} doses', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: LinearProgressIndicator(value: (n.adherenceRate ?? 0) / 100, minHeight: 8, borderRadius: BorderRadius.circular(8))),
                const SizedBox(width: 10),
                Text(n.adherenceRate == null ? 'Sem doses vencidas' : 'Adesão ${n.adherenceRate}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
              Text(isVet ? 'Toque para ver as doses' : 'Toque para marcar as doses administradas', style: TextStyle(fontSize: 12, color: Colors.teal.shade700)),
            ],
            const SizedBox(height: 8),
            Text(
              'Dr(a). ${n.vetName} · ${fmtDate(n.createdAt.toIso8601String())}${n.vetActive ? '' : ' · veterinário desligado'}',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: n.vetActive ? Colors.blueGrey.shade500 : Colors.orange.shade800),
            ),
          ]),
        ),
      ),
    );
  }

  void _showDoses(BuildContext context, NotesViewModel vm) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(value: vm, child: _DosesSheet(note: note, canMark: !isVet)),
    );
  }
}

class _DosesSheet extends StatefulWidget {
  final VetNote note;
  final bool canMark;
  const _DosesSheet({required this.note, required this.canMark});
  @override
  State<_DosesSheet> createState() => _DosesSheetState();
}

class _DosesSheetState extends State<_DosesSheet> {
  late final Future<List<Dose>> _f = context.read<NotesViewModel>().doses(widget.note.prescriptionId!);

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        expand: false, initialChildSize: .7, maxChildSize: .92,
        builder: (_, scroll) => Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('${widget.note.medication} — doses', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: FutureBuilder<List<Dose>>(
              future: _f,
              builder: (_, s) {
                if (s.hasError) return Center(child: Text('${s.error}'));
                if (!s.hasData) return const Center(child: CircularProgressIndicator());
                return ListView(controller: scroll, children: [
                  for (final d in s.data!)
                    CheckboxListTile(
                      value: d.administered,
                      title: Text(fmtDateTime(d.at.toIso8601String())),
                      subtitle: Text(d.administered ? 'Administrada' : (d.at.isBefore(DateTime.now()) ? 'Em atraso / por marcar' : 'Agendada')),
                      onChanged: widget.canMark
                          ? (v) async {
                              try {
                                await context.read<NotesViewModel>().markDose(d, v ?? false);
                                setState(() {});
                              } catch (e) {
                                if (context.mounted) snack(context, '$e', error: true);
                              }
                            }
                          : null,
                    ),
                ]);
              },
            ),
          ),
        ]),
      );
}
