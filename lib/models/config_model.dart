class ConfigModel {
  // Supabase (novo backend)
  final String supabaseUrl;
  final String supabaseAnonKey;

  // GitHub (legado, mantido apenas para importar dados antigos)
  final String githubToken;
  final String githubRepo;
  final String ramo;
  final String caminhoArquivo;

  // Sessao / acesso
  final String usuarioAtivo;
  final String senhaPedro;
  final String senhaMariaLuiza;
  final String notasMes;

  ConfigModel({
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.githubToken = '',
    this.githubRepo = '',
    this.ramo = 'main',
    this.caminhoArquivo = 'dados_calendario.csv',
    this.usuarioAtivo = '',
    this.senhaPedro = 'amareloazul',
    this.senhaMariaLuiza = 'amareloazul',
    this.notasMes = '',
  });

  bool get estaConfiguradoSupabase {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }

  bool get estaConfiguradoGithub {
    return githubToken.isNotEmpty && githubRepo.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'supabaseUrl': supabaseUrl,
      'supabaseAnonKey': supabaseAnonKey,
      'githubToken': githubToken,
      'githubRepo': githubRepo,
      'ramo': ramo,
      'caminhoArquivo': caminhoArquivo,
      'usuarioAtivo': usuarioAtivo,
      'senhaPedro': senhaPedro,
      'senhaMariaLuiza': senhaMariaLuiza,
      'notasMes': notasMes,
    };
  }

  factory ConfigModel.fromJson(Map<String, dynamic> json) {
    return ConfigModel(
      supabaseUrl: json['supabaseUrl'] ?? '',
      supabaseAnonKey: json['supabaseAnonKey'] ?? '',
      githubToken: json['githubToken'] ?? '',
      githubRepo: json['githubRepo'] ?? '',
      ramo: json['ramo'] ?? 'main',
      caminhoArquivo: json['caminhoArquivo'] ?? 'dados_calendario.csv',
      usuarioAtivo: json['usuarioAtivo'] ?? '',
      senhaPedro: json['senhaPedro'] ?? 'amareloazul',
      senhaMariaLuiza: json['senhaMariaLuiza'] ?? json['senhaNamorada'] ?? 'amareloazul',
      notasMes: json['notasMes'] ?? '',
    );
  }

  ConfigModel copyWith({
    String? supabaseUrl,
    String? supabaseAnonKey,
    String? githubToken,
    String? githubRepo,
    String? ramo,
    String? caminhoArquivo,
    String? usuarioAtivo,
    String? senhaPedro,
    String? senhaMariaLuiza,
    String? notasMes,
  }) {
    return ConfigModel(
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
      supabaseAnonKey: supabaseAnonKey ?? this.supabaseAnonKey,
      githubToken: githubToken ?? this.githubToken,
      githubRepo: githubRepo ?? this.githubRepo,
      ramo: ramo ?? this.ramo,
      caminhoArquivo: caminhoArquivo ?? this.caminhoArquivo,
      usuarioAtivo: usuarioAtivo ?? this.usuarioAtivo,
      senhaPedro: senhaPedro ?? this.senhaPedro,
      senhaMariaLuiza: senhaMariaLuiza ?? this.senhaMariaLuiza,
      notasMes: notasMes ?? this.notasMes,
    );
  }
}
