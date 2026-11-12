import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/format.dart';
import '../../core/health_kinds.dart';
import '../../models/models.dart';
import '../../viewmodels/health_viewmodel.dart';
import '../widgets/common.dart';

/// Formulário gerado a partir dos FieldSpec do tipo de registo (criar e editar).
class HealthFormView extends StatefulWidget {
  final HealthViewModel vm;
  final HealthRecord? record;
  const HealthFormView({super.key, required this.vm, this.record});
  @override
  State<HealthFormView> createState() => _HealthFormViewState();
}

class _HealthFormViewState extends State<HealthFormView> {
  final _form = GlobalKey<FormState>();
  final _ctrl = <String, TextEditingController>{};
  final _raw = <String, String?>{}; // valor enviado à API (datas, horas, escolhas, dias)
  XFile? _photo;
  bool _saving = false;

  HealthKind get kind => widget.vm.kind;

  @override
  void initState() {
    super.initState();
    final d = widget.record?.data ?? {};
    final now = DateTime.now();
    for (final f in kind.fields) {
      final v = d[f.key];
      _ctrl[f.key] = TextEditingController();
      switch (f.type) {
        case FieldType.date:
          _setDate(f, v ?? (widget.record == null && f.required ? '${now.year}-${two(now.month)}-${two(now.day)}' : null));
        case FieldType.datetime:
          _setDateTime(f, v != null ? DateTime.parse(v).toLocal() : (f.required ? now : null));
        case FieldType.time:
        case FieldType.choice:
        case FieldType.weekdays:
          _raw[f.key] = v?.toString();
          _ctrl[f.key]!.text = f.type == FieldType.choice ? (f.options?[v] ?? '') : (v?.toString() ?? '');
        default:
          _ctrl[f.key]!.text = v?.toString() ?? '';
      }
    }
  }

  void _setDate(FieldSpec f, String? iso) {
    _raw[f.key] = iso;
    _ctrl[f.key]!.text = fmtDate(iso);
  }

  void _setDateTime(FieldSpec f, DateTime? d) {
    _raw[f.key] = d?.toUtc().toIso8601String();
    _ctrl[f.key]!.text = d == null ? '' : fmtDateTime(d.toIso8601String());
  }

  Future<void> _pick(FieldSpec f) async {
    final now = DateTime.now();
    if (f.type == FieldType.time) {
      final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (t != null) setState(() {
        _raw[f.key] = '${two(t.hour)}:${two(t.minute)}';
        _ctrl[f.key]!.text = _raw[f.key]!;
      });
      return;
    }
    final d = await showDatePicker(context: context, firstDate: DateTime(now.year - 20), lastDate: DateTime(now.year + 5),
        initialDate: DateTime.tryParse(_raw[f.key] ?? '')?.toLocal() ?? now);
    if (d == null) return;
    if (f.type == FieldType.date) return setState(() => _setDate(f, '${d.year}-${two(d.month)}-${two(d.day)}'));
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
    if (t != null) setState(() => _setDateTime(f, DateTime(d.year, d.month, d.day, t.hour, t.minute)));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final body = <String, dynamic>{};
    for (final f in kind.fields) {
      final text = _ctrl[f.key]!.text.trim();
      switch (f.type) {
        case FieldType.text:
        case FieldType.multiline:
          body[f.key] = text.isEmpty ? null : text;
        case FieldType.number:
          body[f.key] = double.parse(text.replaceAll(',', '.'));
        default:
          body[f.key] = (_raw[f.key] == null || _raw[f.key]!.isEmpty) ? null : _raw[f.key];
      }
    }
    if (kind.hasImage) body['image_url'] = widget.record?.data['image_url'];
    setState(() => _saving = true);
    final ok = await widget.vm.save(body, id: widget.record?.id, photo: _photo);
    if (!mounted) return;
    setState(() => _saving = false);
    ok ? Navigator.pop(context) : snack(context, widget.vm.error ?? 'Erro ao guardar', error: true);
  }

  Widget _field(FieldSpec f) {
    final label = f.required ? '${f.label} *' : f.label;
    String? req(String? v) => f.required && (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null;
    switch (f.type) {
      case FieldType.date:
      case FieldType.datetime:
      case FieldType.time:
        return TextFormField(
          controller: _ctrl[f.key], readOnly: true, onTap: () => _pick(f), validator: req,
          decoration: InputDecoration(labelText: label, suffixIcon: Icon(f.type == FieldType.time ? Icons.access_time : Icons.calendar_today_outlined)),
        );
      case FieldType.choice:
        return DropdownButtonFormField<String>(
          value: _raw[f.key], decoration: InputDecoration(labelText: label),
          items: [for (final e in f.options!.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
          onChanged: (v) => _raw[f.key] = v,
        );
      case FieldType.weekdays:
        final sel = (_raw[f.key] ?? '').split(',').where((e) => e.isNotEmpty).toSet();
        return InputDecorator(
          decoration: InputDecoration(labelText: '${f.label} (vazio = todos)'),
          child: Wrap(spacing: 6, children: [
            for (final e in weekdayLabels.entries)
              FilterChip(
                label: Text(e.value), selected: sel.contains(e.key),
                onSelected: (on) => setState(() {
                  on ? sel.add(e.key) : sel.remove(e.key);
                  final l = sel.toList()..sort();
                  _raw[f.key] = l.isEmpty ? null : l.join(',');
                }),
              ),
          ]),
        );
      case FieldType.number:
        return TextFormField(
          controller: _ctrl[f.key], keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
          validator: (v) {
            final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
            return (n == null || n <= 0) ? 'Número inválido' : null;
          },
        );
      default:
        return TextFormField(
          controller: _ctrl[f.key], maxLines: f.type == FieldType.multiline ? 3 : 1, validator: req,
          textCapitalization: TextCapitalization.sentences, decoration: InputDecoration(labelText: label),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('${widget.record == null ? 'Novo' : 'Editar'} ${kind.singular}')),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            for (final f in kind.fields) ...[_field(f), const SizedBox(height: 14)],
            if (kind.hasImage)
              OutlinedButton.icon(
                onPressed: () async {
                  final p = await pickImage(context);
                  if (p != null) setState(() => _photo = p);
                },
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(_photo != null ? 'Foto selecionada: ${_photo!.name}' : (widget.record?.data['image_url'] != null ? 'Substituir foto' : 'Adicionar foto (opcional)')),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5)) : const Text('Guardar'),
            ),
          ]),
        ),
      );
}
