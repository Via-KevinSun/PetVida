import 'package:flutter/material.dart';
import '../../core/health_kinds.dart';
import '../../models/models.dart';
import '../health/health_list_view.dart';

class HealthTab extends StatelessWidget {
  final Pet pet;
  final bool readOnly;
  const HealthTab({super.key, required this.pet, required this.readOnly});
  @override
  Widget build(BuildContext context) => GridView.count(
        padding: const EdgeInsets.all(16), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.25,
        children: [
          for (final k in healthKinds)
            Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => HealthListView(petId: pet.id, petName: pet.name, kind: k, readOnly: readOnly))),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(k.icon, size: 36, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(k.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ]),
              ),
            ),
        ],
      );
}
