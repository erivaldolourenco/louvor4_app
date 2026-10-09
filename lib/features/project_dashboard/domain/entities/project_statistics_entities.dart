import 'package:equatable/equatable.dart';

int _asInt(dynamic value) => value is num ? value.toInt() : 0;

String? _asNullableString(dynamic value) {
  final text = value?.toString();
  return text == null || text.isEmpty ? null : text;
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

class SkillCountEntity extends Equatable {
  final String? skillId;
  final String skillName;
  final String? skillIconKey;
  final int total;

  const SkillCountEntity({
    this.skillId,
    required this.skillName,
    this.skillIconKey,
    required this.total,
  });

  factory SkillCountEntity.fromJson(Map<String, dynamic> json) {
    return SkillCountEntity(
      skillId: _asNullableString(json['skillId']),
      skillName: (json['skillName'] ?? '').toString(),
      skillIconKey: _asNullableString(json['skillIconKey']),
      total: _asInt(json['total']),
    );
  }

  @override
  List<Object?> get props => [skillId, skillName, skillIconKey, total];
}

class MonthScheduleStatsEntity extends Equatable {
  /// Formato "YYYY-MM".
  final String month;
  final int total;
  final List<SkillCountEntity> bySkill;

  const MonthScheduleStatsEntity({
    required this.month,
    required this.total,
    required this.bySkill,
  });

  factory MonthScheduleStatsEntity.fromJson(Map<String, dynamic> json) {
    return MonthScheduleStatsEntity(
      month: (json['month'] ?? '').toString(),
      total: _asInt(json['total']),
      bySkill: _asMapList(
        json['bySkill'],
      ).map(SkillCountEntity.fromJson).toList(),
    );
  }

  @override
  List<Object?> get props => [month, total, bySkill];
}

class MemberScheduleStatsEntity extends Equatable {
  final String memberId;
  final String userId;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final int total;
  final List<SkillCountEntity> bySkill;
  final List<MonthScheduleStatsEntity> byMonth;

  const MemberScheduleStatsEntity({
    required this.memberId,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    required this.total,
    required this.bySkill,
    required this.byMonth,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory MemberScheduleStatsEntity.fromJson(Map<String, dynamic> json) {
    return MemberScheduleStatsEntity(
      memberId: json['memberId'].toString(),
      userId: json['userId'].toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      profileImage: _asNullableString(json['profileImage']),
      total: _asInt(json['total']),
      bySkill: _asMapList(
        json['bySkill'],
      ).map(SkillCountEntity.fromJson).toList(),
      byMonth: _asMapList(
        json['byMonth'],
      ).map(MonthScheduleStatsEntity.fromJson).toList(),
    );
  }

  @override
  List<Object?> get props => [
    memberId,
    userId,
    firstName,
    lastName,
    profileImage,
    total,
    bySkill,
    byMonth,
  ];
}

class ProjectScheduleStatsEntity extends Equatable {
  final String from;
  final String to;
  final List<MemberScheduleStatsEntity> members;

  const ProjectScheduleStatsEntity({
    required this.from,
    required this.to,
    required this.members,
  });

  factory ProjectScheduleStatsEntity.fromJson(Map<String, dynamic> json) {
    return ProjectScheduleStatsEntity(
      from: (json['from'] ?? '').toString(),
      to: (json['to'] ?? '').toString(),
      members: _asMapList(
        json['members'],
      ).map(MemberScheduleStatsEntity.fromJson).toList(),
    );
  }

  @override
  List<Object?> get props => [from, to, members];
}

class InviteCountsEntity extends Equatable {
  final int sent;
  final int accepted;
  final int declined;
  final int pending;

  /// Aceitos / enviados, de 0 a 1.
  final double acceptanceRate;

  const InviteCountsEntity({
    required this.sent,
    required this.accepted,
    required this.declined,
    required this.pending,
    required this.acceptanceRate,
  });

  static const empty = InviteCountsEntity(
    sent: 0,
    accepted: 0,
    declined: 0,
    pending: 0,
    acceptanceRate: 0,
  );

  factory InviteCountsEntity.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;
    final rate = json['acceptanceRate'];
    return InviteCountsEntity(
      sent: _asInt(json['sent']),
      accepted: _asInt(json['accepted']),
      declined: _asInt(json['declined']),
      pending: _asInt(json['pending']),
      acceptanceRate: rate is num ? rate.toDouble() : 0,
    );
  }

  @override
  List<Object?> get props => [
    sent,
    accepted,
    declined,
    pending,
    acceptanceRate,
  ];
}

class MonthInviteStatsEntity extends Equatable {
  /// Formato "YYYY-MM".
  final String month;
  final InviteCountsEntity counts;

  const MonthInviteStatsEntity({required this.month, required this.counts});

  factory MonthInviteStatsEntity.fromJson(Map<String, dynamic> json) {
    return MonthInviteStatsEntity(
      month: (json['month'] ?? '').toString(),
      counts: InviteCountsEntity.fromJson(
        json['counts'] is Map
            ? Map<String, dynamic>.from(json['counts'])
            : null,
      ),
    );
  }

  @override
  List<Object?> get props => [month, counts];
}

class MemberInviteStatsEntity extends Equatable {
  final String memberId;
  final String userId;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final InviteCountsEntity counts;

  const MemberInviteStatsEntity({
    required this.memberId,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    required this.counts,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory MemberInviteStatsEntity.fromJson(Map<String, dynamic> json) {
    return MemberInviteStatsEntity(
      memberId: json['memberId'].toString(),
      userId: json['userId'].toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      profileImage: _asNullableString(json['profileImage']),
      counts: InviteCountsEntity.fromJson(
        json['counts'] is Map
            ? Map<String, dynamic>.from(json['counts'])
            : null,
      ),
    );
  }

  @override
  List<Object?> get props => [
    memberId,
    userId,
    firstName,
    lastName,
    profileImage,
    counts,
  ];
}

class ProjectInviteStatsEntity extends Equatable {
  final String from;
  final String to;
  final InviteCountsEntity totals;
  final List<MonthInviteStatsEntity> byMonth;
  final List<MemberInviteStatsEntity> byMember;

  const ProjectInviteStatsEntity({
    required this.from,
    required this.to,
    required this.totals,
    required this.byMonth,
    required this.byMember,
  });

  factory ProjectInviteStatsEntity.fromJson(Map<String, dynamic> json) {
    return ProjectInviteStatsEntity(
      from: (json['from'] ?? '').toString(),
      to: (json['to'] ?? '').toString(),
      totals: InviteCountsEntity.fromJson(
        json['totals'] is Map
            ? Map<String, dynamic>.from(json['totals'])
            : null,
      ),
      byMonth: _asMapList(
        json['byMonth'],
      ).map(MonthInviteStatsEntity.fromJson).toList(),
      byMember: _asMapList(
        json['byMember'],
      ).map(MemberInviteStatsEntity.fromJson).toList(),
    );
  }

  @override
  List<Object?> get props => [from, to, totals, byMonth, byMember];
}
