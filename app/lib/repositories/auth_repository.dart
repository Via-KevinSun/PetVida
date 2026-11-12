import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/models.dart';

class AuthRepository {
  final ApiClient api;
  AuthRepository(this.api);
  static const _key = 'petvida_token';

  Future<AppUser?> restore() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString(_key);
    if (t == null) return null;
    api.token = t;
    try {
      return AppUser.fromJson((await api.get('/auth/me'))['user']);
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<AppUser> _session(dynamic r) async {
    api.token = r['token'];
    (await SharedPreferences.getInstance()).setString(_key, r['token']);
    return AppUser.fromJson(r['user']);
  }

  Future<AppUser> login(String email, String password) async =>
      _session(await api.post('/auth/login', {'email': email, 'password': password}));

  Future<AppUser> register(String name, String email, String password, String role) async =>
      _session(await api.post('/auth/register', {'name': name, 'email': email, 'password': password, 'role': role}));

  Future<void> forgot(String email) => api.post('/auth/forgot-password', {'email': email});
  Future<void> reset(String email, String code, String password) =>
      api.post('/auth/reset-password', {'email': email, 'code': code, 'password': password});

  Future<void> clear() async {
    api.token = null;
    (await SharedPreferences.getInstance()).remove(_key);
  }
}
