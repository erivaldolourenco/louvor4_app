import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/events_repository.dart';
import '../../domain/entities/event_participant_entity.dart';
import '../../domain/entities/event_song_entity.dart';
import 'event_detail_state.dart';

class EventDetailCubit extends Cubit<EventDetailState> {
  final EventsRepository _repository;

  EventDetailCubit(this._repository) : super(const EventDetailState());

  Future<void> load(String eventId) async {
    emit(state.copyWith(status: EventDetailStatus.loading));

    try {
      final event = await _repository.getEventDetail(eventId);

      final results = await Future.wait([
        _repository.getEventParticipants(eventId),
        _repository.getEventSongs(eventId),
        _repository.getProjectSkills(event.projectId),
      ]);

      final participants = results[0] as List<EventParticipant>; // Ajuste conforme seu tipo
      final songs = results[1] as List<EventSong>;
      final skillsList = results[2] as List; // Supondo que retorne List<SkillModel>

      final Map<String, String> skillsMap = {
        for (var skill in skillsList) skill.id: skill.name
      };

      if (kDebugMode) {
        print(skillsMap);
      }
      emit(state.copyWith(
        status: EventDetailStatus.success,
        event: event,
        participants: participants,
        songs: songs,
        skillsMap: skillsMap, // Você precisará adicionar esse campo no seu EventDetailState
      ));
    } catch (e) {
      emit(state.copyWith(
        status: EventDetailStatus.failure,
        errorMessage: 'Não foi possível carregar os detalhes do evento.',
      ));
    }
  }
}