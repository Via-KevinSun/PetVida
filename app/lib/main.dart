import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/notification_service.dart';
import 'core/theme.dart';
import 'repositories/auth_repository.dart';
import 'repositories/pet_repository.dart';
import 'repositories/vet_repository.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/app_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  runApp(MultiProvider(
    providers: [
      Provider<NotificationService>(create: (_) => NotificationService()),
      Provider<AuthRepository>(create: (_) => AuthRepository(api)),
      Provider<PetRepository>(create: (_) => PetRepository(api)),
      Provider<VetRepository>(create: (_) => VetRepository(api)),
      ChangeNotifierProvider<AuthViewModel>(create: (c) {
        final vm = AuthViewModel(c.read<AuthRepository>());
        api.onUnauthorized = vm.logout; // sessão expirada -> volta ao login
        vm.init();
        return vm;
      }),
    ],
    child: const PetVidaApp(),
  ));
}

class PetVidaApp extends StatelessWidget {
  const PetVidaApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'PetVida',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AppGate(),
      );
}
