class SkillEntity {
  final String id;
  final String name;
  final String? iconKey;

  const SkillEntity({required this.id, required this.name, this.iconKey});

  factory SkillEntity.fromJson(Map<String, dynamic> json) {
    return SkillEntity(
      id: json['id'].toString(),
      name: json['name'].toString(),
      iconKey: json['iconKey']?.toString(),
    );
  }
}
