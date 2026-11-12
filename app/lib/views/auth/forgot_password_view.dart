import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/common.dart';
import 'login_view.dart';

/// Passo 1: pedir código por e-mail. Passo 2: código + nova senha.
class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});
  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _email = TextEditingController(), _code = TextEditingController(), _pass = TextEditingController();
  bool _codeSent = false;

  Future<void> _send() async {
    if (!_email.text.contains('@')) return snack(context, 'Introduza um e-mail válido', error: true);
    final vm = context.read<AuthViewModel>();
    if (await vm.forgot(_email.text)) {
      setState(() => _codeSent = true);
      if (mounted) snack(context, 'Se o e-mail existir, enviámos um código.');
    } else if (mounted) {
      snack(context, vm.error!, error: true);
    }
  }

  Future<void> _reset() async {
    if (_code.text.trim().length != 6) return snack(context, 'O código tem 6 dígitos', error: true);
    if (_pass.text.length < 8) return snack(context, 'A senha deve ter pelo menos 8 caracteres', error: true);
    final vm = context.read<AuthViewModel>();
    if (await vm.reset(_email.text, _code.text, _pass.text)) {
      if (mounted) {
        snack(context, 'Senha atualizada! Já pode entrar.');
        Navigator.pop(context);
      }
    } else if (mounted) {
      snack(context, vm.error!, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthViewModel>().loading;
    return AuthScaffold(
      title: 'Recuperar senha',
      subtitle: _codeSent ? 'Introduza o código recebido e a nova senha' : 'Enviaremos um código para o seu e-mail',
      children: [
        TextField(controller: _email, enabled: !_codeSent, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline))),
        if (_codeSent) ...[
          const SizedBox(height: 14),
          TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 6,
              decoration: const InputDecoration(labelText: 'Código de 6 dígitos', prefixIcon: Icon(Icons.pin_outlined))),
          TextField(controller: _pass, obscureText: true,
              decoration: const InputDecoration(labelText: 'Nova senha', prefixIcon: Icon(Icons.lock_outline))),
        ],
        const SizedBox(height: 22),
        FilledButton(onPressed: loading ? null : (_codeSent ? _reset : _send), child: Text(_codeSent ? 'Redefinir senha' : 'Enviar código')),
        if (_codeSent) TextButton(onPressed: loading ? null : _send, child: const Text('Reenviar código')),
      ],
    );
  }
}
