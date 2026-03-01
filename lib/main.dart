import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/root/presentation/pages/root_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa a formatação de data para o português do Brasil
  await initializeDateFormatting('pt_BR', null);
  
  // Verifica se o token existe no Secure Storage
  final token = await TokenStorage().getToken();
  final bool isLoggedIn = token != null && token.isNotEmpty;

  runApp(Louvor4App(isLoggedIn: isLoggedIn));
}

class Louvor4App extends StatelessWidget {
  final bool isLoggedIn;
  
  const Louvor4App({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF0166FF);
    const textGrey = Color(0xFF4D4D4D);

    return MaterialApp(
      title: 'Louvor4',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Outfit',

        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          onPrimary: Colors.white,
        ),

        textTheme: const TextTheme(
          displayLarge: TextStyle(color: textGrey),
          displayMedium: TextStyle(color: textGrey),
          displaySmall: TextStyle(color: textGrey),
          headlineLarge: TextStyle(color: textGrey),
          headlineMedium: TextStyle(color: textGrey),
          headlineSmall: TextStyle(color: textGrey),
          titleLarge: TextStyle(color: textGrey),
          titleMedium: TextStyle(color: textGrey),
          titleSmall: TextStyle(color: textGrey),
          bodyLarge: TextStyle(color: textGrey),
          bodyMedium: TextStyle(color: textGrey),
          bodySmall: TextStyle(color: textGrey),
          labelLarge: TextStyle(color: textGrey),
        ),

        scaffoldBackgroundColor: Colors.white,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: primaryBlue,
        ),
      ),
      // Se estiver logado, vai direto para a RootPage
      home: isLoggedIn ? const RootPage() : const LoginPage(),
    );
  }
}
