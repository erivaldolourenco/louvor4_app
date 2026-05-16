import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/create_user_input_entity.dart';
import '../../domain/exceptions/auth_request_exception.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthRepository _authRepository;

  RegisterCubit(this._authRepository) : super(const RegisterState());

  Future<bool> submit(CreateUserInputEntity input) async {
    emit(state.copyWith(status: RegisterStatus.submitting, clearError: true));

    try {
      await _authRepository.register(input);
      emit(state.copyWith(status: RegisterStatus.success, clearError: true));
      return true;
    } on AuthRequestException catch (e) {
      emit(
        state.copyWith(status: RegisterStatus.failure, errorMessage: e.message),
      );
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          errorMessage: 'Não foi possível criar sua conta.',
        ),
      );
      return false;
    }
  }
}
