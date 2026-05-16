class CreateMedleyItemInputEntity {
  final String songId;
  final String key;
  final String? notes;
  final int sequence;

  const CreateMedleyItemInputEntity({
    required this.songId,
    required this.key,
    this.notes,
    required this.sequence,
  });

  Map<String, dynamic> toJson() => {
    'songId': songId,
    'key': key,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    'sequence': sequence,
  };
}

class CreateMedleyInputEntity {
  final String name;
  final String? description;
  final List<CreateMedleyItemInputEntity> items;

  const CreateMedleyInputEntity({
    required this.name,
    this.description,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null && description!.isNotEmpty)
      'description': description,
    'items': items.map((i) => i.toJson()).toList(),
  };
}
