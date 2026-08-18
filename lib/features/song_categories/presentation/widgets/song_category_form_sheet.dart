import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
import '../../../../core/ui/widgets/app_inline_error_message.dart';
import '../../domain/entities/song_category_entity.dart';
import '../cubit/song_categories_cubit.dart';
import '../cubit/song_categories_state.dart';

Future<bool?> showSongCategoryFormSheet(
  BuildContext context, {
  required SongCategoriesCubit cubit,
  SongCategoryEntity? category,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.bottomSheet),
      ),
    ),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: SongCategoryFormSheet(category: category),
    ),
  );
}

class SongCategoryFormSheet extends StatefulWidget {
  final SongCategoryEntity? category;

  const SongCategoryFormSheet({super.key, this.category});

  bool get isEditing => category != null;

  @override
  State<SongCategoryFormSheet> createState() => _SongCategoryFormSheetState();
}

class _SongCategoryFormSheetState extends State<SongCategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cubit = context.read<SongCategoriesCubit>();
    final state = context.watch<SongCategoriesCubit>().state;
    final isSubmitting = state.submission == SongCategoriesSubmission.saving;
    final isEditing = widget.isEditing;

    return AppFormSheet(
      title: isEditing ? 'Editar categoria' : 'Nova categoria',
      subtitle: isEditing
          ? 'Altere o nome desta categoria de música.'
          : 'Crie uma categoria para organizar o seu repertório.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              enabled: !isSubmitting,
              autofocus: !isEditing,
              maxLength: SongCategoriesCubit.maxNameLength,
              decoration: const InputDecoration(
                labelText: 'Nome da categoria',
                hintText: 'Ex: Adoração, Natal, Ceia',
                prefixIcon: Icon(Icons.sell_rounded),
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) {
                  return 'Informe o nome da categoria.';
                }
                if (text.length > SongCategoriesCubit.maxNameLength) {
                  return 'Use no máximo ${SongCategoriesCubit.maxNameLength} caracteres.';
                }
                return null;
              },
            ),
            if (state.actionErrorMessage != null) ...[
              const SizedBox(height: 12),
              AppInlineErrorMessage(message: state.actionErrorMessage!),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(context).maybePop(false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppPrimaryButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;

                            final bool success;
                            if (isEditing) {
                              success = await cubit.updateCategory(
                                widget.category!,
                                _nameController.text,
                              );
                            } else {
                              success = await cubit.createCategory(
                                _nameController.text,
                              );
                            }

                            if (!mounted) return;
                            if (success) {
                              Navigator.of(this.context).pop(true);
                            } else if (cubit.state.actionErrorMessage != null) {
                              AppFeedback.showError(
                                cubit.state.actionErrorMessage!,
                              );
                            }
                          },
                    child: isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : Text(isEditing ? 'Salvar alterações' : 'Criar categoria'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
