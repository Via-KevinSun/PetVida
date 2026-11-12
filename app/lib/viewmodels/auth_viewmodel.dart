import '../models/models.dart';
import '../repositories/auth_repository.dart';
import 'base_viewmodel.dart';

class AuthViewModel extends BaseViewModel {
  final AuthRepository _repo;
  AuthViewModel(this._repo);

  AppUser? user;
  bool initializing = true;

  Future<void> init() async {
    user = await _repo.restore();
    initializing = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) => run(() async => user = await _repo.login(email.trim(), password));
  Future<bool> register(String name, String email, String password, String role) =>
      run(() async => user = await _repo.register(name.trim(), email.trim(), password, role));
  Future<bool> forgot(String email) => run(() => _repo.forgot(email.trim()));
  Future<bool> reset(String email, String code, String password) => run(() => _repo.reset(email.trim(), code.trim(), password));

  Future<void> logout() async {
    await _repo.clear();
    user = null;
    notifyListeners();
  }
}
