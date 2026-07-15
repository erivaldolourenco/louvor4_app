import 'package:equatable/equatable.dart';

enum ChordSectionType {
  verse,
  chorus,
  bridge,
  intro,
  instrumental,
  preChorus,
  outro,
  chordSequence,
  other,
}

extension ChordSectionTypeX on ChordSectionType {
  String get apiValue {
    switch (this) {
      case ChordSectionType.verse:
        return 'verse';
      case ChordSectionType.chorus:
        return 'chorus';
      case ChordSectionType.bridge:
        return 'bridge';
      case ChordSectionType.intro:
        return 'intro';
      case ChordSectionType.instrumental:
        return 'instrumental';
      case ChordSectionType.preChorus:
        return 'pre-chorus';
      case ChordSectionType.outro:
        return 'outro';
      case ChordSectionType.chordSequence:
        return 'chord_sequence';
      case ChordSectionType.other:
        return 'other';
    }
  }

  String get ptLabel {
    switch (this) {
      case ChordSectionType.verse:
        return 'Verso';
      case ChordSectionType.chorus:
        return 'Refrão';
      case ChordSectionType.bridge:
        return 'Ponte';
      case ChordSectionType.intro:
        return 'Introdução';
      case ChordSectionType.instrumental:
        return 'Instrumental';
      case ChordSectionType.preChorus:
        return 'Pré-refrão';
      case ChordSectionType.outro:
        return 'Final';
      case ChordSectionType.chordSequence:
        return 'Sequência de acordes';
      case ChordSectionType.other:
        return 'Outro';
    }
  }

  static ChordSectionType fromApiValue(String value) {
    return ChordSectionType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => ChordSectionType.other,
    );
  }
}

/// Formato de acorde aceito pelo backend: raiz A-G, acidente opcional (#/b),
/// sufixo livre (m, 7, maj7, sus4, dim...), baixo opcional após "/".
final RegExp chordNamePattern = RegExp(
  r'^[A-G](#|b)?[A-Za-z0-9+\-]*(\/[A-G](#|b)?)?$',
);

bool isValidChordName(String value) {
  final trimmed = value.trim();
  return trimmed.isNotEmpty && chordNamePattern.hasMatch(trimmed);
}

class ChordEntity extends Equatable {
  final int position;
  final String chord;

  const ChordEntity({required this.position, required this.chord});

  factory ChordEntity.fromJson(Map<String, dynamic> json) {
    return ChordEntity(
      position: (json['position'] as num?)?.toInt() ?? 0,
      chord: (json['chord'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'position': position, 'chord': chord};

  @override
  List<Object?> get props => [position, chord];
}

class ChordLineEntity extends Equatable {
  final String text;
  final List<ChordEntity> chords;
  final int? repeat;

  const ChordLineEntity({
    required this.text,
    this.chords = const [],
    this.repeat,
  });

  factory ChordLineEntity.fromJson(Map<String, dynamic> json) {
    final rawChords = json['chords'];
    return ChordLineEntity(
      text: (json['text'] ?? '').toString(),
      chords: rawChords is List
          ? rawChords
                .map((c) => ChordEntity.fromJson(Map<String, dynamic>.from(c as Map)))
                .toList()
          : const [],
      repeat: (json['repeat'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'chords': chords.map((c) => c.toJson()).toList(),
    'repeat': repeat,
  };

  @override
  List<Object?> get props => [text, chords, repeat];
}

class ChordSectionEntity extends Equatable {
  final ChordSectionType type;
  final String label;
  final List<ChordLineEntity> lines;

  const ChordSectionEntity({
    required this.type,
    required this.label,
    this.lines = const [],
  });

  factory ChordSectionEntity.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];
    return ChordSectionEntity(
      type: ChordSectionTypeX.fromApiValue((json['type'] ?? 'other').toString()),
      label: (json['label'] ?? '').toString(),
      lines: rawLines is List
          ? rawLines
                .map((l) => ChordLineEntity.fromJson(Map<String, dynamic>.from(l as Map)))
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.apiValue,
    'label': label,
    'lines': lines.map((l) => l.toJson()).toList(),
  };

  @override
  List<Object?> get props => [type, label, lines];
}

class ChordSheetSongInfo extends Equatable {
  final String? originalKey;
  final int? bpm;

  const ChordSheetSongInfo({this.originalKey, this.bpm});

  factory ChordSheetSongInfo.fromJson(Map<String, dynamic> json) {
    final key = json['originalKey']?.toString().trim();
    return ChordSheetSongInfo(
      originalKey: key == null || key.isEmpty ? null : key,
      bpm: (json['bpm'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {'originalKey': originalKey, 'bpm': bpm};

  @override
  List<Object?> get props => [originalKey, bpm];
}

class ChordSheetEntity extends Equatable {
  final int schemaVersion;
  final ChordSheetSongInfo song;
  final List<ChordSectionEntity> sections;

  const ChordSheetEntity({
    required this.schemaVersion,
    required this.song,
    this.sections = const [],
  });

  factory ChordSheetEntity.empty({String? originalKey, int? bpm}) {
    return ChordSheetEntity(
      schemaVersion: 1,
      song: ChordSheetSongInfo(originalKey: originalKey, bpm: bpm),
      sections: const [],
    );
  }

  factory ChordSheetEntity.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    final rawSong = json['song'];
    return ChordSheetEntity(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      song: rawSong is Map
          ? ChordSheetSongInfo.fromJson(Map<String, dynamic>.from(rawSong))
          : const ChordSheetSongInfo(),
      sections: rawSections is List
          ? rawSections
                .map((s) => ChordSectionEntity.fromJson(Map<String, dynamic>.from(s as Map)))
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'song': song.toJson(),
    'sections': sections.map((s) => s.toJson()).toList(),
  };

  @override
  List<Object?> get props => [schemaVersion, song, sections];
}
