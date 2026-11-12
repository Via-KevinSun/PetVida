import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PetAvatar extends StatelessWidget {
  final String? url;
  final double size;
  const PetAvatar({super.key, this.url, this.size = 56});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(size / 3),
        child: Container(
          width: size, height: size, color: Colors.teal.shade50,
          child: url == null
              ? Icon(Icons.pets_rounded, size: size * .5, color: Colors.teal.shade300)
              : CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Icon(Icons.broken_image_outlined, color: Colors.teal.shade300)),
        ),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.message, this.action});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 64, color: Colors.teal.shade200),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 15)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ]),
        ),
      );
}

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => EmptyState(
        icon: Icons.cloud_off_rounded, message: message,
        action: OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Tentar de novo')),
      );
}

/// Corpo padrão: loading / erro / vazio / conteúdo.
class AsyncBody extends StatelessWidget {
  final bool loading, isEmpty;
  final String? error;
  final VoidCallback onRetry;
  final Widget empty;
  final Widget child;
  const AsyncBody({super.key, required this.loading, required this.error, required this.isEmpty,
      required this.onRetry, required this.empty, required this.child});
  @override
  Widget build(BuildContext context) {
    if (loading && isEmpty) return const Center(child: CircularProgressIndicator());
    if (error != null && isEmpty) return ErrorView(message: error!, onRetry: onRetry);
    if (isEmpty) return empty;
    return child;
  }
}

void snack(BuildContext c, String msg, {bool error = false}) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg), behavior: SnackBarBehavior.floating,
      backgroundColor: error ? Colors.red.shade400 : null,
    ));
}

Future<bool> confirm(BuildContext c, String title, String body, {String action = 'Confirmar'}) async =>
    await showDialog<bool>(
      context: c,
      builder: (_) => AlertDialog(
        title: Text(title), content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(90, 42)),
              onPressed: () => Navigator.pop(c, true), child: Text(action)),
        ],
      ),
    ) ?? false;

Future<XFile?> pickImage(BuildContext c) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: c,
    builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Galeria'),
            onTap: () => Navigator.pop(c, ImageSource.gallery)),
        ListTile(leading: const Icon(Icons.photo_camera_outlined), title: const Text('Câmara'),
            onTap: () => Navigator.pop(c, ImageSource.camera)),
      ]),
    ),
  );
  if (source == null) return null;
  return ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
}
