import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../viewmodels/notes_viewmodel.dart';
import '../widgets/common.dart';

/// Criar recomendação/sugestão/prescrição. Ao editar, só título e texto mudam.
class NoteFormView extends StatefulWidget {
  final NotesViewModel vm;
  final VetNote? note;
  const NoteFormView({super.key, required this.vm, this.note});
  @override
  State<NoteFormView> createState() => _NoteFormViewState();
}

class _NoteFormViewState extends State<NoteFormView> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.note?.title);
  late final _content = TextEditingController(text: widget.note?.content);
  final _med = TextEditingController(), _dose = TextEditingController();
  final _freq = TextEditingController(text: '8'), _days = TextEditingController(text: '7');
  late String _type = widget.note?.type ?? 'recommendation';
  bool _saving = false;

  bool get _editing => widget.note != null;
  bool get _rx => _type == 'prescription';

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final c = _content.text.trim().isEmpty ? null : _content.text.trim();
    final ok = _editing
        ? await widget.vm.update(widget.note!.id, _title.text.trim(), c)
        : await widget.vm.create({
            'type': _type, 'title': _title.text.trim(), 'content': c,
            if (_rx) ...{
              'medication': _med.text.trim(), 'dosage': _dose.text.trim(),
              'frequency_hours': int.parse(_freq.text), 'duration_days': int.parse(_days.text),
              'start_at': DateTime.now().toUtc().toIso8601String(),
            },
          });
    if (!mounted) return;
    setState(() => _saving = false);
    ok ? Navigator.pop(context) : snack(context, widget.vm.error ?? 'Erro ao guardar', error: true);
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null;
  String? _int(String? v, int lo, int hi) {
    final n = int.tryParse(v ?? '');
    return (n == null || n < lo || n > hi) ? 'Entre $lo e $hi' : null;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(_editing ? 'Editar ${widget.note!.typeLabel.toLowerCase()}' : 'Nova entrada')),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            if (!_editing) ...[
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'recommendation', label: Text('Recomend.')),
                  ButtonSegment(value: 'suggestion', label: Text('Sugestão')),
                  ButtonSegment(value: 'prescription', label: Text('Prescrição')),
                ],
                selected: {_type}, onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 18),
            ],
            TextFormField(controller: _title, validator: _req, textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Título *')),
            const SizedBox(height: 14),
            TextFormField(controller: _content, maxLines: 4, textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Detalhes / instruções')),
            if (_rx && !_editing) ...[
              const SizedBox(height: 14),
              TextFormField(controller: _med, validator: _req, decoration: const InputDecoration(labelText: 'Medicamento *')),
              const SizedBox(height: 14),
              TextFormField(controller: _dose, validator: _req, decoration: const InputDecoration(labelText: 'Dosagem * (ex.: 1 comprimido)')),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextFormField(controller: _freq, keyboardType: TextInputType.number, validator: (v) => _int(v, 1, 168),
                    decoration: const InputDecoration(labelText: 'A cada (horas)'))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _days, keyboardType: TextInputType.number, validator: (v) => _int(v, 1, 365),
                    decoration: const InputDecoration(labelText: 'Duração (dias)'))),
              ]),
              const SizedBox(height: 8),
              Text('As doses são geradas automaticamente a partir de agora.', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade500)),
            ],
            if (_rx && _editing)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Medicamento, dosagem e duração não podem ser alterados. Para mudar, exclua e crie nova prescrição.',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade500)),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5)) : const Text('Guardar'),
            ),
          ]),
        ),
      );
}
