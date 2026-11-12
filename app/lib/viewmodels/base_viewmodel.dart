import 'package:flutter/foundation.dart';

class BaseViewModel extends ChangeNotifier {
  bool loading = false;
  String? error;
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Executa uma ação com estado de loading/erro. Devolve true se correu bem.
  Future<bool> run(Future<void> Function() action, {bool showLoading = true}) async {
    if (showLoading) loading = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
