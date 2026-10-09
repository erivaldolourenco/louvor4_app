import 'package:equatable/equatable.dart';

/// Responsabilidade do usuário logado (vigente ou agendada) em algum projeto.
class MyResponsibilityEntity extends Equatable {
  final String assignmentId;
  final String responsibilityId;
  final String responsibilityName;
  final String? responsibilityDescription;
  final String projectId;
  final String projectName;
  final String? projectImage;
  final DateTime startDate;
  final DateTime endDate;

  /// `true` quando o período contém hoje; `false` quando ainda vai começar.
  final bool current;

  const MyResponsibilityEntity({
    required this.assignmentId,
    required this.responsibilityId,
    required this.responsibilityName,
    this.responsibilityDescription,
    required this.projectId,
    required this.projectName,
    this.projectImage,
    required this.startDate,
    required this.endDate,
    required this.current,
  });

  factory MyResponsibilityEntity.fromJson(Map<String, dynamic> json) {
    DateTime parse(dynamic value) {
      final date = DateTime.parse(value.toString());
      return DateTime(date.year, date.month, date.day);
    }

    return MyResponsibilityEntity(
      assignmentId: (json['assignmentId'] ?? '').toString(),
      responsibilityId: (json['responsibilityId'] ?? '').toString(),
      responsibilityName: (json['responsibilityName'] ?? '').toString(),
      responsibilityDescription: json['responsibilityDescription']?.toString(),
      projectId: (json['projectId'] ?? '').toString(),
      projectName: (json['projectName'] ?? '').toString(),
      projectImage: json['projectImage']?.toString(),
      startDate: parse(json['startDate']),
      endDate: parse(json['endDate']),
      current: json['current'] == true,
    );
  }

  @override
  List<Object?> get props => [
    assignmentId,
    responsibilityId,
    responsibilityName,
    responsibilityDescription,
    projectId,
    projectName,
    projectImage,
    startDate,
    endDate,
    current,
  ];
}
