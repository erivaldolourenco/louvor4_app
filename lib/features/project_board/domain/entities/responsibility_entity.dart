import 'package:equatable/equatable.dart';

DateTime _parseDate(dynamic value) {
  final parsed = DateTime.parse(value.toString());
  return DateTime(parsed.year, parsed.month, parsed.day);
}

String formatApiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Período em que um membro fica com uma responsabilidade.
class ResponsibilityAssignmentEntity extends Equatable {
  final String id;
  final String memberId;
  final String userId;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final bool accountDeleted;
  final DateTime startDate;
  final DateTime endDate;

  const ResponsibilityAssignmentEntity({
    required this.id,
    required this.memberId,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    this.accountDeleted = false,
    required this.startDate,
    required this.endDate,
  });

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'Sem nome' : name;
  }

  factory ResponsibilityAssignmentEntity.fromJson(Map<String, dynamic> json) {
    return ResponsibilityAssignmentEntity(
      id: (json['id'] ?? '').toString(),
      memberId: (json['memberId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      profileImage: json['profileImage']?.toString(),
      accountDeleted: json['accountDeleted'] == true,
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
    );
  }

  static ResponsibilityAssignmentEntity? fromJsonOrNull(dynamic json) {
    if (json is! Map) return null;
    return ResponsibilityAssignmentEntity.fromJson(
      Map<String, dynamic>.from(json),
    );
  }

  @override
  List<Object?> get props => [
    id,
    memberId,
    userId,
    firstName,
    lastName,
    profileImage,
    accountDeleted,
    startDate,
    endDate,
  ];
}

/// Responsabilidade do projeto com o resumo do histórico calculado pela API:
/// [current] contém hoje, [next] é o próximo agendado, [last] o último encerrado.
class ResponsibilityEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int position;
  final ResponsibilityAssignmentEntity? current;
  final ResponsibilityAssignmentEntity? next;
  final ResponsibilityAssignmentEntity? last;

  const ResponsibilityEntity({
    required this.id,
    required this.name,
    this.description,
    this.position = 0,
    this.current,
    this.next,
    this.last,
  });

  factory ResponsibilityEntity.fromJson(Map<String, dynamic> json) {
    final description = json['description']?.toString().trim();
    return ResponsibilityEntity(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: description == null || description.isEmpty
          ? null
          : description,
      position: (json['position'] as num?)?.toInt() ?? 0,
      current: ResponsibilityAssignmentEntity.fromJsonOrNull(json['current']),
      next: ResponsibilityAssignmentEntity.fromJsonOrNull(json['next']),
      last: ResponsibilityAssignmentEntity.fromJsonOrNull(json['last']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    position,
    current,
    next,
    last,
  ];
}
