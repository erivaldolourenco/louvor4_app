import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
import '../../data/user_repository.dart';
import '../../domain/entities/update_user_input_entity.dart';
import '../../domain/entities/user_detail_entity.dart';
import '../cubit/edit_profile_cubit.dart';
import '../cubit/edit_profile_state.dart';

Future<UserDetailEntity?> showEditProfileSheet(BuildContext context) {
  return showModalBottomSheet<UserDetailEntity>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return RepositoryProvider.value(
        value: context.read<UserRepository>(),
        child: BlocProvider(
          create: (ctx) =>
              EditProfileCubit(ctx.read<UserRepository>())..loadProfile(),
          child: const _EditProfileSheet(),
        ),
      );
    },
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _didFillControllers = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditProfileCubit>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: BlocBuilder<EditProfileCubit, EditProfileState>(
        builder: (context, state) {
          final user = state.user;
          if (user != null && !_didFillControllers) {
            _firstNameController.text = user.firstName;
            _lastNameController.text = user.lastName;
            _emailController.text = user.email;
            _phoneController.text = user.phoneNumber ?? '';
            _didFillControllers = true;
          }

          return AppFormSheet(
            title: 'Editar perfil',
            subtitle: 'Atualize suas informacoes pessoais.',
            icon: Icons.person_outline_rounded,
            child: state.isLoadingProfile
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _buildForm(context, cubit, state),
          );
        },
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    EditProfileCubit cubit,
    EditProfileState state,
  ) {
    final cs = Theme.of(context).colorScheme;
    final canEdit = state.user != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _firstNameController,
            enabled: canEdit && !state.isSubmitting,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nome',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Informe seu nome.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastNameController,
            enabled: canEdit && !state.isSubmitting,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Sobrenome',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Informe seu sobrenome.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            enabled: false,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) return 'Informe seu email.';
              final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
              if (!emailRegex.hasMatch(text)) {
                return 'Informe um email valido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            enabled: canEdit && !state.isSubmitting,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Telefone',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            onFieldSubmitted: (_) => _submit(context, cubit),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Informe seu telefone.';
              }
              return null;
            },
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            _InlineErrorMessage(message: state.errorMessage!),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppPrimaryButton(
                  onPressed: !canEdit || state.isSubmitting
                      ? null
                      : () => _submit(context, cubit),
                  child: state.isSubmitting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Text('Salvar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context, EditProfileCubit cubit) async {
    if (!_formKey.currentState!.validate()) return;

    final updated = await cubit.submit(
      UpdateUserInputEntity(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      ),
    );

    if (!mounted || updated == null) return;
    Navigator.of(this.context).pop(updated);
  }
}

class _InlineErrorMessage extends StatelessWidget {
  final String message;

  const _InlineErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: cs.error.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
