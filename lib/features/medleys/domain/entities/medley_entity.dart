import 'package:equatable/equatable.dart';

import '../../../song_categories/domain/entities/song_category_entity.dart';
import 'medley_item_entity.dart';

class MedleyEntity extends Equatable {
  final String? id;
  final String name;
  final String? description;
  final String? notes;
  final String? referenceAudioUrl;
  final List<MedleyItemEntity> items;
  final List<SongCategoryEntity> categories;

  const MedleyEntity({
    this.id,
    required this.name,
    this.description,
    this.notes,
    this.referenceAudioUrl,
    this.items = const [],
    this.categories = const [],
  });

  factory MedleyEntity.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List?;
    final items = rawItems
            ?.map(
              (e) => MedleyItemEntity.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList() ??
        [];

    items.sort((a, b) => a.sequence.compareTo(b.sequence));

    return MedleyEntity(
      id: json['id']?.toString(),
      name: (json['name'] ?? '').toString(),
      description: _normalizeOptional(json['description']),
      notes: _normalizeOptional(json['notes']),
      referenceAudioUrl: _normalizeOptional(json['referenceAudioUrl']),
      items: items,
      categories: (json['categories'] as List? ?? const [])
          .map(
            (item) => SongCategoryEntity.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  MedleyEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? notes,
    String? referenceAudioUrl,
    List<MedleyItemEntity>? items,
    List<SongCategoryEntity>? categories,
  }) {
    return MedleyEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      referenceAudioUrl: referenceAudioUrl ?? this.referenceAudioUrl,
      items: items ?? this.items,
      categories: categories ?? this.categories,
    );
  }

  static String? _normalizeOptional(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    notes,
    referenceAudioUrl,
    items,
    categories,
  ];
}
