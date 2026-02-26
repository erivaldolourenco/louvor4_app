import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../root/presentation/pages/root_page.dart';
import '../../data/repositories/impl/auth_repository_impl.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';

class LoginPage extends StatelessWidget {
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
  bool _keepConnected = false;

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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.errorMessage ?? 'Erro no login')),
                    );
                  }

                  if (state.status == LoginStatus.success) {
                    final name = state.auth?.user.firstName ?? '';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bem-vindo $name ✅')),
                    );

                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const RootPage(),
                      ),
                    );
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SvgPicture.asset('assets/images/logos/logo.svg', height: 42),
                    const SizedBox(height: 22),
                    Text(
                      'Gerencie bandas, ministérios e eventos com simplicidade',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 28),
                    const Divider(indent: 120, endIndent: 120),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _userCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Digite seu usuário',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onChanged: (v) => context.read<LoginCubit>().usernameChanged(v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: 'Digite sua senha',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      onChanged: (v) => context.read<LoginCubit>().passwordChanged(v),
                      onSubmitted: (_) => context.read<LoginCubit>().submit(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              visualDensity: VisualDensity.compact,
                              value: _keepConnected,
                              onChanged: (v) => setState(() => _keepConnected = v ?? false),
                            ),
                            const Text('Manter-me conectado'),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Esqueceu a senha?'),
                        )
                      ],
                    ),
                    const SizedBox(height: 22),
                    BlocBuilder<LoginCubit, LoginState>(
                      buildWhen: (p, c) => p.status != c.status,
                      builder: (context, state) {
                        final loading = state.status == LoginStatus.loading;

                        return SizedBox(
                          height: 48,
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: loading ? null : () => context.read<LoginCubit>().submit(),
                            child: loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Entrar'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Ainda não tem uma conta?'),
                        TextButton(onPressed: () {}, child: const Text('Criar conta'))
                      ],
                    )
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
