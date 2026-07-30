import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/auth/google_auth_service.dart';
import '../../domain/exceptions/auth_request_exception.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _authRepository;

  LoginCubit(this._authRepository) : super(const LoginState());

  void usernameChanged(String v) => emit(state.copyWith(username: v));
  void passwordChanged(String v) => emit(state.copyWith(password: v));

  Future<void> submit() async {
    if (state.username.trim().isEmpty || state.password.isEmpty) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'Informe usuário e senha',
          errorStatusCode: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: LoginStatus.loading,
        method: LoginMethod.password,
        errorMessage: null,
        errorStatusCode: null,
      ),
    );

    try {
      final auth = await _authRepository.login(
        state.username.trim(),
        state.password,
      );

      emit(state.copyWith(status: LoginStatus.success, auth: auth));
    } on AuthRequestException catch (e) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: e.message,
          errorStatusCode: e.statusCode,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
          errorStatusCode: null,
        ),
      );
    }
  }

  Future<void> loginWithGoogle() async {
    emit(
      state.copyWith(
        status: LoginStatus.loading,
        method: LoginMethod.google,
        errorMessage: null,
        errorStatusCode: null,
      ),
    );

    try {
      final idToken = await GoogleAuthService.instance.signInAndGetIdToken();
      if (idToken == null) {
        emit(state.copyWith(status: LoginStatus.initial));
        return;
      }

      final auth = await _authRepository.loginWithGoogle(idToken);

      emit(state.copyWith(status: LoginStatus.success, auth: auth));
    } on AuthRequestException catch (e) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: e.message,
          errorStatusCode: e.statusCode,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
          errorStatusCode: null,
        ),
      );
    }
  }
}
