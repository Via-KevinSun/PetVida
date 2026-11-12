import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'widgets/common.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});
  @override
  Widget build(BuildContext context) {
    final u = context.watch<AuthViewModel>().user!;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(radius: 28, child: Text(u.name.isEmpty ? '?' : u.name[0].toUpperCase())),
            title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            subtitle: Text('${u.email}\n${u.isVet ? 'Veterinário' : 'Dono de pet'}'),
            isThreeLine: true,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            if (await confirm(context, 'Terminar sessão', 'Deseja sair da sua conta?', action: 'Sair')) {
              context.read<AuthViewModel>().logout();
            }
          },
          icon: const Icon(Icons.logout), label: const Text('Terminar sessão'),
        ),
      ]),
    );
  }
}
