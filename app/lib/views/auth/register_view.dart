import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/common.dart';
import 'login_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});
  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController(), _pass = TextEditingController();
  String _role = 'owner';

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    if (await vm.register(_name.text, _email.text, _pass.text, _role)) {
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } else if (mounted) {
      snack(context, vm.error!, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return AuthScaffold(
      title: 'Criar conta', subtitle: 'Escolha o seu perfil (não poderá ter os dois)',
      children: [
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'owner', label: Text('Dono do pet'), icon: Icon(Icons.pets)),
            ButtonSegment(value: 'vet', label: Text('Veterinário'), icon: Icon(Icons.medical_services_outlined)),
          ],
          selected: {_role}, onSelectionChanged: (s) => setState(() => _role = s.first),
        ),
        const SizedBox(height: 18),
        Form(
          key: _form,
          child: Column(children: [
            TextFormField(controller: _name, textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Introduza o nome' : null),
            const SizedBox(height: 14),
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline)),
                validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null),
            const SizedBox(height: 14),
            TextFormField(controller: _pass, obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha (mín. 8 caracteres)', prefixIcon: Icon(Icons.lock_outline)),
                validator: (v) => (v == null || v.length < 8) ? 'Mínimo 8 caracteres' : null),
          ]),
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: vm.loading ? null : _submit,
          child: vm.loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5)) : const Text('Criar conta'),
        ),
      ],
    );
  }
}
