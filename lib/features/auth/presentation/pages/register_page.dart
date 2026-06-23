import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/ui/app_feedback.dart';
import '../../../../core/ui/widgets/app_buttons.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/impl/auth_repository_impl.dart';
import '../../domain/entities/create_user_input_entity.dart';
import '../cubit/register_cubit.dart';
import '../cubit/register_state.dart';

Future<bool?> openRegisterPage(BuildContext context) {
  return Navigator.of(
    context,
  ).push<bool>(MaterialPageRoute(builder: (_) => const RegisterPage()));
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<AuthRepository>(
      create: (_) => AuthRepositoryImpl(),
      child: BlocProvider(
        create: (ctx) => RegisterCubit(ctx.read<AuthRepository>()),
        child: const _RegisterView(),
      ),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasInteracted = false;
  bool _isFormValid = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
              child: BlocListener<RegisterCubit, RegisterState>(
                listenWhen: (p, c) => p.status != c.status,
                listener: (context, state) {
                  if (state.status == RegisterStatus.failure &&
                      (state.errorMessage?.trim().isNotEmpty ?? false)) {
                    AppFeedback.showError(state.errorMessage!);
                  }

                  if (state.status == RegisterStatus.success) {
                    AppFeedback.showSuccess(
                      'Cadastro realizado com sucesso. Faça login para continuar.',
                    );
                    Navigator.of(context).pop(true);
                  }
                },
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _hasInteracted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SvgPicture.asset(
                          'assets/images/logos/logo.svg',
                          height: 42,
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Crie sua conta para gerenciar bandas, ministérios e eventos',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 24),
                        const Divider(indent: 120, endIndent: 120),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _firstNameController,
                          textInputAction: TextInputAction.next,
                          maxLength: 100,
                          onChanged: (_) => _onFormChanged(),
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: _validateFirstName,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lastNameController,
                          textInputAction: TextInputAction.next,
                          maxLength: 100,
                          onChanged: (_) => _onFormChanged(),
                          decoration: const InputDecoration(
                            labelText: 'Sobrenome',
                            prefixIcon: Icon(Icons.badge_rounded),
                          ),
                          validator: _validateLastName,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          maxLength: 255,
                          onChanged: (_) => _onFormChanged(),
                          decoration: const InputDecoration(
                            labelText: 'Usuário',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          validator: _validateUsername,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          maxLength: 255,
                          onChanged: (_) => _onFormChanged(),
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'voce@email.com',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          maxLength: 255,
                          onChanged: (_) => _onFormChanged(),
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: _validatePassword,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          maxLength: 255,
                          onChanged: (_) => _onFormChanged(),
                          decoration: InputDecoration(
                            labelText: 'Confirmar senha',
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: _validateConfirmPassword,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 16),
                        BlocBuilder<RegisterCubit, RegisterState>(
                          buildWhen: (p, c) => p.status != c.status,
                          builder: (context, state) {
                            return AppPrimaryButton(
                              onPressed: state.isSubmitting || !_isFormValid
                                  ? null
                                  : _submit,
                              child: state.isSubmitting
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Criar conta'),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        AppSecondaryButton(
                          onPressed: () =>
                              Navigator.of(context).maybePop(false),
                          child: const Text('Voltar para login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _hasInteracted = true);
    if (!_formKey.currentState!.validate()) {
      _onFormChanged();
      return;
    }

    await context.read<RegisterCubit>().submit(
      CreateUserInputEntity(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        email: _emailController.text,
      ),
    );
  }

  void _onFormChanged() {
    if (!_hasInteracted) {
      setState(() => _hasInteracted = true);
    }

    final isValid =
        _validateFirstName(_firstNameController.text) == null &&
        _validateLastName(_lastNameController.text) == null &&
        _validateUsername(_usernameController.text) == null &&
        _validateEmail(_emailController.text) == null &&
        _validatePassword(_passwordController.text) == null &&
        _validateConfirmPassword(_confirmPasswordController.text) == null;

    if (isValid != _isFormValid) {
      setState(() => _isFormValid = isValid);
    }
  }

  String? _validateFirstName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Informe seu nome.';
    if (text.length < 3) return 'O nome deve ter no mínimo 3 caracteres.';
    if (text.length > 100) return 'O nome deve ter no máximo 100 caracteres.';
    if (!RegExp(r'^[A-Za-zÀ-ÖØ-öø-ÿ]+(?:\s+[A-Za-zÀ-ÖØ-öø-ÿ]+)*$').hasMatch(text)) {
      return 'O nome deve conter apenas letras.';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Informe seu sobrenome.';
    if (text.length < 3) {
      return 'O sobrenome deve ter no mínimo 3 caracteres.';
    }
    if (text.length > 100) {
      return 'O sobrenome deve ter no máximo 100 caracteres.';
    }
    if (!RegExp(r'^[A-Za-zÀ-ÖØ-öø-ÿ]+(?:\s+[A-Za-zÀ-ÖØ-öø-ÿ]+)*$').hasMatch(text)) {
      return 'O sobrenome deve conter apenas letras.';
    }
    return null;
  }

  String? _validateUsername(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Informe um usuário.';
    if (text.length < 5) return 'O usuário deve ter no mínimo 5 caracteres.';
    if (text.length > 255) {
      return 'O usuário deve ter no máximo 255 caracteres.';
    }
    if (!RegExp(r'^[A-Za-z]').hasMatch(text)) {
      return 'O usuário deve começar com uma letra.';
    }
    if (RegExp(r'[.-]$').hasMatch(text)) {
      return 'O usuário não pode terminar com ponto ou traço.';
    }
    if (!RegExp(r'^[A-Za-z][A-Za-z0-9.-]*$').hasMatch(text)) {
      return 'Use apenas letras, números, ponto ou traço.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Informe seu email.';
    if (text.length > 255) return 'O email deve ter no máximo 255 caracteres.';
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(text)) return 'Informe um email válido.';
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Informe uma senha.';
    if (text.length < 6) return 'A senha deve ter no mínimo 6 caracteres.';
    if (text.length > 255) return 'A senha deve ter no máximo 255 caracteres.';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Confirme sua senha.';
    if (text != _passwordController.text) {
      return 'As senhas precisam ser iguais.';
    }
    return null;
  }
}

