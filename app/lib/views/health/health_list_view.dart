import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/health_kinds.dart';
import '../../models/models.dart';
import '../../repositories/pet_repository.dart';
import '../../viewmodels/health_viewmodel.dart';
import '../widgets/common.dart';
import 'health_form_view.dart';

class HealthListView extends StatelessWidget {
  final String petId, petName;
  final HealthKind kind;
  final bool readOnly;
  const HealthListView({super.key, required this.petId, required this.petName, required this.kind, required this.readOnly});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (c) => HealthViewModel(c.read<PetRepository>(), petId, kind)..load(),
        child: _Body(kind: kind, readOnly: readOnly, petName: petName),
      );
}

class _Body extends StatelessWidget {
  final HealthKind kind;
  final bool readOnly;
  final String petName;
  const _Body({required this.kind, required this.readOnly, required this.petName});

  void _form(BuildContext c, HealthViewModel vm, [HealthRecord? r]) =>
      Navigator.push(c, MaterialPageRoute(builder: (_) => HealthFormView(vm: vm, record: r)));

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HealthViewModel>();
    return Scaffold(
      appBar: AppBar(title: Text('${kind.title} · $petName')),
      floatingActionButton: readOnly ? null : FloatingActionButton(onPressed: () => _form(context, vm), child: const Icon(Icons.add)),
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: AsyncBody(
          loading: vm.loading, error: vm.error, isEmpty: vm.items.isEmpty, onRetry: vm.load,
          empty: ListView(children: [
            const SizedBox(height: 100),
            EmptyState(icon: kind.icon, message: 'Sem registos de ${kind.title.toLowerCase()}.'),
          ]),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 90), children: [
            if (kind.path == 'weights' && vm.items.length >= 2)
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(height: 120, width: double.infinity,
                    child: CustomPaint(painter: _WeightChart(
                      vm.items.reversed.map((r) => (r.data['weight_kg'] as num).toDouble()).toList(),
                      Theme.of(context).colorScheme.primary))),
              )),
            for (final r in vm.items)
              Card(
                child: ListTile(
                  leading: r.data['image_url'] != null
                      ? PetAvatar(url: r.data['image_url'], size: 44)
                      : CircleAvatar(backgroundColor: Colors.teal.shade50, child: Icon(kind.icon, color: Colors.teal)),
                  title: Text(kind.titleOf(r.data), style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(kind.subtitleOf(r.data)),
                  trailing: readOnly
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') return _form(context, vm, r);
                            if (await confirm(context, 'Excluir registo', 'Deseja excluir este registo?', action: 'Excluir')) {
                              if (!await vm.delete(r.id) && context.mounted) snack(context, vm.error!, error: true);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Editar')),
                            PopupMenuItem(value: 'delete', child: Text('Excluir')),
                          ],
                        ),
                  onTap: readOnly ? null : () => _form(context, vm, r),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _WeightChart extends CustomPainter {
  final List<double> v;
  final Color color;
  _WeightChart(this.v, this.color);
  @override
  void paint(Canvas canvas, Size s) {
    final lo = v.reduce((a, b) => a < b ? a : b), hi = v.reduce((a, b) => a > b ? a : b);
    final range = (hi - lo) == 0 ? 1 : hi - lo;
    final pts = [
      for (var i = 0; i < v.length; i++) Offset(i * s.width / (v.length - 1), s.height - ((v[i] - lo) / range) * (s.height - 12) - 6)
    ];
    final line = Paint()..color = color..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..addPolygon(pts, false), line);
    for (final p in pts) {
      canvas.drawCircle(p, 4.5, Paint()..color = color);
    }
  }
  @override
  bool shouldRepaint(covariant _WeightChart o) => o.v != v;
}
