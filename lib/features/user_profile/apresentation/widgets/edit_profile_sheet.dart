import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
                : _buildContent(context, cubit, state),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    EditProfileCubit cubit,
    EditProfileState state,
  ) {
    final canEdit = state.user != null;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FieldLabel(label: 'Nome'),
          TextFormField(
            controller: _firstNameController,
            enabled: canEdit && !state.isSubmitting,
            decoration: appFormFieldDecoration(
              context,
              hintText: 'Seu nome',
              prefixIcon: Icons.badge_outlined,
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Informe seu nome.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          const _FieldLabel(label: 'Sobrenome'),
          TextFormField(
            controller: _lastNameController,
            enabled: canEdit && !state.isSubmitting,
            decoration: appFormFieldDecoration(
              context,
              hintText: 'Seu sobrenome',
              prefixIcon: Icons.badge_rounded,
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return 'Informe seu sobrenome.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          const _FieldLabel(label: 'Email'),
          TextFormField(
            controller: _emailController,
            enabled: false,
            keyboardType: TextInputType.emailAddress,
            decoration: appFormFieldDecoration(
              context,
              hintText: 'voce@email.com',
              prefixIcon: Icons.email_outlined,
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
          const SizedBox(height: 14),
          const _FieldLabel(label: 'Telefone'),
          TextFormField(
            controller: _phoneController,
            enabled: canEdit && !state.isSubmitting,
            keyboardType: TextInputType.phone,
            decoration: appFormFieldDecoration(
              context,
              hintText: '82999999999',
              prefixIcon: Icons.phone_outlined,
            ),
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
                child: OutlinedButton(
                  style: appSecondaryPillButtonStyle(context),
                  onPressed: state.isSubmitting
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: appPrimaryPillButtonStyle(context),
                  onPressed: !canEdit || state.isSubmitting
                      ? null
                      : () => _submit(context, cubit),
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
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

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

class _InlineErrorMessage extends StatelessWidget {
  final String message;

  const _InlineErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF991B1B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
