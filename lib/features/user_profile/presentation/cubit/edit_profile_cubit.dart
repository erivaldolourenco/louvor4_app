import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/user_repository.dart';
import '../../domain/entities/update_user_input_entity.dart';
import '../../domain/entities/user_detail_entity.dart';
import 'edit_profile_state.dart';

class EditProfileCubit extends Cubit<EditProfileState> {
  final UserRepository _repository;

  EditProfileCubit(this._repository) : super(const EditProfileState());

  Future<void> loadProfile() async {
    emit(
      state.copyWith(
        status: EditProfileStatus.loadingProfile,
        clearErrorMessage: true,
      ),
    );

    try {
      final user = await _repository.getUserDetail();
      emit(
        state.copyWith(
          status: EditProfileStatus.editing,
          user: user,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: EditProfileStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<UserDetailEntity?> submit(UpdateUserInputEntity input) async {
    emit(
      state.copyWith(
        status: EditProfileStatus.submitting,
        clearErrorMessage: true,
      ),
    );

    try {
      final user = await _repository.updateUserProfile(input);
      emit(
        state.copyWith(
          status: EditProfileStatus.success,
          user: user,
          clearErrorMessage: true,
        ),
      );
      return user;
    } catch (e) {
      emit(
        state.copyWith(
          status: EditProfileStatus.error,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return null;
    }
  }
}
