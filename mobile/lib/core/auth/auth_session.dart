import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gjendja e sesionit në memorie. Burimi i vërtetë i tokenit mbetet
/// `flutter_secure_storage`; kjo klasë shërben për mbrojtjen e rrugëve.
class AuthSession extends ChangeNotifier {
  AuthSession(this._authenticated);

  bool _authenticated;
  bool get isAuthenticated => _authenticated;

  void setAuthenticated(bool value) {
    if (_authenticated == value) return;
    _authenticated = value;
    notifyListeners();
  }
}

/// Inicializohet në main() me rezultatin e leximit të tokenit.
final authSessionProvider = Provider<AuthSession>((ref) => AuthSession(false));
