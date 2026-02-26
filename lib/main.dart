import 'package:flutter/material.dart';

import 'features/auth/presentation/pages/login_page.dart';

void main() {
  runApp(const Louvor4App());
}

class Louvor4App extends StatelessWidget {
  const Louvor4App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Louvor4',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Outfit',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0D7FF),
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginPage(),
    );
  }
}
