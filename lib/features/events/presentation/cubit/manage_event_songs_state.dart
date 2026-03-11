import 'package:equatable/equatable.dart';
import 'package:louvor4_app/features/songs/domain/entities/song_entity.dart';

enum ManageEventSongsStatus { initial, loadingSongs, loaded, submitting, success, error }

class ManageEventSongsState extends Equatable {
  final ManageEventSongsStatus status;
  final List<SongEntity> songs;
  final Set<String> selectedSongIds;
  final String? errorMessage;

  const ManageEventSongsState({
    this.status = ManageEventSongsStatus.initial,
    this.songs = const [],
    this.selectedSongIds = const {},
    this.errorMessage,
  });

  bool get isLoading => status == ManageEventSongsStatus.loadingSongs;
  bool get isSubmitting => status == ManageEventSongsStatus.submitting;
  bool get hasSelection => selectedSongIds.isNotEmpty;

  ManageEventSongsState copyWith({
    ManageEventSongsStatus? status,
    List<SongEntity>? songs,
    Set<String>? selectedSongIds,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ManageEventSongsState(
      status: status ?? this.status,
      songs: songs ?? this.songs,
      selectedSongIds: selectedSongIds ?? this.selectedSongIds,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, songs, selectedSongIds, errorMessage];
}
