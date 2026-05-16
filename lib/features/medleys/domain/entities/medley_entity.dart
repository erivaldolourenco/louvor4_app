import 'package:equatable/equatable.dart';

import 'medley_item_entity.dart';

class MedleyEntity extends Equatable {
  final String? id;
  final String name;
  final String? description;
  final String? notes;
  final List<MedleyItemEntity> items;

  const MedleyEntity({
    this.id,
    required this.name,
    this.description,
    this.notes,
    this.items = const [],
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
      items: items,
    );
  }

  static String? _normalizeOptional(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  @override
  List<Object?> get props => [id, name, description, notes, items];
}
