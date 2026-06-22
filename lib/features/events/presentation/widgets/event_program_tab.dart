import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/utils/youtube_utils.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_async_states.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
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

        final header = Padding(
          padding: const EdgeInsets.fromLTRB(0, 2, 0, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Programação',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isAdmin)
                FilledButton.tonal(
                  onPressed: () => _showTextItemDialog(context),
                  style: appTonalPillButtonStyleCompact(context),
                  child: const Text('Adicionar'),
                ),
            ],
          ),
        );

        if (state.items.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
            children: [
              header,
              _EmptyProgramState(
                isAdmin: isAdmin,
                onAdd: () => _showTextItemDialog(context),
              ),
            ],
          );
        }

        return ReorderableListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
          header: header,
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) {
            if (!isAdmin) return;
            if (newIndex > oldIndex) newIndex -= 1;
            final ids = state.items.map((i) => i.id).toList();
            final id = ids.removeAt(oldIndex);
            ids.insert(newIndex, id);
            context.read<EventProgramCubit>().reorder(ids);
          },
          children: [
            for (int i = 0; i < state.items.length; i++)
              Padding(
                key: ValueKey(state.items[i].id),
                padding: const EdgeInsets.only(bottom: 10),
                child: _ProgramItemCard(
                  item: state.items[i],
                  position: i + 1,
                  isAdmin: isAdmin,
                  itemIndex: i,
                  onEdit: isAdmin && state.items[i] is TextProgramItemEntity
                      ? () => _showTextItemDialog(
                          context,
                          item: state.items[i] as TextProgramItemEntity,
                        )
                      : null,
                  onDelete: isAdmin && state.items[i] is TextProgramItemEntity
                      ? () => _confirmDelete(
                          context,
                          state.items[i] as TextProgramItemEntity,
                        )
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showTextItemDialog(
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
      AppFeedback.showError(
        cubit.state.actionError ?? 'Erro ao salvar item.',
      );
    }
  }

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

// ---------------------------------------------------------------------------
// Item card
// ---------------------------------------------------------------------------

class _ProgramItemCard extends StatelessWidget {
  final ProgramItemEntity item;
  final int position;
  final bool isAdmin;
  final int itemIndex;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ProgramItemCard({
    required this.item,
    required this.position,
    required this.isAdmin,
    required this.itemIndex,
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

    final iconData = isMusic
        ? Icons.music_note_rounded
        : isMedley
            ? Icons.queue_music_rounded
            : Icons.text_fields_rounded;

    final iconColor = isMusic
        ? cs.primary
        : isMedley
            ? cs.secondary
            : cs.tertiary;

    final iconBgColor = isMusic
        ? cs.primaryContainer
        : isMedley
            ? cs.secondaryContainer
            : cs.tertiaryContainer;

    final isEditable = text != null;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: cs.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _PositionBadge(position: position),
            const SizedBox(width: 10),
            if (isMusic && music!.songYouTubeUrl != null && music.songYouTubeUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.input),
                child: Image.network(
                  YoutubeUtils.getThumbnail(music.songYouTubeUrl, quality: 'default'),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, stack) => Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(AppRadius.input),
                    ),
                    child: Icon(iconData, color: iconColor, size: 20),
                  ),
                ),
              )
            else
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isMusic
                        ? music!.songTitle
                        : isMedley
                            ? medley!.medleyName
                            : text!.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isMusic)
                    Text(
                      music!.songArtist,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (isMedley && medley!.songs.isNotEmpty)
                    Text(
                      medley.songs.map((s) => s.title).join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (text != null &&
                      text.description != null &&
                      text.description!.isNotEmpty)
                    Text(
                      text.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 4),
              if (isEditable) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SmallIconButton(
                      icon: Icons.edit_outlined,
                      color: cs.primary,
                      bgColor: cs.primaryContainer,
                      onPressed: onEdit,
                    ),
                    const SizedBox(width: 4),
                    _SmallIconButton(
                      icon: Icons.delete_outline_rounded,
                      color: cs.error,
                      bgColor: cs.errorContainer,
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const SizedBox(width: 6),
              ],
              ReorderableDragStartListener(
                index: itemIndex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    size: 22,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final int position;

  const _PositionBadge({required this.position});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.badge),
        border: Border.all(
          color: cs.outlineVariant,
        ),
      ),
      child: Center(
        child: Text(
          '$position',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? bgColor;
  final VoidCallback? onPressed;

  const _SmallIconButton({
    required this.icon,
    required this.color,
    this.bgColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.badge),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.badge),
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 18,
            color: onPressed == null ? color.withValues(alpha: 0.3) : color,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyProgramState extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onAdd;

  const _EmptyProgramState({required this.isAdmin, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.list_alt_rounded, size: 30, color: cs.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            'Sem programação',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'A programação deste evento está vazia.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Adicionar item de texto'),
              style: appPrimaryPillButtonStyle(context),
            ),
          ],
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
    Navigator.of(context).pop((
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
    ));
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
              decoration: appFormFieldDecoration(context, hintText: 'Título *'),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe um título' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: appFormFieldDecoration(
                context,
                hintText: 'Descrição (opcional)',
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
        FilledButton(
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
