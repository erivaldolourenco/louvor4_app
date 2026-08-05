import 'package:equatable/equatable.dart';

enum ExternalMusicProvider {
  spotify,
  deezer;

  /// Valor esperado pela API (`MusicProvider` enum em Java).
  String get apiValue => name.toUpperCase();

  static ExternalMusicProvider? fromApiValue(dynamic value) {
    final normalized = value?.toString().toUpperCase();
    for (final provider in ExternalMusicProvider.values) {
      if (provider.apiValue == normalized) return provider;
    }
    return null;
  }
}

class ExternalMusicEntity extends Equatable {
  final String externalId;
  final String title;
  final String artist;
  final String? album;
  final String? coverUrl;
  final int? durationMs;
  final String? previewUrl;
  final String? spotifyUrl;
  final String? deezerUrl;
  final String? isrc;
  final int? bpm;
  final ExternalMusicProvider? provider;

  const ExternalMusicEntity({
    required this.externalId,
    required this.title,
    required this.artist,
    this.album,
    this.coverUrl,
    this.durationMs,
    this.previewUrl,
    this.spotifyUrl,
    this.deezerUrl,
    this.isrc,
    this.bpm,
    this.provider,
  });

  factory ExternalMusicEntity.fromJson(Map<String, dynamic> json) {
    return ExternalMusicEntity(
      externalId: (json['externalId'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      artist: (json['artist'] ?? '').toString(),
      album: _normalizeOptionalValue(json['album']),
      coverUrl: _normalizeOptionalValue(json['coverUrl']),
      durationMs: json['durationMs'] is num
          ? (json['durationMs'] as num).toInt()
          : null,
      previewUrl: _normalizeOptionalValue(json['previewUrl']),
      spotifyUrl: _normalizeOptionalValue(json['spotifyUrl']),
      deezerUrl: _normalizeOptionalValue(json['deezerUrl']),
      isrc: _normalizeOptionalValue(json['isrc']),
      bpm: json['bpm'] is num ? (json['bpm'] as num).toInt() : null,
      provider: ExternalMusicProvider.fromApiValue(json['provider']),
    );
  }

  /// Serializa de volta para o mesmo formato do DTO da API, usado como body
  /// do POST `/external-music/select`.
  Map<String, dynamic> toJson() {
    return {
      'externalId': externalId,
      'title': title,
      'artist': artist,
      'album': album,
      'coverUrl': coverUrl,
      'durationMs': durationMs,
      'previewUrl': previewUrl,
      'spotifyUrl': spotifyUrl,
      'deezerUrl': deezerUrl,
      'isrc': isrc,
      'bpm': bpm,
      'provider': provider?.apiValue,
    };
  }

  static String? _normalizeOptionalValue(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  List<Object?> get props => [
    externalId,
    title,
    artist,
    album,
    coverUrl,
    durationMs,
    previewUrl,
    spotifyUrl,
    deezerUrl,
    isrc,
    bpm,
    provider,
  ];
}
