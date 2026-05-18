import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'utils/cores_projeto.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NossoCalendarioApp());
}

class NossoCalendarioApp extends StatelessWidget {
  const NossoCalendarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nosso Espaço - Planejamento',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: CoresProjeto.fundoCaderno,
        colorScheme: ColorScheme.fromSeed(
          seedColor: CoresProjeto.destaqueAtivo,
          background: CoresProjeto.fundoCaderno,
          primary: CoresProjeto.destaqueAtivo,
          surface: CoresProjeto.fundoCaderno,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
