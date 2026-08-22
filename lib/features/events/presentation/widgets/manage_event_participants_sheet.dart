import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:louvor4_app/core/ui/widgets/app_cached_network_image.dart';

import '../../../../../core/theme/app_extra_colors.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../../../core/utils/skill_icon.dart';
import '../../../../core/utils/url_utils.dart';
import '../../data/events_repository.dart';
import '../../domain/entities/event_detail_entity.dart';
import '../../domain/entities/event_participant_entity.dart';
import '../cubit/manage_event_participants_cubit.dart';
import '../cubit/manage_event_participants_state.dart';
import '../models/selectable_event_member.dart';

Future<bool?> showManageEventParticipantsSheet(
  BuildContext context, {
  required EventDetailEntity event,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return RepositoryProvider.value(
        value: context.read<EventsRepository>(),
        child: BlocProvider(
          create: (ctx) =>
              ManageEventParticipantsCubit(ctx.read<EventsRepository>())
                ..load(eventId: event.id, projectId: event.projectId),
          child: _ManageEventParticipantsSheet(event: event),
        ),
      );
    },
  );
}

class _ManageEventParticipantsSheet extends StatelessWidget {
  final EventDetailEntity event;

  const _ManageEventParticipantsSheet({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.65,
      maxChildSize: 0.96,
      expand: false,
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.sheet),
            ),
          ),
          child: SafeArea(
            top: false,
            child:
                BlocConsumer<
                  ManageEventParticipantsCubit,
                  ManageEventParticipantsState
                >(
                  listenWhen: (previous, current) =>
                      previous.status != current.status &&
                      current.status == ManageEventParticipantsStatus.success,
                  listener: (context, state) {
                    AppFeedback.showSuccess('Escala atualizada com sucesso.');
                    Navigator.of(context).pop(true);
                  },
                  builder: (context, state) {
                    final cubit = context.read<ManageEventParticipantsCubit>();

                    return Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: cs.outlineVariant,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gerenciar escala',
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: cs.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      event.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (state.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                              decoration: BoxDecoration(
                                color: cs.errorContainer,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.card,
                                ),
                                border: Border.all(
                                  color: cs.error.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Text(
                                        state.errorMessage!,
                                        style: TextStyle(
                                          color: cs.onErrorContainer,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Fechar',
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: cs.onErrorContainer,
                                    ),
                                    onPressed: cubit.dismissError,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Expanded(
                          child: state.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : RefreshIndicator(
                                  onRefresh: () => cubit.load(
                                    eventId: event.id,
                                    projectId: event.projectId,
                                  ),
                                  child: state.members.isEmpty
                                      ? ListView(
                                          controller: scrollController,
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          padding: const EdgeInsets.fromLTRB(
                                            20,
                                            32,
                                            20,
                                            120,
                                          ),
                                          children: const [_SheetEmptyState()],
                                        )
                                      : ListView.builder(
                                          controller: scrollController,
                                          padding: const EdgeInsets.fromLTRB(
                                            20,
                                            8,
                                            20,
                                            120,
                                          ),
                                          itemCount: state.members.length,
                                          itemBuilder: (context, index) {
                                            final item = state.members[index];
                                            return _SelectableMemberCard(
                                              item: item,
                                              skillsMap: state.skillsMap,
                                            );
                                          },
                                        ),
                                ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          decoration: BoxDecoration(
                            color: cs.surface,
                            border: Border(
                              top: BorderSide(color: cs.outlineVariant),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: AppSecondaryButton(
                                  onPressed: state.isSubmitting
                                      ? null
                                      : () => Navigator.of(context).maybePop(),
                                  child: const Text('Cancelar'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: AppPrimaryButton(
                                  onPressed: state.isSubmitting
                                      ? null
                                      : () => cubit.submit(event.id),
                                  child: state.isSubmitting
                                      ? const Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : const Center(
                                          child: Text(
                                            'Salvar',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
          ),
        );
      },
    );
  }
}

class _SelectableMemberCard extends StatelessWidget {
  final SelectableEventMember item;
  final Map<String, String> skillsMap;

  const _SelectableMemberCard({required this.item, required this.skillsMap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cubit = context.read<ManageEventParticipantsCubit>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: appExpressiveCurve,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.cardLarge),
        border: Border.all(
          color: item.isSelected ? cs.primary : cs.outlineVariant,
          width: item.isSelected ? 1.4 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.card),
                onTap: () =>
                    cubit.toggleMember(item.member.id, !item.isSelected),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _MemberAvatar(imageUrl: item.member.profileImage),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.member.fullName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.member.projectRole ?? 'Membro',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IgnorePointer(
                      child: Checkbox(
                        value: item.isSelected,
                        onChanged: (_) {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              firstCurve: Curves.easeOut,
              secondCurve: Curves.easeIn,
              sizeCurve: appExpressiveCurve,
              crossFadeState: item.isSelected
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(height: 1, color: cs.outlineVariant),
                    const SizedBox(height: 14),
                    Text(
                      'Função no evento',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _SkillOptionButton(
                          label: 'Nenhuma',
                          isSelected: item.selectedSkillId == null,
                          onTap: () => cubit.updateSkill(item.member.id, null),
                        ),
                        ...item.availableSkills.map(
                          (skill) => _SkillOptionButton(
                            label: skillsMap[skill.id] ?? skill.name,
                            iconKey: skill.iconKey,
                            isSelected: item.selectedSkillId == skill.id,
                            onTap: () =>
                                cubit.updateSkill(item.member.id, skill.id),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Permissões no evento',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      value: item.permissions.contains(EventPermission.addSong),
                      onChanged: (value) => cubit.togglePermission(
                        item.member.id,
                        EventPermission.addSong,
                        value,
                      ),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Permite adicionar músicas'),
                    ),
                    SwitchListTile(
                      value: item.permissions.contains(
                        EventPermission.editChordSheet,
                      ),
                      onChanged: (value) => cubit.togglePermission(
                        item.member.id,
                        EventPermission.editChordSheet,
                        value,
                      ),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Permite editar cifra'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillOptionButton extends StatelessWidget {
  final String label;
  final String? iconKey;
  final bool isSelected;
  final VoidCallback onTap;

  const _SkillOptionButton({
    required this.label,
    this.iconKey,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final extraColors = theme.extension<AppExtraColors>()!;
    final contentColor = isSelected ? cs.onPrimary : cs.onSurfaceVariant;
    return Material(
      color: isSelected ? cs.primary : cs.surface,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: appExpressiveCurve,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected ? cs.primary : cs.outlineVariant,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconKey != null) ...[
                CircleAvatar(
                  radius: 11,
                  backgroundColor: extraColors.iconBadgeSurface,
                  child: SvgPicture.asset(
                    skillIconAsset(iconKey),
                    width: 14,
                    height: 14,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: contentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final String? imageUrl;

  const _MemberAvatar({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasImage = UrlUtils.isValidNetworkUrl(imageUrl);
    return CircleAvatar(
      radius: 24,
      backgroundColor: cs.surfaceContainerHigh,
      backgroundImage: hasImage ? appCachedImageProvider(imageUrl) : null,
      child: hasImage
          ? null
          : Icon(Icons.person_rounded, color: cs.onSurfaceVariant),
    );
  }
}

class _SheetEmptyState extends StatelessWidget {
  const _SheetEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.group_off_rounded, size: 40, color: cs.onSurfaceVariant),
        const SizedBox(height: 12),
        Text(
          'Nenhum membro encontrado para este projeto.',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}
