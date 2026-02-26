import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository _authRepository;

  LoginCubit(this._authRepository) : super(const LoginState());

  void usernameChanged(String v) => emit(state.copyWith(username: v));
  void passwordChanged(String v) => emit(state.copyWith(password: v));

  Future<void> submit() async {
    if (state.username.trim().isEmpty || state.password.isEmpty) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: 'Informe usuário e senha',
      ));
      return;
    }

    emit(state.copyWith(status: LoginStatus.loading, errorMessage: null));

    try {
      final auth = await _authRepository.login(
        state.username.trim(),
        state.password,
      );

      emit(state.copyWith(status: LoginStatus.success, auth: auth));
    } catch (e) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }
}