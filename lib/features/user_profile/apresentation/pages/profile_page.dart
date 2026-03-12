import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:louvor4_app/core/auth/auth_service.dart';
import 'package:louvor4_app/core/network/api_client.dart';
import 'package:louvor4_app/core/theme/app_theme_controller.dart';
import 'package:louvor4_app/core/ui/app_feedback.dart';
import 'package:louvor4_app/core/ui/widgets/app_card_surface.dart';
import 'package:louvor4_app/features/auth/presentation/pages/login_page.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/user_detail_entity.dart';

import '../../data/impl/user_repository_impl.dart';
import '../../data/user_repository.dart';
import 'edit_profile_page.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<UserRepository>(
      create: (_) => UserRepositoryImpl(),
      child: BlocProvider(
        create: (context) => UserCubit(context.read<UserRepository>())..load(),
        child: Scaffold(
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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildTopCard(context, user, state.isUploadingImage),
                      const SizedBox(height: 16),
                      _buildInfoCard(user, context),
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

  // Card de Identificação
  Widget _buildTopCard(
    BuildContext context,
    UserDetailEntity user,
    bool isUploadingImage,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = theme.textTheme.titleLarge?.color;
    final subtitleColor = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.78,
    );
    final profileImage = user.profileImage?.trim();
    final hasProfileImage = profileImage != null && profileImage.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: AppCardSurface(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        radius: 24,
        child: Column(
          children: [
            InkWell(
              onTap: isUploadingImage
                  ? null
                  : () => _onChangeProfileImage(context),
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    foregroundImage: hasProfileImage
                        ? NetworkImage(profileImage)
                        : null,
                    backgroundColor: isDark
                        ? const Color(0xFF172554)
                        : const Color(0xFFEFF6FF),
                    child: !hasProfileImage
                        ? Text(
                            _buildUserInitial(user),
                            style: const TextStyle(
                              color: Color(0xFF0166FF),
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F4CDA),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF111827)
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: isUploadingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque na imagem para alterar',
              style: TextStyle(fontSize: 12, color: subtitleColor),
            ),
            const SizedBox(height: 20),
            Text(
              '${user.firstName} ${user.lastName}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.firstName,
              style: TextStyle(fontSize: 16, color: subtitleColor),
            ),
          ],
        ),
      ),
    );
  }

  // Card de Informações Detalhadas
  Widget _buildInfoCard(UserDetailEntity user, BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = theme.textTheme.titleMedium?.color;
    final borderColor = theme.brightness == Brightness.dark
        ? const Color(0xFF334155)
        : Colors.grey.shade300;

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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
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
            _buildInfoField(context, 'Bio', 'Descrição'),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () => _onEditProfile(context),
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text('Editar'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                foregroundColor: titleColor,
              ),
            ),

            const SizedBox(height: 12),

            AnimatedBuilder(
              animation: AppThemeController.instance,
              builder: (context, _) {
                return SwitchListTile(
                  value: AppThemeController.instance.isDarkMode,
                  onChanged: (value) =>
                      AppThemeController.instance.setDarkMode(value),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Modo escuro',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Ativar tema escuro no aplicativo'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                  activeThumbColor: const Color(0xFF0166FF),
                );
              },
            ),

            const SizedBox(height: 12),

            // Botão Sair
            OutlinedButton.icon(
              onPressed: () async {
                await AuthService.instance.logout(ApiClient.dio);
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, size: 20, color: Colors.redAccent),
              label: const Text('Sair do Aplicativo'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                foregroundColor: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final labelColor = theme.textTheme.bodySmall?.color?.withValues(
      alpha: 0.78,
    );
    final valueColor = theme.textTheme.bodyLarge?.color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
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
    AppFeedback.showSuccess('Seu usuario foi atualizado!');
  }

  String _buildUserInitial(UserDetailEntity user) {
    final source = user.firstName.trim().isNotEmpty
        ? user.firstName.trim()
        : user.email.trim();
    if (source.isEmpty) return '?';
    return source[0].toUpperCase();
  }
}
