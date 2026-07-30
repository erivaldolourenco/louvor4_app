import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  // Web Client ID (serverClientId): usado para que o idToken gerado tenha
  // audiência validável pelo backend (GOOGLE_OAUTH_CLIENT_IDS). Configurar
  // via --dart-define=GOOGLE_WEB_CLIENT_ID=<id>.
  static const _serverClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
    );
    _initialized = true;
  }

  /// Retorna o idToken do usuário autenticado, ou `null` se o usuário
  /// cancelou o fluxo de sign-in.
  Future<String?> signInAndGetIdToken() async {
    await _ensureInitialized();

    try {
      final account = await GoogleSignIn.instance.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }
}
