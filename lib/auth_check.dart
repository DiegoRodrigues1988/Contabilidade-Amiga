import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:contabilidade_amiga/login_screen.dart';
// ▼▼▼ MUDANÇA AQUI ▼▼▼
import 'package:contabilidade_amiga/main_screen.dart';

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // ▼▼▼ MUDANÇA AQUI ▼▼▼
          // Agora o usuário logado vai para a MainScreen, que tem a barra de navegação
          return const MainScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
