import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/storage/token_storage.dart';
import 'core/ui/app_feedback.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/root/presentation/pages/root_page.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Inicializa a formatação de data
    await initializeDateFormatting('pt_BR', null);

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase não inicializado: $e');
    }

    // Tenta buscar o token com um tempo limite de 2 segundos para não travar o app
    final token = await TokenStorage().getAccessToken().timeout(
      const Duration(seconds: 2),
      onTimeout: () => null,
    );

    final bool isLoggedIn = token != null && token.isNotEmpty;

    if (isLoggedIn) {
      unawaited(PushNotificationService.instance.initialize());
    }

    runApp(Louvor4App(isLoggedIn: isLoggedIn));
  } catch (e) {
    // Se der qualquer erro na inicialização, abre na tela de login por segurança
    debugPrint('Erro na inicialização: $e');
    runApp(const Louvor4App(isLoggedIn: false));
  }
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
      navigatorKey: AppFeedback.navigatorKey,
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
      home: isLoggedIn ? const RootPage() : const LoginPage(),
    );
  }
}
