import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:louvor4_app/core/auth/auth_service.dart';
import 'package:louvor4_app/core/network/api_client.dart';
import 'package:louvor4_app/core/theme/app_theme_controller.dart';
import 'package:louvor4_app/core/ui/app_feedback.dart';
import 'package:louvor4_app/core/ui/widgets/app_cached_network_image.dart';
import 'package:louvor4_app/core/ui/widgets/app_card_surface.dart';
import 'package:louvor4_app/core/ui/widgets/app_buttons.dart';
import 'package:louvor4_app/core/ui/widgets/fade_slide_in.dart';
import 'package:louvor4_app/core/ui/widgets/spring_tap.dart';
import 'package:louvor4_app/features/auth/presentation/pages/login_page.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/user_detail_entity.dart';

import '../../data/impl/user_repository_impl.dart';
import '../../data/user_repository.dart';
import 'edit_profile_page.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_state.dart';

class ProfilePage extends StatelessWidget {
  static const routeName = '/perfil';

  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<UserRepository>(
      create: (_) => UserRepositoryImpl(),
      child: BlocProvider(
        create: (context) => UserCubit(context.read<UserRepository>())..load(),
        child: Scaffold(
          appBar: AppBar(title: const Text('Perfil')),
          body: BlocBuilder<UserCubit, UserState>(
            builder: (context, state) {
              if (state.status == UserStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.status == UserStatus.failure) {
                return Center(
                  child: Text(state.errorMessage ?? 'Erro ao carregar'),
                );
              }

              if (state.status == UserStatus.success && state.user != null) {
                final user = state.user!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                  child: Column(
                    children: [
                      FadeSlideIn(
                        child: _buildTopCard(
                          context,
                          user,
                          state.isUploadingImage,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 90),
                        child: _buildInfoCard(user, context),
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopCard(
    BuildContext context,
    UserDetailEntity user,
    bool isUploadingImage,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final profileImage = user.profileImage?.trim();
    final hasProfileImage = profileImage != null && profileImage.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: AppCardSurface(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        radius: 24,
        child: Column(
          children: [
            SpringTap(
              onTap: isUploadingImage
                  ? null
                  : () => _onChangeProfileImage(context),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 112,
                    height: 112,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isUploadingImage ? 1 : 0,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: CircleAvatar(
                      key: ValueKey(
                        hasProfileImage ? profileImage : 'placeholder',
                      ),
                      radius: 50,
                      foregroundImage: hasProfileImage
                          ? appCachedImageProvider(profileImage)
                          : null,
                      backgroundColor: cs.primaryContainer,
                      child: !hasProfileImage
                          ? Text(
                              _buildUserInitial(user),
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isUploadingImage ? 0.4 : 1,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 2),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque na imagem para alterar',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${user.firstName} ${user.lastName}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _buildProfileSubtitle(user),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(UserDetailEntity user, BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: AppCardSurface(
        padding: const EdgeInsets.all(24),
        radius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações pessoais',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoField(context, 'Nome', user.firstName),
            _buildInfoField(context, 'Sobrenome', user.lastName),
            _buildInfoField(context, 'Email', user.email),
            _buildInfoField(
              context,
              'Telefone',
              user.phoneNumber ?? 'Não informado',
            ),
            const SizedBox(height: 12),
            AppSecondaryButton(
              onPressed: () => _onEditProfile(context),
              icon: Icons.edit_outlined,
              child: const Text('Editar perfil'),
            ),
            const SizedBox(height: 4),
            AnimatedBuilder(
              animation: AppThemeController.instance,
              builder: (context, _) {
                return SwitchListTile(
                  value: AppThemeController.instance.isDarkMode,
                  onChanged: (value) =>
                      AppThemeController.instance.setDarkMode(value),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Modo escuro',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text('Ativar tema escuro no aplicativo'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                );
              },
            ),
            const SizedBox(height: 4),
            AppDestructiveButton(
              onPressed: () async {
                await AuthService.instance.logout(ApiClient.dio);
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    LoginPage.routeName,
                    (route) => false,
                  );
                }
              },
              icon: Icons.logout_rounded,
              child: const Text('Sair do aplicativo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onChangeProfileImage(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (image == null || !context.mounted) return;

    final success = await context.read<UserCubit>().updateProfileImage(
      filePath: image.path,
      fileName: image.name,
    );

    if (!context.mounted) return;

    if (success) {
      AppFeedback.showSuccess('Imagem de perfil atualizada.');
    } else {
      AppFeedback.showError('Não foi possível atualizar a imagem do perfil.');
    }
  }

  Future<void> _onEditProfile(BuildContext context) async {
    final updatedUser = await openEditProfilePage(
      context,
      repository: context.read<UserRepository>(),
    );
    if (!context.mounted || updatedUser == null) return;

    context.read<UserCubit>().updateLocalUser(updatedUser);
    AppFeedback.showSuccess('Perfil atualizado com sucesso.');
  }

  String _buildUserInitial(UserDetailEntity user) {
    final source = user.firstName.trim().isNotEmpty
        ? user.firstName.trim()
        : user.email.trim();
    if (source.isEmpty) return '?';
    return source[0].toUpperCase();
  }

  String _buildProfileSubtitle(UserDetailEntity user) {
    final username = user.username.trim().isNotEmpty
        ? '@${user.username.trim()}'
        : '@nao_informado';
    final planName = user.planName?.trim();
    if (planName == null || planName.isEmpty) return username;
    return '$username · $planName';
  }
}
