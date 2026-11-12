import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/pet_repository.dart';
import '../../viewmodels/gallery_viewmodel.dart';
import '../widgets/common.dart';

class GalleryTab extends StatelessWidget {
  final String petId;
  final bool readOnly;
  const GalleryTab({super.key, required this.petId, required this.readOnly});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (c) => GalleryViewModel(c.read<PetRepository>(), petId)..load(),
        child: _Body(readOnly: readOnly),
      );
}

class _Body extends StatelessWidget {
  final bool readOnly;
  const _Body({required this.readOnly});

  Future<void> _add(BuildContext context, GalleryViewModel vm) async {
    final f = await pickImage(context);
    if (f == null) return;
    if (!await vm.add(f, null) && context.mounted) snack(context, vm.error!, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GalleryViewModel>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: readOnly ? null : FloatingActionButton(onPressed: () => _add(context, vm), child: const Icon(Icons.add_a_photo_outlined)),
      body: Stack(children: [
        AsyncBody(
          loading: vm.loading, error: vm.error, isEmpty: vm.images.isEmpty, onRetry: vm.load,
          empty: const EmptyState(icon: Icons.photo_library_outlined, message: 'Ainda não há fotos.'),
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 160, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: vm.images.length,
            itemBuilder: (_, i) {
              final img = vm.images[i];
              return GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => Dialog(child: InteractiveViewer(child: Image.network(img.url))),
                ),
                onLongPress: readOnly
                    ? null
                    : () async {
                        if (await confirm(context, 'Excluir foto', 'Deseja excluir esta foto?', action: 'Excluir')) vm.delete(img.id);
                      },
                child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(img.url, fit: BoxFit.cover)),
              );
            },
          ),
        ),
        if (vm.loading && vm.images.isNotEmpty) const Align(alignment: Alignment.topCenter, child: LinearProgressIndicator()),
      ]),
    );
  }
}
