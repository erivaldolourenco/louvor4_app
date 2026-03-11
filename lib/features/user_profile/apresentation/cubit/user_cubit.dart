import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:louvor4_app/features/user_profile/apresentation/cubit/user_state.dart';
import 'package:louvor4_app/features/user_profile/data/user_repository.dart';

class UserCubit extends Cubit<UserState> {
  final UserRepository _userRepo;

  UserCubit(this._userRepo) : super(const UserState());

  Future<void> load() async {
    emit(state.copyWith(status: UserStatus.loading, clearErrorMessage: true));
    try {
      final user = await _userRepo.getUserDetail();
      emit(
        state.copyWith(
          status: UserStatus.success,
          user: user,
          clearErrorMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: UserStatus.failure,
          errorMessage: 'Não foi possível carregar os detalhes do Usuario.',
        ),
      );
    }
  }

  Future<bool> updateProfileImage({
    required String filePath,
    required String fileName,
  }) async {
    emit(state.copyWith(isUploadingImage: true, clearErrorMessage: true));

    try {
      final imageUrl = await _userRepo.updateProfileImage(
        filePath: filePath,
        fileName: fileName,
      );
      final currentUser = state.user;

      emit(
        state.copyWith(
          user: currentUser?.copyWith(profileImage: imageUrl),
          isUploadingImage: false,
          clearErrorMessage: true,
        ),
      );
      return true;
    } catch (_) {
      emit(
        state.copyWith(
          isUploadingImage: false,
          errorMessage: 'Não foi possível atualizar a imagem do perfil.',
        ),
      );
      return false;
    }
  }
}
