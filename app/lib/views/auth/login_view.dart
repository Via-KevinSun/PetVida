import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/common.dart';
import 'forgot_password_view.dart';
import 'register_view.dart';

class AuthScaffold extends StatelessWidget {
  final String title, subtitle;
  final List<Widget> children;
  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.children});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: Navigator.canPop(context) ? AppBar() : null,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Icon(Icons.pets_rounded, size: 56, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey.shade500)),
                  const SizedBox(height: 28),
                  ...children,
                ]),
              ),
            ),
          ),
        ),
      );
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _pass = TextEditingController();
  bool _hide = true;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    if (!await vm.login(_email.text, _pass.text) && mounted) snack(context, vm.error!, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return AuthScaffold(
      title: 'PetVida', subtitle: 'Cuide bem do seu melhor amigo',
      children: [
        Form(
          key: _form,
          child: Column(children: [
            TextFormField(
              controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline)),
              validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pass, obscureText: _hide, onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Senha', prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _hide = !_hide)),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Introduza a senha' : null,
            ),
          ]),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordView())),
            child: const Text('Esqueci a senha'),
          ),
        ),
        FilledButton(
          onPressed: vm.loading ? null : _submit,
          child: vm.loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5)) : const Text('Entrar'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterView())),
          child: const Text('Ainda não tem conta? Criar conta'),
        ),
      ],
    );
  }
}
