import 'package:equatable/equatable.dart';

class UserUnavailabilityEntity extends Equatable {
  final String id;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final bool appliesToAllProjects;
  final List<String> projectIds;

  const UserUnavailabilityEntity({
    required this.id,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.appliesToAllProjects,
    required this.projectIds,
  });

  factory UserUnavailabilityEntity.fromJson(Map<String, dynamic> json) {
    return UserUnavailabilityEntity(
      id: (json['id'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      appliesToAllProjects: json['appliesToAllProjects'] == true,
      projectIds: _parseProjectIds(json['projectIds']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    final raw = (value ?? '').toString();
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return DateTime.now();
    }
    return parsed;
  }

  static List<String> _parseProjectIds(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  @override
  List<Object?> get props => [
    id,
    description,
    startDate,
    endDate,
    appliesToAllProjects,
    projectIds,
  ];
}
