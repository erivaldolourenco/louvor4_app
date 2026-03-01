import 'package:dio/dio.dart';
import 'package:louvor4_app/features/user_profile/data/user_repository.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/user_detail_entity.dart';

import '../../../../core/network/api_client.dart';

class UserRepositoryImpl implements UserRepository{
  final Dio _dio;
  UserRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  @override
  Future<UserDetailEntity> getUserDetail() async {
    final response = await _dio.get('/users/detail');
    return UserDetailEntity.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}