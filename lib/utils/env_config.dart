/// Credenciais injetadas em tempo de build via --dart-define.
/// Nunca ficam no código-fonte; são passadas pelo CI (GitHub Secrets).
///
/// Para rodar localmente com credenciais:
///   flutter run -d chrome --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_xxx
class EnvConfig {
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get estaConfigurado =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
