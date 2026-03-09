import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:louvor4_app/core/auth/auth_service.dart';
import 'package:louvor4_app/core/network/api_client.dart';
import 'package:louvor4_app/features/auth/presentation/pages/login_page.dart';
import 'package:louvor4_app/features/user_profile/domain/entities/user_detail_entity.dart';

import '../../data/impl/user_repository_impl.dart';
import '../cubit/user_cubit.dart';
import '../cubit/user_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserCubit(UserRepositoryImpl())..load(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F9),
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
                    _buildTopCard(user),
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
    );
  }

  // Card de Identificação
  Widget _buildTopCard(UserDetailEntity user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: user.profileImage != null
                ? NetworkImage(user.profileImage!)
                : const NetworkImage('https://i.pravatar.cc/300'),
          ),
          const SizedBox(height: 20),
          Text(
            '${user.firstName} ${user.lastName}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2939),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.firstName,
            style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  // Card de Informações Detalhadas
  Widget _buildInfoCard(UserDetailEntity user, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informações pessoais',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2939),
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoField('Nome', user.firstName),
          _buildInfoField('Sobrenome', user.lastName),
          _buildInfoField('Email', user.email),
          _buildInfoField('Telefone', user.phoneNumber ?? 'Não informado'),
          _buildInfoField('Bio', 'Descrição'),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, size: 20),
            label: const Text('Editar'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              foregroundColor: const Color(0xFF1D2939),
            ),
          ),

          const SizedBox(height: 12),

          // Botão Sair
          TextButton.icon(
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
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blueGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D2939),
            ),
          ),
        ],
      ),
    );
  }
}
