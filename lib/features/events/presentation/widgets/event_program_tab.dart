import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/utils/youtube_utils.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_async_states.dart';
import '../../../../core/ui/widgets/app_card_surface.dart';
import '../../../../core/ui/widgets/fade_slide_in.dart';
import '../../domain/entities/program_item_entity.dart';
import '../../domain/entities/program_item_input_entity.dart';
import '../cubit/event_program_cubit.dart';
import '../cubit/event_program_state.dart';

class EventProgramTab extends StatelessWidget {
  final bool isAdmin;

  const EventProgramTab({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventProgramCubit, EventProgramState>(
      builder: (context, state) {
        if (state.status == EventProgramStatus.initial ||
            state.status == EventProgramStatus.loading) {
          return const AppLoadingState();
        }

        if (state.status == EventProgramStatus.failure && state.items.isEmpty) {
          return AppErrorState(
            message:
                state.errorMessage ??
                'Não foi possível carregar a programação.',
            onRetry: () => context.read<EventProgramCubit>().loadProgram(),
          );
        }

        final cubit = context.read<EventProgramCubit>();

        if (state.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: cubit.loadProgram,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
              children: const [_EmptyProgramState()],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: cubit.loadProgram,
          child: Column(
            children: [
              Expanded(
                child: ReorderableListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
                  buildDefaultDragHandles: false,
                  onReorder: (oldIndex, newIndex) {
                    if (!isAdmin) return;
                    if (newIndex > oldIndex) newIndex -= 1;
                    final ids = state.items.map((i) => i.id).toList();
                    final id = ids.removeAt(oldIndex);
                    ids.insert(newIndex, id);
                    cubit.reorder(ids);
                  },
                  children: [
                    for (int i = 0; i < state.items.length; i++)
                      FadeSlideIn(
                        key: ValueKey(state.items[i].id),
                        delay: staggerDelay(i),
                        child: _ProgramItemTile(
                          item: state.items[i],
                          position: i + 1,
                          isAdmin: isAdmin,
                          itemIndex: i,
                          totalCount: state.items.length,
                          onEdit: isAdmin && state.items[i] is TextProgramItemEntity
                              ? () => _showTextItemDialog(
                                  context,
                                  item: state.items[i] as TextProgramItemEntity,
                                )
                              : null,
                          onDelete:
                              isAdmin && state.items[i] is TextProgramItemEntity
                              ? () => _confirmDelete(
                                  context,
                                  state.items[i] as TextProgramItemEntity,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showTextItemDialog(
    BuildContext context, {
    TextProgramItemEntity? item,
  }) => showProgramTextItemDialog(context, item: item);

  Future<void> _confirmDelete(
    BuildContext context,
    TextProgramItemEntity item,
  ) async {
    final cubit = context.read<EventProgramCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover item'),
        content: const Text(
          'Tem certeza que deseja remover este item da programação?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await cubit.deleteItem(item.id);
    if (success) {
      AppFeedback.showSuccess('Item removido da programação.');
    } else {
      AppFeedback.showError(cubit.state.actionError ?? 'Erro ao remover item.');
    }
  }
}

Future<void> showProgramTextItemDialog(
  BuildContext context, {
  TextProgramItemEntity? item,
}) async {
  final cubit = context.read<EventProgramCubit>();

  final result = await showDialog<({String title, String description})>(
    context: context,
    builder: (_) => _TextItemDialog(item: item),
  );
  if (result == null) return;

  final bool success;
  if (item == null) {
    success = await cubit.createTextItem(
      CreateTextProgramItemInputEntity(
        title: result.title,
        description: result.description.isEmpty ? null : result.description,
      ),
    );
  } else {
    success = await cubit.updateTextItem(
      item.id,
      UpdateTextProgramItemInputEntity(
        title: result.title,
        description: result.description.isEmpty ? null : result.description,
      ),
    );
  }

  if (success) {
    AppFeedback.showSuccess(
      item == null ? 'Item adicionado à programação.' : 'Item atualizado.',
    );
  } else {
    AppFeedback.showError(cubit.state.actionError ?? 'Erro ao salvar item.');
  }
}

// ---------------------------------------------------------------------------
// Item tile (M3 Expressive)
// ---------------------------------------------------------------------------

class _ProgramItemTile extends StatelessWidget {
  final ProgramItemEntity item;
  final int position;
  final bool isAdmin;
  final int itemIndex;
  final int totalCount;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ProgramItemTile({
    required this.item,
    required this.position,
    required this.isAdmin,
    required this.itemIndex,
    required this.totalCount,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final isMusic = item is MusicProgramItemEntity;
    final isMedley = item is MedleyProgramItemEntity;
    final music = isMusic ? item as MusicProgramItemEntity : null;
    final medley = isMedley ? item as MedleyProgramItemEntity : null;
    final text = (!isMusic && !isMedley) ? item as TextProgramItemEntity : null;
    final isEditable = text != null;

    final IconData iconData;
    final Color avatarBgColor;
    final Color avatarFgColor;

    if (isMusic) {
      iconData = Icons.music_note_rounded;
      avatarBgColor = cs.primaryContainer;
      avatarFgColor = cs.onPrimaryContainer;
    } else if (isMedley) {
      iconData = Icons.queue_music_rounded;
      avatarBgColor = cs.secondaryContainer;
      avatarFgColor = cs.onSecondaryContainer;
    } else {
      iconData = Icons.text_fields_rounded;
      avatarBgColor = cs.tertiaryContainer;
      avatarFgColor = cs.onTertiaryContainer;
    }

    final String titleText = isMusic
        ? music!.songTitle
        : isMedley
        ? medley!.medleyName
        : text!.title;

    String? subtitleText;
    if (isMusic && music!.songArtist.isNotEmpty) {
      subtitleText = music.songArtist;
    } else if (isMedley && medley!.songs.isNotEmpty) {
      subtitleText = medley.songs.map((s) => s.title).join(' • ');
    } else if (text?.description?.isNotEmpty == true) {
      subtitleText = text!.description;
    }

    String? musicMetaText;
    if (isMusic) {
      final metaParts = <String>[
        if (music!.songKey != null && music.songKey!.isNotEmpty)
          'Tom: ${music.songKey}',
        if (music.addedBy != null && music.addedBy!.isNotEmpty)
          'Adicionado por ${music.addedBy}',
      ];
      if (metaParts.isNotEmpty) musicMetaText = metaParts.join(' • ');
    }

    final thumbnailUrl = music?.songYouTubeUrl?.isNotEmpty == true
        ? YoutubeUtils.getThumbnail(music!.songYouTubeUrl, quality: 'default')
        : null;

    final Widget avatarFallback = CircleAvatar(
      radius: 18,
      backgroundColor: avatarBgColor,
      child: Icon(iconData, color: avatarFgColor, size: 18),
    );

    final Widget avatar = thumbnailUrl != null
        ? ClipOval(
            child: Image.network(
              thumbnailUrl,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => avatarFallback,
            ),
          )
        : avatarFallback;

    Widget trailing = ReorderableDragStartListener(
      index: itemIndex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.drag_handle, color: cs.onSurfaceVariant),
      ),
    );

    if (isAdmin) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEditable) ...[
            IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                foregroundColor: cs.onSecondaryContainer,
                backgroundColor: cs.secondaryContainer,
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: onEdit,
            ),
            const SizedBox(width: 4),
            IconButton.filledTonal(
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                foregroundColor: cs.onErrorContainer,
                backgroundColor: cs.errorContainer,
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              onPressed: onDelete,
            ),
          ],
          const SizedBox(width: 4),
          ReorderableDragStartListener(
            index: itemIndex,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.drag_handle, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      );
    }

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          avatar,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleText,
                  style: isEditable
                      ? theme.textTheme.titleLarge
                      : theme.textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitleText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
                if (musicMetaText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    musicMetaText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isAdmin) ...[const SizedBox(width: 8), trailing],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              '$position',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          isEditable
              ? content
              : DecoratedBox(
                  decoration: appCardDecoration(context, radius: AppRadius.cardHero),
                  child: content,
                ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyProgramState extends StatelessWidget {
  const _EmptyProgramState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: appCardDecoration(context, radius: AppRadius.cardHero),
      child: Column(
        children: [
          SvgPicture.asset(
            'assets/icons/clipboard-clock.svg',
            width: 30,
            height: 30,
            colorFilter: ColorFilter.mode(
              cs.onSurfaceVariant,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sem programação',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A programação deste evento está vazia.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Text item form dialog
// ---------------------------------------------------------------------------

class _TextItemDialog extends StatefulWidget {
  final TextProgramItemEntity? item;

  const _TextItemDialog({this.item});

  @override
  State<_TextItemDialog> createState() => _TextItemDialogState();
}

class _TextItemDialogState extends State<_TextItemDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item?.title ?? '');
    _descCtrl = TextEditingController(text: widget.item?.description ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(
      context,
    ).pop((title: _titleCtrl.text.trim(), description: _descCtrl.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.item != null;

    return AlertDialog(
      title: Text(isEdit ? 'Editar item' : 'Adicionar item'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe um título' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                alignLabelWithHint: true,
              ),
              textInputAction: TextInputAction.done,
              maxLines: 3,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }
}
