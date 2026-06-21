import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';
import '../../domain/exceptions/auth_request_exception.dart';
import 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository _repo;

  ForgotPasswordCubit(this._repo) : super(const ForgotPasswordState());

  void identifierChanged(String v) => emit(state.copyWith(identifier: v));
  void selectChannel(String channel) => emit(state.copyWith(selectedChannel: channel));
  void codeChanged(String v) => emit(state.copyWith(code: v));
  void newPasswordChanged(String v) => emit(state.copyWith(newPassword: v));

  Future<void> loadChannels() async {
    final identifier = state.identifier.trim();
    if (identifier.isEmpty) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: 'Informe seu e-mail ou nome de usuário.',
      ));
      return;
    }

    emit(state.copyWith(status: ForgotPasswordStatus.loading, errorMessage: null));

    try {
      final channels = await _repo.getAvailableChannels(identifier);
      emit(state.copyWith(
        status: ForgotPasswordStatus.channelsLoaded,
        step: 2,
        channels: channels,
        selectedChannel: 'EMAIL',
      ));
    } on AuthRequestException catch (e) {
      emit(state.copyWith(status: ForgotPasswordStatus.failure, errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> sendCode() async {
    emit(state.copyWith(status: ForgotPasswordStatus.loading, errorMessage: null));

    try {
      await _repo.forgotPassword(
        identifier: state.identifier.trim(),
        channel: state.selectedChannel,
      );
      emit(state.copyWith(status: ForgotPasswordStatus.codeSent, step: 3));
    } on AuthRequestException catch (e) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: e.message,
        step: 2,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        step: 2,
      ));
    }
  }

  Future<void> resetPassword() async {
    final code = state.code.trim();
    final newPassword = state.newPassword;

    if (code.length != 6 || newPassword.isEmpty) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: 'Informe o código de 6 dígitos e a nova senha.',
        step: 3,
      ));
      return;
    }

    if (newPassword.length < 6) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: 'A senha deve ter no mínimo 6 caracteres.',
        step: 3,
      ));
      return;
    }

    emit(state.copyWith(status: ForgotPasswordStatus.loading, errorMessage: null, step: 3));

    try {
      await _repo.resetPassword(
        identifier: state.identifier.trim(),
        code: code,
        newPassword: newPassword,
      );
      emit(state.copyWith(status: ForgotPasswordStatus.success));
    } on AuthRequestException catch (e) {
      emit(state.copyWith(status: ForgotPasswordStatus.failure, errorMessage: e.message, step: 3));
    } catch (e) {
      emit(state.copyWith(
        status: ForgotPasswordStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
        step: 3,
      ));
    }
  }
}
