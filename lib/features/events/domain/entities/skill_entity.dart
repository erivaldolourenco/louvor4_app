class SkillEntity {
  final String id;
  final String name;

  const SkillEntity({
    required this.id,
    required this.name,
  });

  factory SkillEntity.fromJson(Map<String, dynamic> json) {
    return SkillEntity(
      id: json['id'].toString(),
      name: json['name'].toString(),
    );
  }
}
