class ConfigModel {
  final String githubToken;
  final String githubRepo; // Ex: 'pedro/CalendarioCompartilhado'
  final String ramo; // Ex: 'main' ou 'gh-pages'
  final String caminhoArquivo; // Ex: 'dados_calendario.csv'
  final String usuarioAtivo; // 'Pedro' ou 'Maria Luiza'
  final String senhaPedro; // Senha para o login do Pedro
  final String senhaMariaLuiza; // Senha para o login da Maria Luiza
  final String notasMes; // Campo de texto livre para as notas do mês

  ConfigModel({
    this.githubToken = '',
    this.githubRepo = '',
    this.ramo = 'main',
    this.caminhoArquivo = 'dados_calendario.csv',
    this.usuarioAtivo = '',
    this.senhaPedro = 'amareloazul',      // Senha padrão inicial Pedro
    this.senhaMariaLuiza = 'amareloazul',  // Senha padrão inicial Maria Luiza
    this.notasMes = '',
  });

  bool get estaConfiguradoGithub {
    return githubToken.isNotEmpty && githubRepo.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
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
      githubToken: json['githubToken'] ?? '',
      githubRepo: json['githubRepo'] ?? '',
      ramo: json['ramo'] ?? 'main',
      caminhoArquivo: json['caminhoArquivo'] ?? 'dados_calendario.csv',
      usuarioAtivo: json['usuarioAtivo'] ?? '',
      senhaPedro: json['senhaPedro'] ?? 'amareloazul',
      // Fallback para suportar migração transparente do cache antigo 'senhaNamorada'
      senhaMariaLuiza: json['senhaMariaLuiza'] ?? json['senhaNamorada'] ?? 'amareloazul',
      notasMes: json['notasMes'] ?? '',
    );
  }

  ConfigModel copyWith({
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
