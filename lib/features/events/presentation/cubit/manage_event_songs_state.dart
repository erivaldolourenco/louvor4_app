import 'package:equatable/equatable.dart';
import 'package:louvor4_app/features/medleys/domain/entities/medley_entity.dart';
import 'package:louvor4_app/features/songs/domain/entities/song_entity.dart';

enum ManageEventSongsStatus { initial, loadingSongs, loaded, submitting, success, error }

class ManageEventSongsState extends Equatable {
  final ManageEventSongsStatus status;
  final List<SongEntity> songs;
  final Set<String> selectedSongIds;
  final List<MedleyEntity> medleys;
  final Set<String> selectedMedleyIds;
  final bool isLoadingMedleys;
  final String? errorMessage;

  const ManageEventSongsState({
    this.status = ManageEventSongsStatus.initial,
    this.songs = const [],
    this.selectedSongIds = const {},
    this.medleys = const [],
    this.selectedMedleyIds = const {},
    this.isLoadingMedleys = false,
    this.errorMessage,
  });

  bool get isLoading => status == ManageEventSongsStatus.loadingSongs;
  bool get isSubmitting => status == ManageEventSongsStatus.submitting;
  bool get hasSongSelection => selectedSongIds.isNotEmpty;
  bool get hasMedleySelection => selectedMedleyIds.isNotEmpty;

  ManageEventSongsState copyWith({
    ManageEventSongsStatus? status,
    List<SongEntity>? songs,
    Set<String>? selectedSongIds,
    List<MedleyEntity>? medleys,
    Set<String>? selectedMedleyIds,
    bool? isLoadingMedleys,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ManageEventSongsState(
      status: status ?? this.status,
      songs: songs ?? this.songs,
      selectedSongIds: selectedSongIds ?? this.selectedSongIds,
      medleys: medleys ?? this.medleys,
      selectedMedleyIds: selectedMedleyIds ?? this.selectedMedleyIds,
      isLoadingMedleys: isLoadingMedleys ?? this.isLoadingMedleys,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    songs,
    selectedSongIds,
    medleys,
    selectedMedleyIds,
    isLoadingMedleys,
    errorMessage,
  ];
}
