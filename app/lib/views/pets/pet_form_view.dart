import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../viewmodels/pets_viewmodel.dart';
import '../widgets/common.dart';

class PetFormView extends StatefulWidget {
  final PetsViewModel vm;
  final Pet? pet;
  const PetFormView({super.key, required this.vm, this.pet});
  @override
  State<PetFormView> createState() => _PetFormViewState();
}

class _PetFormViewState extends State<PetFormView> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.pet?.name);
  late final _breed = TextEditingController(text: widget.pet?.breed);
  late final _color = TextEditingController(text: widget.pet?.color);
  late final _chip = TextEditingController(text: widget.pet?.microchip);
  late final _notes = TextEditingController(text: widget.pet?.notes);
  late final _weight = TextEditingController(text: widget.pet?.weightKg?.toString());
  late String? _birth = widget.pet?.birthDate;
  late String? _sex = widget.pet?.sex;
  XFile? _photo;
  bool _saving = false;

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context, firstDate: DateTime(now.year - 30), lastDate: now,
      initialDate: DateTime.tryParse(_birth ?? '') ?? now,
    );
    if (d != null) setState(() => _birth = '${d.year}-${two(d.month)}-${two(d.day)}');
  }

  String? _t(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = <String, dynamic>{
      'name': _name.text.trim(), 'breed': _t(_breed), 'birth_date': _birth, 'sex': _sex,
      'weight_kg': _weight.text.trim().isEmpty ? null : double.parse(_weight.text.trim().replaceAll(',', '.')),
      'color': _t(_color), 'microchip': _t(_chip), 'notes': _t(_notes),
      'photo_url': widget.pet?.photoUrl,
    };
    final ok = await widget.vm.save(id: widget.pet?.id, data: data, photo: _photo);
    if (!mounted) return;
    setState(() => _saving = false);
    ok ? Navigator.pop(context) : snack(context, widget.vm.error ?? 'Erro ao guardar', error: true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.pet == null ? 'Novo cão' : 'Editar ${widget.pet!.name}')),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Center(
              child: GestureDetector(
                onTap: () async {
                  final f = await pickImage(context);
                  if (f != null) setState(() => _photo = f);
                },
                child: Stack(alignment: Alignment.bottomRight, children: [
                  _photo != null
                      ? FutureBuilder(
                          future: _photo!.readAsBytes(),
                          builder: (_, s) => ClipRRect(
                            borderRadius: BorderRadius.circular(34),
                            child: SizedBox(width: 112, height: 112,
                                child: s.hasData ? Image.memory(s.data!, fit: BoxFit.cover) : const SizedBox()),
                          ))
                      : PetAvatar(url: widget.pet?.photoUrl, size: 112),
                  CircleAvatar(radius: 18, backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.camera_alt, size: 18, color: Colors.white)),
                ]),
              ),
            ),
            const SizedBox(height: 22),
            TextFormField(controller: _name, textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Introduza o nome' : null),
            const SizedBox(height: 14),
            TextFormField(controller: _breed, decoration: const InputDecoration(labelText: 'Raça')),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickBirth,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Data de nascimento', suffixIcon: Icon(Icons.calendar_today_outlined)),
                child: Text(_birth == null ? '—' : fmtDate(_birth)),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _sex, decoration: const InputDecoration(labelText: 'Sexo'),
              items: const [DropdownMenuItem(value: 'male', child: Text('Macho')), DropdownMenuItem(value: 'female', child: Text('Fêmea'))],
              onChanged: (v) => setState(() => _sex = v),
            ),
            const SizedBox(height: 14),
            TextFormField(controller: _weight, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Peso (kg)'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(v.trim().replaceAll(',', '.'));
                  return (n == null || n <= 0) ? 'Número inválido' : null;
                }),
            const SizedBox(height: 14),
            TextFormField(controller: _color, decoration: const InputDecoration(labelText: 'Cor / pelagem')),
            const SizedBox(height: 14),
            TextFormField(controller: _chip, decoration: const InputDecoration(labelText: 'Microchip (opcional)')),
            const SizedBox(height: 14),
            TextFormField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Observações')),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5)) : const Text('Guardar'),
            ),
          ]),
        ),
      );
}
