import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_form_sheet.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/impl/auth_repository_impl.dart';
import '../cubit/forgot_password_cubit.dart';
import '../cubit/forgot_password_state.dart';

Future<void> openForgotPasswordPage(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
  );
}

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>(
      create: (_) => AuthRepositoryImpl(),
      child: BlocProvider(
        create: (ctx) => ForgotPasswordCubit(ctx.read<AuthRepository>()),
        child: const _ForgotPasswordView(),
      ),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
                listenWhen: (p, c) => p.status != c.status,
                listener: (context, state) {
                  if (state.status == ForgotPasswordStatus.failure &&
                      (state.errorMessage?.trim().isNotEmpty ?? false)) {
                    AppFeedback.showError(state.errorMessage!);
                  }

                  if (state.status == ForgotPasswordStatus.codeSent) {
                    final canal = state.selectedChannel == 'SMS' ? 'celular' : 'e-mail';
                    AppFeedback.showInfo('Código enviado para seu $canal!');
                  }

                  if (state.status == ForgotPasswordStatus.success) {
                    AppFeedback.showSuccess('Senha redefinida com sucesso! Faça login.');
                    Navigator.of(context).pop();
                  }
                },
                child: BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
                  builder: (context, state) {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          SvgPicture.asset('assets/images/logos/logo.svg', height: 42),
                          const SizedBox(height: 22),
                          Text(
                            _titleForStep(state.step),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 24),
                          const Divider(indent: 120, endIndent: 120),
                          const SizedBox(height: 28),
                          if (state.step == 1) _buildStep1(context, state),
                          if (state.step == 2) _buildStep2(context, state, theme),
                          if (state.step == 3) _buildStep3(context, state),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            style: appSecondaryPillButtonStyle(context),
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: const Text('Voltar para login'),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _titleForStep(int step) => switch (step) {
        1 => 'Informe seu e-mail para recuperar o acesso',
        2 => 'Como deseja receber o código?',
        _ => 'Digite o código recebido e crie uma nova senha',
      };

  Widget _buildStep1(BuildContext context, ForgotPasswordState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(label: 'E-mail'),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          decoration: appFormFieldDecoration(
            context,
            hintText: 'voce@email.com',
            prefixIcon: Icons.email_outlined,
          ),
          onChanged: (v) => context.read<ForgotPasswordCubit>().emailChanged(v),
          onSubmitted: (_) => context.read<ForgotPasswordCubit>().loadChannels(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: appPrimaryPillButtonStyle(context),
          onPressed: state.isLoading
              ? null
              : () => context.read<ForgotPasswordCubit>().loadChannels(),
          child: state.isLoading
              ? const SizedBox(
                  height: 22, width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _buildStep2(
    BuildContext context,
    ForgotPasswordState state,
    ThemeData theme,
  ) {
    final channels = state.channels;
    if (channels == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChannelOption(
          icon: Icons.email_outlined,
          label: 'E-mail',
          subtitle: channels.maskedEmail,
          value: 'EMAIL',
          selected: state.selectedChannel == 'EMAIL',
          onTap: () => context.read<ForgotPasswordCubit>().selectChannel('EMAIL'),
        ),
        if (channels.hasSms) ...[
          const SizedBox(height: 12),
          _ChannelOption(
            icon: Icons.smartphone_outlined,
            label: 'Celular (SMS)',
            subtitle: channels.maskedPhone!,
            value: 'SMS',
            selected: state.selectedChannel == 'SMS',
            onTap: () => context.read<ForgotPasswordCubit>().selectChannel('SMS'),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          style: appPrimaryPillButtonStyle(context),
          onPressed: state.isLoading
              ? null
              : () => context.read<ForgotPasswordCubit>().sendCode(),
          child: state.isLoading
              ? const SizedBox(
                  height: 22, width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar código'),
        ),
      ],
    );
  }

  Widget _buildStep3(BuildContext context, ForgotPasswordState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(label: 'Código de verificação'),
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
          ),
          decoration: appFormFieldDecoration(context, hintText: '000000').copyWith(
            counterText: '',
            hintStyle: const TextStyle(letterSpacing: 8),
          ),
          onChanged: (v) => context.read<ForgotPasswordCubit>().codeChanged(v),
        ),
        const SizedBox(height: 16),
        const _FieldLabel(label: 'Nova senha'),
        TextField(
          controller: _newPasswordCtrl,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          decoration: appFormFieldDecoration(
            context,
            hintText: 'Mínimo 6 caracteres',
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              ),
            ),
          ),
          onChanged: (v) => context.read<ForgotPasswordCubit>().newPasswordChanged(v),
          onSubmitted: (_) => context.read<ForgotPasswordCubit>().resetPassword(),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: appPrimaryPillButtonStyle(context),
          onPressed: state.isLoading
              ? null
              : () => context.read<ForgotPasswordCubit>().resetPassword(),
          child: state.isLoading
              ? const SizedBox(
                  height: 22, width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Redefinir senha'),
        ),
      ],
    );
  }
}

class _ChannelOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _ChannelOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.5),
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: selected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? colorScheme.primary : colorScheme.outline,
            ),
          ],
        ),
      ),
    );
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
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
