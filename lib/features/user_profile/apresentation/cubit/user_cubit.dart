import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:louvor4_app/features/user_profile/apresentation/cubit/user_state.dart';
import 'package:louvor4_app/features/user_profile/data/user_repository.dart';

class UserCubit  extends Cubit<UserState>{
  final UserRepository _userRepo;

  UserCubit(this._userRepo) : super(const UserState());

  Future<void> load() async {
    emit(state.copyWith(status: UserStatus.loading));
    try {
      final user = await _userRepo.getUserDetail();
      emit(state.copyWith(status: UserStatus.success, user: user));
    } catch (e) {
      emit(state.copyWith(
        status: UserStatus.failure,
        errorMessage: 'Não foi possível carregar os detalhes do Usuario.',
      ));
    }
  }

}