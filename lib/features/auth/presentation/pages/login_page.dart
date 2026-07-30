import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../../../core/ui/widgets/app_logo.dart';
import '../../../../core/notifications/push_notification_service.dart';
import '../../../root/presentation/pages/root_page.dart';
import '../../data/repositories/impl/auth_repository_impl.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

const _googleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18">
  <path fill="#4285F4" d="M17.64 9.2045c0-.6381-.0573-1.2518-.1636-1.8409H9v3.4818h4.8436c-.2086 1.125-.8427 2.0782-1.7959 2.7164v2.2582h2.9087c1.7018-1.5668 2.6836-3.8741 2.6836-6.6155z"/>
  <path fill="#34A853" d="M9 18c2.43 0 4.4673-.806 5.9564-2.1805l-2.9087-2.2582c-.8059.54-1.8368.8591-3.0477.8591-2.344 0-4.3282-1.5831-5.036-3.7104H.9573v2.3318C2.4382 15.9832 5.4818 18 9 18z"/>
  <path fill="#FBBC05" d="M3.964 10.71c-.18-.54-.2827-1.1168-.2827-1.71s.1027-1.17.2827-1.71V4.9582H.9573C.3477 6.1732 0 7.5477 0 9s.3477 2.8268.9573 4.0418L3.964 10.71z"/>
  <path fill="#EA4335" d="M9 3.5795c1.3214 0 2.5077.4541 3.4405 1.346l2.5814-2.5814C13.4632.8918 11.4259 0 9 0 5.4818 0 2.4382 2.0168.9573 4.9582L3.964 7.29C4.6718 5.1627 6.656 3.5795 9 3.5795z"/>
</svg>
''';

class LoginPage extends StatelessWidget {
  static const routeName = '/login';

  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => AuthRepositoryImpl(),
      child: BlocProvider(
        create: (ctx) => LoginCubit(ctx.read<AuthRepositoryImpl>()),
        child: const _LoginView(),
      ),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
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
              child: BlocListener<LoginCubit, LoginState>(
                listenWhen: (p, c) => p.status != c.status,
                listener: (context, state) {
                  if (state.status == LoginStatus.failure) {
                    if (state.errorStatusCode == 409 &&
                        (state.errorMessage?.trim().isNotEmpty ?? false)) {
                      showDialog<void>(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.cardLarge),
                            ),
                            title: const Text('Atenção'),
                            content: Text(state.errorMessage!),
                            actions: [
                              AppPrimaryButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                height: 44,
                                child: const Text('Entendi'),
                              ),
                            ],
                          );
                        },
                      );
                      return;
                    }

                    AppFeedback.showError(
                      state.errorMessage ?? 'Erro no login',
                    );
                  }

                  if (state.status == LoginStatus.success) {
                    final name = state.auth?.user.firstName ?? '';

                    Navigator.of(
                      context,
                    ).pushReplacementNamed(RootPage.routeName);

                    Future.delayed(const Duration(milliseconds: 300), () {
                      AppFeedback.showSuccess('Bem-vindo, $name!');
                    });

                    unawaited(
                      Future(() async {
                        await PushNotificationService.instance.initialize();
                        await PushNotificationService.instance.syncTokenNow();
                      }).catchError((Object e) {
                        debugPrint('Push notification setup falhou: $e');
                      }),
                    );
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppLogo(height: 42),
                    const SizedBox(height: 22),
                    Text(
                      'Gerencie bandas, ministérios e eventos com simplicidade',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 24),
                    const Divider(indent: 120, endIndent: 120),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Usuário',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      onChanged: (v) =>
                          context.read<LoginCubit>().usernameChanged(v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      onChanged: (v) =>
                          context.read<LoginCubit>().passwordChanged(v),
                      onSubmitted: (_) => context.read<LoginCubit>().submit(),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => openForgotPasswordPage(context),
                        child: const Text('Esqueceu a senha?'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<LoginCubit, LoginState>(
                      buildWhen: (p, c) =>
                          p.status != c.status || p.method != c.method,
                      builder: (context, state) {
                        final passwordLoading =
                            state.status == LoginStatus.loading &&
                            state.method == LoginMethod.password;
                        final anyLoading = state.status == LoginStatus.loading;

                        return AppPrimaryButton(
                          onPressed: anyLoading
                              ? null
                              : () => context.read<LoginCubit>().submit(),
                          child: passwordLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Entrar'),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('ou'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<LoginCubit, LoginState>(
                      buildWhen: (p, c) =>
                          p.status != c.status || p.method != c.method,
                      builder: (context, state) {
                        final googleLoading =
                            state.status == LoginStatus.loading &&
                            state.method == LoginMethod.google;
                        final anyLoading = state.status == LoginStatus.loading;

                        return AppSecondaryButton(
                          onPressed: anyLoading
                              ? null
                              : () =>
                                    context.read<LoginCubit>().loginWithGoogle(),
                          leading: googleLoading
                              ? null
                              : SvgPicture.string(
                                  _googleLogoSvg,
                                  height: 20,
                                  width: 20,
                                ),
                          child: googleLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Continuar com Google'),
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Ainda não tem uma conta?'),
                        TextButton(
                          onPressed: () => openRegisterPage(context),
                          child: const Text('Criar conta'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

