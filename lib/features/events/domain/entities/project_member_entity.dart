import 'package:equatable/equatable.dart';

import 'skill_entity.dart';

class ProjectMemberEntity extends Equatable {
  final String id;
  final String? userId;
  final String firstName;
  final String? lastName;
  final String? profileImage;
  final String? projectRole;
  final List<SkillEntity> skills;
  final Set<String> skillNames;

  const ProjectMemberEntity({
    required this.id,
    this.userId,
    required this.firstName,
    this.lastName,
    this.profileImage,
    this.projectRole,
    this.skills = const [],
    this.skillNames = const {},
  });

  String get fullName {
    final name = '$firstName ${lastName ?? ''}'.trim();
    return name.isEmpty ? 'Sem nome' : name;
  }

  factory ProjectMemberEntity.fromJson(
    Map<String, dynamic> json, {
    List<SkillEntity> projectSkillsCatalog = const [],
  }) {
    final user = _asMap(json['user']);
    final rawSkills =
        json['skills'] ?? json['memberSkills'] ?? json['projectSkills'];
    final skillNames = _extractSkillNames(rawSkills);
    final parsedSkills = (rawSkills as List? ?? const [])
        .map((item) => _parseSkill(item, projectSkillsCatalog))
        .whereType<SkillEntity>()
        .toList();
    final skills = {
      for (final skill in parsedSkills) skill.id: skill,
    }.values.toList();

    return ProjectMemberEntity(
      id: _readString(json, ['memberId', 'id', 'userId'], fallbackMap: user),
      userId: _readNullableString(json, ['userId'], fallbackMap: user),
      firstName: _readString(json, ['firstName', 'name'], fallbackMap: user),
      lastName: _readNullableString(json, [
        'lastName',
        'surname',
      ], fallbackMap: user),
      profileImage: _readNullableString(json, [
        'profileImage',
        'avatar',
        'imageUrl',
      ], fallbackMap: user),
      projectRole: _readNullableString(json, [
        'projectRole',
        'role',
        'memberRole',
      ]),
      skills: skills,
      skillNames: skillNames,
    );
  }

  ProjectMemberEntity copyWith({
    String? id,
    String? userId,
    String? firstName,
    String? lastName,
    String? profileImage,
    String? projectRole,
    List<SkillEntity>? skills,
    Set<String>? skillNames,
  }) {
    return ProjectMemberEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImage: profileImage ?? this.profileImage,
      projectRole: projectRole ?? this.projectRole,
      skills: skills ?? this.skills,
      skillNames: skillNames ?? this.skillNames,
    );
  }

  static SkillEntity? _parseSkill(
    dynamic value,
    List<SkillEntity> projectSkillsCatalog,
  ) {
    if (value is Map<String, dynamic>) {
      if (value['skill'] is Map<String, dynamic>) {
        return SkillEntity.fromJson(value['skill'] as Map<String, dynamic>);
      }
      if (value['skill'] is Map) {
        return SkillEntity.fromJson(
          Map<String, dynamic>.from(value['skill'] as Map),
        );
      }
      return SkillEntity.fromJson(value);
    }

    if (value is String) {
      final normalized = _normalizeString(value);
      if (normalized == null) return null;
      return SkillEntity(id: normalized, name: normalized);
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      if (map['skill'] is Map) {
        return SkillEntity.fromJson(
          Map<String, dynamic>.from(map['skill'] as Map),
        );
      }
      return SkillEntity.fromJson(map);
    }

    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static Set<String> _extractSkillNames(dynamic rawSkills) {
    final skills = rawSkills as List? ?? const [];
    return skills
        .map((item) {
          if (item is String) return _normalizeString(item);
          if (item is Map<String, dynamic>) {
            return _normalizeString(item['name']);
          }
          if (item is Map) {
            return _normalizeString(item['name']);
          }
          return null;
        })
        .whereType<String>()
        .toSet();
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    Map<String, dynamic>? fallbackMap,
  }) {
    final value = _readNullableString(json, keys, fallbackMap: fallbackMap);
    return value ?? '';
  }

  static String? _readNullableString(
    Map<String, dynamic> json,
    List<String> keys, {
    Map<String, dynamic>? fallbackMap,
  }) {
    for (final key in keys) {
      final directValue = _normalizeString(json[key]);
      if (directValue != null) return directValue;

      if (fallbackMap != null) {
        final fallbackValue = _normalizeString(fallbackMap[key]);
        if (fallbackValue != null) return fallbackValue;
      }
    }

    return null;
  }

  static String? _normalizeString(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    firstName,
    lastName,
    profileImage,
    projectRole,
    skills,
    skillNames,
  ];
}
