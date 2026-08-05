import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_async_states.dart';
import '../../../../core/ui/widgets/app_cached_network_image.dart';
import '../../../../core/ui/widgets/standard_section_app_bar.dart';
import '../../../../core/utils/url_utils.dart';
import '../../data/external_music_repository.dart';
import '../../data/impl/external_music_repository_impl.dart';
import '../../domain/entities/external_music_entity.dart';
import 'create_song_page.dart';

class SearchExternalMusicPage extends StatefulWidget {
  final ExternalMusicProvider provider;

  const SearchExternalMusicPage({super.key, required this.provider});

  @override
  State<SearchExternalMusicPage> createState() =>
      _SearchExternalMusicPageState();
}

class _SearchExternalMusicPageState extends State<SearchExternalMusicPage> {
  static const _debounceDuration = Duration(milliseconds: 450);

  final ExternalMusicRepository _repo = ExternalMusicRepositoryImpl();
  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _previewPlayer = AudioPlayer();
  late final StreamSubscription<PlayerState> _previewStateSub;
  Timer? _debounce;

  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _hasSearched = false;
  List<ExternalMusicEntity> _results = const [];
  int _requestId = 0;
  String? _playingPreviewId;
  String? _loadingPreviewId;
  String? _selectingId;

  String get _providerLabel =>
      widget.provider == ExternalMusicProvider.spotify ? 'Spotify' : 'Deezer';

  @override
  void initState() {
    super.initState();
    _previewStateSub = _previewPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && mounted) {
        setState(() => _playingPreviewId = null);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _previewStateSub.cancel();
    _previewPlayer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final term = value.trim();

    if (term.isEmpty) {
      setState(() {
        _hasSearched = false;
        _results = const [];
        _hasError = false;
        _isLoading = false;
      });
      return;
    }

    _debounce = Timer(_debounceDuration, () => _search(term));
  }

  Future<void> _search(String term) async {
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final results = await _repo.search(term: term, provider: widget.provider);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _togglePreview(ExternalMusicEntity result) async {
    final url = result.previewUrl;
    if (url == null) return;

    if (_playingPreviewId == result.externalId) {
      await _previewPlayer.pause();
      if (mounted) setState(() => _playingPreviewId = null);
      return;
    }

    setState(() {
      _loadingPreviewId = result.externalId;
      _playingPreviewId = null;
    });
    try {
      await _previewPlayer.setUrl(url);
      if (!mounted) return;
      await _previewPlayer.play();
      if (!mounted) return;
      setState(() {
        _playingPreviewId = result.externalId;
        _loadingPreviewId = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPreviewId = null);
      AppFeedback.showError('Não foi possível reproduzir a prévia.');
    }
  }

  Future<void> _selectResult(ExternalMusicEntity result) async {
    if (_selectingId != null) return;

    await _previewPlayer.stop();
    if (mounted) {
      setState(() {
        _playingPreviewId = null;
        _selectingId = result.externalId;
      });
    }
    if (!mounted) return;

    // Resolve a URL do provedor que faltava (via ISRC) antes de abrir o
    // formulário. Se a chamada falhar, seguimos com o item original — o
    // usuário ainda pode cadastrar a música, só sem a URL do outro provedor.
    var resolved = result;
    try {
      resolved = await _repo.select(result);
    } catch (_) {
      resolved = result;
    }

    if (!mounted) return;
    setState(() => _selectingId = null);

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateSongPage(prefill: resolved)),
    );
    if (created == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardSectionAppBar(
        title: 'Buscar no $_providerLabel',
        subtitle: 'Encontre a música e preencha o formulário automaticamente',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onQueryChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar por título ou artista...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _onQueryChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_hasSearched) {
      return AppEmptyState(
        icon: Icons.travel_explore_rounded,
        title: 'Buscar no $_providerLabel',
        description:
            'Digite o título ou artista da música para começar a busca.',
      );
    }

    if (_isLoading) return const AppLoadingState();

    if (_hasError) {
      return AppErrorState(
        message:
            _errorMessage ??
            'Não foi possível buscar músicas no $_providerLabel.',
        onRetry: () => _search(_searchController.text.trim()),
      );
    }

    if (_results.isEmpty) {
      return AppEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Nenhum resultado encontrado',
        description: 'Tente buscar com outro título ou artista.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (_, index) {
        final result = _results[index];
        final isSelecting = _selectingId == result.externalId;
        return _ExternalMusicResultTile(
          result: result,
          onTap: _selectingId == null ? () => _selectResult(result) : null,
          isPlayingPreview: _playingPreviewId == result.externalId,
          isLoadingPreview: _loadingPreviewId == result.externalId,
          isSelecting: isSelecting,
          onTogglePreview: () => _togglePreview(result),
        );
      },
    );
  }
}

class _ExternalMusicResultTile extends StatelessWidget {
  final ExternalMusicEntity result;
  final VoidCallback? onTap;
  final bool isPlayingPreview;
  final bool isLoadingPreview;
  final bool isSelecting;
  final VoidCallback onTogglePreview;

  const _ExternalMusicResultTile({
    required this.result,
    required this.onTap,
    required this.isPlayingPreview,
    required this.isLoadingPreview,
    required this.isSelecting,
    required this.onTogglePreview,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasCover = UrlUtils.isValidNetworkUrl(result.coverUrl);
    final hasPreview = result.previewUrl != null;

    return Opacity(
      opacity: onTap == null && !isSelecting ? 0.5 : 1,
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.thumbnail),
          child: Stack(
            alignment: Alignment.center,
            children: [
              hasCover
                  ? AppCachedNetworkImage(
                      imageUrl: result.coverUrl!,
                      width: 48,
                      height: 48,
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: cs.primaryContainer,
                      child: Icon(
                        Icons.music_note_rounded,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
              if (isSelecting)
                Container(
                  width: 48,
                  height: 48,
                  color: Colors.black.withValues(alpha: 0.45),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          result.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [result.artist, if (result.album != null) result.album!].join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: hasPreview
            ? SizedBox(
                width: 40,
                height: 40,
                child: isLoadingPreview
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        tooltip: isPlayingPreview
                            ? 'Pausar prévia'
                            : 'Ouvir prévia',
                        icon: Icon(
                          isPlayingPreview
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: cs.primary,
                          size: 32,
                        ),
                        onPressed: onTap == null ? null : onTogglePreview,
                      ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
