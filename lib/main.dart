import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'services/storage_service.dart';
import 'services/supabase_service.dart';
import 'utils/cores_projeto.dart';
import 'utils/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = StorageService();
  final config = await storageService.carregarConfig();

  // Usa credenciais do env (injetadas pelo CI via --dart-define).
  // Se não houver env (ex: dev local), tenta usar o que o usuário salvou na config.
  final supabaseUrl = EnvConfig.supabaseUrl.isNotEmpty
      ? EnvConfig.supabaseUrl
      : config.supabaseUrl;
  final supabaseKey = EnvConfig.supabaseAnonKey.isNotEmpty
      ? EnvConfig.supabaseAnonKey
      : config.supabaseAnonKey;

  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    final configComEnv = config.copyWith(
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseKey,
    );
    await SupabaseService.inicializar(configComEnv);

    // Persiste as credenciais do env no localStorage para que o resto do app
    // as encontre via StorageService (sem nunca exibi-las na tela).
    if (EnvConfig.estaConfigurado) {
      await storageService.salvarConfig(configComEnv);
    }
  }

  runApp(const NossoCalendarioApp());
}

class NossoCalendarioApp extends StatelessWidget {
  const NossoCalendarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendario - NossoTempo',
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

