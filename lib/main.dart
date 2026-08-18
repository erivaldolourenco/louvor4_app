import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/navigation/app_route_observer.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_controller.dart';
import 'core/ui/app_feedback.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/notifications/presentation/pages/avisos_page.dart';
import 'features/root/presentation/pages/root_page.dart';
import 'features/song_categories/presentation/pages/song_categories_page.dart';
import 'features/user_profile/apresentation/pages/profile_page.dart';
import 'features/user_profile/apresentation/pages/user_unavailability_page.dart';

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
    await AppThemeController.instance.load();

    final bool isLoggedIn = token != null && token.isNotEmpty;

    if (isLoggedIn) {
      try {
        unawaited(PushNotificationService.instance.initialize());
      } catch (e) {
        debugPrint('PushNotificationService não inicializado: $e');
      }
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
    return AnimatedBuilder(
      animation: AppThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Louvor4',
          debugShowCheckedModeBanner: false,
          navigatorKey: AppFeedback.navigatorKey,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: AppThemeController.instance.themeMode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          routes: {
            LoginPage.routeName: (_) => const LoginPage(),
            RootPage.routeName: (_) => const RootPage(),
            ProfilePage.routeName: (_) => const ProfilePage(),
            AvisosPage.routeName: (_) => const StandaloneAvisosPage(),
            UserUnavailabilityPage.routeName: (_) =>
                const UserUnavailabilityPage(),
            SongCategoriesPage.routeName: (_) => const SongCategoriesPage(),
          },
          navigatorObservers: [appRouteObserver],
          home: isLoggedIn ? const RootPage() : const LoginPage(),
        );
      },
    );
  }
}
