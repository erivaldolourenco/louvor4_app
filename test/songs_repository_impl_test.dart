import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/songs/data/impl/songs_repository_impl.dart';
import 'package:louvor4_app/features/songs/domain/entities/song_entity.dart';

void main() {
  group('SongsRepositoryImpl', () {
    late Dio dio;
    late SongsRepositoryImpl repository;

    setUp(() {
      dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/users/songs') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  data: [
                    {
                      'id': 's1',
                      'artist': 'Artist A',
                      'title': 'Song A',
                      'key': 'C#m',
                      'youTubeUrl': 'https://youtube.com/watch?v=12345678901',
                    },
                  ],
                ),
              );
            }

            if (options.path == '/songs/create') {
              final body = options.data as Map<String, dynamic>;
              if (body['title'] == 'Erro') {
                return handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response(
                      requestOptions: options,
                      statusCode: 400,
                      data: {'message': 'Título inválido'},
                    ),
                    type: DioExceptionType.badResponse,
                  ),
                );
              }

              return handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    'id': 'created-1',
                    'artist': body['artist'],
                    'title': body['title'],
                    'key': body['key'],
                    'bpm': body['bpm'],
                    'youTubeUrl': body['youTubeUrl'],
                  },
                ),
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

      repository = SongsRepositoryImpl(dio: dio);
    });

    test('getUserSongs retorna lista mapeada', () async {
      final songs = await repository.getUserSongs();

      expect(songs, hasLength(1));
      expect(songs.first.id, 's1');
      expect(songs.first.title, 'Song A');
    });

    test('createSong retorna música criada', () async {
      const payload = SongEntity(
        artist: 'Artist B',
        title: 'Song B',
        key: 'Em',
        bpm: '120',
        youTubeUrl: 'https://youtube.com/watch?v=12345678901',
      );

      final created = await repository.createSong(payload);

      expect(created.id, 'created-1');
      expect(created.title, 'Song B');
    });

    test('createSong propaga mensagem da API', () async {
      const payload = SongEntity(
        artist: 'Artist C',
        title: 'Erro',
        key: 'D',
        youTubeUrl: 'https://youtube.com/watch?v=12345678901',
      );

      expect(
        () => repository.createSong(payload),
        throwsA(predicate((e) => e.toString().contains('Título inválido'))),
      );
    });
  });
}
