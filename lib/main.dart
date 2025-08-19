import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_check.dart'; // Importa nosso novo verificador

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ContabilidadeApp());
}

class ContabilidadeApp extends StatelessWidget {
  const ContabilidadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contabilidade Amiga',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // ▼▼▼ A ÚNICA MUDANÇA É AQUI ▼▼▼
      // A tela inicial agora é o nosso verificador, e não mais a tela de login
      home: const AuthCheck(),
    );
  }
}
