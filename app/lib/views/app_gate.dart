import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'auth/login_view.dart';
import 'owner_shell.dart';
import 'vet/vet_shell.dart';

class AppGate extends StatelessWidget {
  const AppGate({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (auth.initializing) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final u = auth.user;
    if (u == null) return const LoginView();
    return u.isVet ? VetShell(key: ValueKey(u.id)) : OwnerShell(key: ValueKey(u.id));
  }
}
