import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/storage_service.dart';
import 'services/supabase_service.dart';
import 'utils/cores_projeto.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Supabase usando as credenciais persistidas (se houver).
  // Se nao houver, o usuario sera direcionado a tela de Config no primeiro uso.
  final config = await StorageService().carregarConfig();
  if (config.estaConfiguradoSupabase) {
    await SupabaseService.inicializar(config);
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
