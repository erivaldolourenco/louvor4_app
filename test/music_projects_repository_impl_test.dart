import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/music_projects/data/impl/music_projects_repository_impl.dart';

void main() {
  group('MusicProjectsRepositoryImpl', () {
    late Dio dio;
    late MusicProjectsRepositoryImpl repository;

    setUp(() {
      dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/users/music-projects') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  data: [
                    {'id': '1', 'name': 'Banda Teste', 'type': 'BAND'},
                  ],
                ),
              );
            }

            if (options.path == '/music-project/1') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  data: {'id': '1', 'name': 'Projeto 1', 'type': 'MINISTRY'},
                ),
              );
            }

            if (options.path == '/music-project/1/member-role') {
              return handler.resolve(
                Response(requestOptions: options, data: {'role': 'ADMIN'}),
              );
            }

            if (options.path == '/music-project/2/member-role') {
              return handler.resolve(
                Response(requestOptions: options, data: 'owner'),
              );
            }

            return handler.reject(
              DioException(
                requestOptions: options,
                response: Response(requestOptions: options, statusCode: 404),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

      repository = MusicProjectsRepositoryImpl(dio: dio);
    });

    test('getUserMusicProjects retorna lista mapeada', () async {
      final projects = await repository.getUserMusicProjects();

      expect(projects, hasLength(1));
      expect(projects.first.id, '1');
      expect(projects.first.name, 'Banda Teste');
    });

    test('getProjectById retorna projeto mapeado', () async {
      final project = await repository.getProjectById('1');

      expect(project.id, '1');
      expect(project.name, 'Projeto 1');
    });

    test('getMemberRole aceita resposta em map e string', () async {
      final roleMap = await repository.getMemberRole('1');
      final roleString = await repository.getMemberRole('2');

      expect(roleMap, 'ADMIN');
      expect(roleString, 'OWNER');
    });

    test('getProjectMembers e getProjectSkills extraem detail em erro', () async {
      final failingDio = Dio();
      failingDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 400,
                  data: {'detail': 'falha detalhada'},
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          },
        ),
      );

      final failingRepository = MusicProjectsRepositoryImpl(dio: failingDio);

      expect(
        () => failingRepository.getProjectMembers('1'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('falha detalhada'),
          ),
        ),
      );
      expect(
        () => failingRepository.getProjectSkills('1'),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('falha detalhada'),
          ),
        ),
      );
    });
  });
}
