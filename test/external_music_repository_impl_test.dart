import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:louvor4_app/features/songs/data/impl/external_music_repository_impl.dart';
import 'package:louvor4_app/features/songs/domain/entities/external_music_entity.dart';

void main() {
  group('ExternalMusicRepositoryImpl', () {
    late Dio dio;
    late ExternalMusicRepositoryImpl repository;

    setUp(() {
      dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path == '/external-music/search') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  data: [
                    {
                      'externalId': '87957443',
                      'title': 'Ele Vive Ao Vivo',
                      'artist': 'Leonardo Gonçalves',
                      'album': 'Principio (Ao Vivo)',
                      'coverUrl': 'https://example.com/cover.jpg',
                      'durationMs': 261000,
                      'previewUrl': 'https://example.com/preview.mp3',
                      'spotifyUrl': null,
                      'deezerUrl': 'https://www.deezer.com/track/87957443',
                      'isrc': 'BRSME1400790',
                      'bpm': null,
                      'provider': 'DEEZER',
                    },
                  ],
                ),
              );
            }

            if (options.path == '/external-music/select') {
              final body = options.data as Map<String, dynamic>;
              if (body['externalId'] == 'sem-match') {
                return handler.resolve(
                  Response(requestOptions: options, data: body),
                );
              }

              return handler.resolve(
                Response(
                  requestOptions: options,
                  data: {
                    ...body,
                    'spotifyUrl': 'https://open.spotify.com/track/xyz',
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

      repository = ExternalMusicRepositoryImpl(dio: dio);
    });

    test('search retorna lista mapeada com apenas a URL do provider de origem', () async {
      final results = await repository.search(
        term: 'Ele Vive',
        provider: ExternalMusicProvider.deezer,
      );

      expect(results, hasLength(1));
      expect(results.first.externalId, '87957443');
      expect(results.first.deezerUrl, 'https://www.deezer.com/track/87957443');
      expect(results.first.spotifyUrl, isNull);
    });

    test('select devolve o item com a URL do outro provider resolvida', () async {
      const item = ExternalMusicEntity(
        externalId: '87957443',
        title: 'Ele Vive Ao Vivo',
        artist: 'Leonardo Gonçalves',
        deezerUrl: 'https://www.deezer.com/track/87957443',
        isrc: 'BRSME1400790',
        provider: ExternalMusicProvider.deezer,
      );

      final resolved = await repository.select(item);

      expect(resolved.deezerUrl, item.deezerUrl);
      expect(resolved.spotifyUrl, 'https://open.spotify.com/track/xyz');
    });

    test('select devolve o item sem alteração quando não há correspondência', () async {
      const item = ExternalMusicEntity(
        externalId: 'sem-match',
        title: 'Sem ISRC',
        artist: 'Artista',
        provider: ExternalMusicProvider.spotify,
      );

      final resolved = await repository.select(item);

      expect(resolved.spotifyUrl, isNull);
      expect(resolved.deezerUrl, isNull);
    });
  });
}
