import 'package:equatable/equatable.dart';

class CreateUserUnavailabilityInputEntity extends Equatable {
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final bool appliesToAllProjects;
  final List<String> projectIds;

  const CreateUserUnavailabilityInputEntity({
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.appliesToAllProjects,
    required this.projectIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'startDate': _formatDate(startDate),
      'endDate': _formatDate(endDate),
      'appliesToAllProjects': appliesToAllProjects,
      'projectIds': projectIds,
    };
  }

  String _formatDate(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    return normalized.toIso8601String();
  }

  @override
  List<Object?> get props => [
    description,
    startDate,
    endDate,
    appliesToAllProjects,
    projectIds,
  ];
}
