import 'package:equatable/equatable.dart';

import '../models/selectable_event_member.dart';

enum ManageEventParticipantsStatus {
  initial,
  loading,
  ready,
  submitting,
  success,
  failure,
}

class ManageEventParticipantsState extends Equatable {
  final ManageEventParticipantsStatus status;
  final List<SelectableEventMember> members;
  final Map<String, String> skillsMap;
  final String? errorMessage;

  const ManageEventParticipantsState({
    this.status = ManageEventParticipantsStatus.initial,
    this.members = const [],
    this.skillsMap = const {},
    this.errorMessage,
  });

  bool get isLoading => status == ManageEventParticipantsStatus.loading;
  bool get isReady =>
      status == ManageEventParticipantsStatus.ready ||
      status == ManageEventParticipantsStatus.submitting ||
      status == ManageEventParticipantsStatus.failure;
  bool get isSubmitting => status == ManageEventParticipantsStatus.submitting;

  ManageEventParticipantsState copyWith({
    ManageEventParticipantsStatus? status,
    List<SelectableEventMember>? members,
    Map<String, String>? skillsMap,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ManageEventParticipantsState(
      status: status ?? this.status,
      members: members ?? this.members,
      skillsMap: skillsMap ?? this.skillsMap,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, members, skillsMap, errorMessage];
}
