import 'package:flutter/material.dart';
import '../models/config_model.dart';
import '../services/storage_service.dart';
import '../utils/cores_projeto.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final StorageService _storageService = StorageService();
  
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _repoController = TextEditingController();
  final _ramoController = TextEditingController();
  final _arquivoController = TextEditingController();
  final _senhaPedroController = TextEditingController();
  final _senhaMariaLuizaController = TextEditingController();

  ConfigModel _config = ConfigModel();
  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregarConfigs();
  }

  Future<void> _carregarConfigs() async {
    final config = await _storageService.carregarConfig();
    setState(() {
      _config = config;
      _tokenController.text = config.githubToken;
      _repoController.text = config.githubRepo;
      _ramoController.text = config.ramo;
      _arquivoController.text = config.caminhoArquivo;
      _senhaPedroController.text = config.senhaPedro;
      _senhaMariaLuizaController.text = config.senhaMariaLuiza;
      _carregando = false;
    });
  }

  Future<void> _salvarConfigs() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
    });

    final novaConfig = _config.copyWith(
      githubToken: _tokenController.text.trim(),
      githubRepo: _repoController.text.trim(),
      ramo: _ramoController.text.trim(),
      caminhoArquivo: _arquivoController.text.trim(),
      senhaPedro: _senhaPedroController.text.trim(),
      senhaMariaLuiza: _senhaMariaLuizaController.text.trim(),
    );

    await _storageService.salvarConfig(novaConfig);

    if (!mounted) return;

    setState(() {
      _salvando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: CoresProjeto.destaqueAtivo,
        content: Text(
          'Configurações salvas localmente!',
          style: CoresProjeto.estiloTextoMono(12, cor: CoresProjeto.destaqueTexto),
        ),
      ),
    );

    Navigator.of(context).pop(true); // Retorna true informando que mudou configs
  }

  Future<void> _logout() async {
    // Apenas limpa o usuário ativo da sessão local para voltar para a tela de login
    final novaConfig = _config.copyWith(usuarioAtivo: '');
    await _storageService.salvarConfig(novaConfig);
    
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        backgroundColor: CoresProjeto.fundoCaderno,
        body: Center(
          child: CircularProgressIndicator(color: CoresProjeto.destaqueAtivo),
        ),
      );
    }

    return Scaffold(
      backgroundColor: CoresProjeto.fundoCaderno,
      appBar: AppBar(
        backgroundColor: CoresProjeto.fundoCaderno,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CoresProjeto.textoEscuro),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'CONFIGURAÇÕES',
          style: CoresProjeto.estiloTitulo(16),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: CoresProjeto.bordaCinza, height: 1),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: CoresProjeto.fundoCaderno,
              border: Border.all(color: CoresProjeto.bordaCinza, width: 1.0),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabeçalho da Seção GitHub
                  _buildCabecalhoSecao('SINCRONIZAÇÃO GITHUB (OPCIONAL)', Icons.cloud_queue),
                  const SizedBox(height: 8),
                  Text(
                    'Preencha esses campos para que o app salve e leia os dados no GitHub. Se deixados em branco, o app funcionará apenas localmente neste navegador.',
                    style: CoresProjeto.estiloTextoCorpo(12, cor: CoresProjeto.textoClaro),
                  ),
                  const SizedBox(height: 24),

                  // Token
                  _buildInputLabel('GITHUB PERSONAL ACCESS TOKEN (PAT)'),
                  TextFormField(
                    controller: _tokenController,
                    style: CoresProjeto.estiloTextoMono(13),
                    cursorColor: CoresProjeto.textoEscuro,
                    decoration: _buildInputDecoration('ghp_xxxxxxxxxxxxxxxxxxxxxx'),
                  ),
                  const SizedBox(height: 16),

                  // Repositório
                  _buildInputLabel('REPOSITÓRIO (DONO/NOME)'),
                  TextFormField(
                    controller: _repoController,
                    style: CoresProjeto.estiloTextoMono(13),
                    cursorColor: CoresProjeto.textoEscuro,
                    decoration: _buildInputDecoration('usuario/repositorio'),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && !v.contains('/')) {
                        return 'Formato deve ser dono/nome (ex: pedro/nosso-calendario)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      // Branch
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInputLabel('BRANCH (RAMO)'),
                            TextFormField(
                              controller: _ramoController,
                              style: CoresProjeto.estiloTextoMono(13),
                              cursorColor: CoresProjeto.textoEscuro,
                              decoration: _buildInputDecoration('main'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Caminho do arquivo
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInputLabel('NOME DO ARQUIVO CSV'),
                            TextFormField(
                              controller: _arquivoController,
                              style: CoresProjeto.estiloTextoMono(13),
                              cursorColor: CoresProjeto.textoEscuro,
                              decoration: _buildInputDecoration('dados_calendario.csv'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: CoresProjeto.bordaCinza, thickness: 1.0),
                  const SizedBox(height: 24),

                  // Cabeçalho da Seção Acesso / Perfis
                  _buildCabecalhoSecao('SENHAS DE ACESSO LOCAL', Icons.lock_outline),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      // Senha Pedro
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInputLabel('SENHA DO PEDRO'),
                            TextFormField(
                              controller: _senhaPedroController,
                              obscureText: true,
                              style: CoresProjeto.estiloTextoMono(13),
                              cursorColor: CoresProjeto.textoEscuro,
                              decoration: _buildInputDecoration('******'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Senha Maria Luiza
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildInputLabel('SENHA DA MARIA LUIZA'),
                            TextFormField(
                              controller: _senhaMariaLuizaController,
                              obscureText: true,
                              style: CoresProjeto.estiloTextoMono(13),
                              cursorColor: CoresProjeto.textoEscuro,
                              decoration: _buildInputDecoration('******'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Botão Salvar
                  InkWell(
                    onTap: _salvando ? null : _salvarConfigs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: CoresProjeto.destaqueAtivo,
                        border: Border.all(color: CoresProjeto.textoEscuro, width: 1.0),
                      ),
                      child: Center(
                        child: _salvando
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(color: CoresProjeto.destaqueTexto, strokeWidth: 2),
                              )
                            : Text(
                                'SALVAR CONFIGURAÇÕES',
                                style: CoresProjeto.estiloTextoMono(13, bold: true, cor: CoresProjeto.destaqueTexto),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botão Logout (Desconectar usuário ativo)
                  OutlinedButton(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent, width: 1.0),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.redAccent,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: Text(
                      'DESLOGAR DO PERFIL',
                      style: CoresProjeto.estiloTextoMono(12, bold: true, cor: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCabecalhoSecao(String titulo, IconData icone) {
    return Row(
      children: [
        Icon(icone, color: CoresProjeto.textoEscuro, size: 20),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: CoresProjeto.estiloTextoMono(12, bold: true),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        texto,
        style: CoresProjeto.estiloTextoMono(10, bold: true, cor: CoresProjeto.textoClaro),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: CoresProjeto.estiloTextoMono(12, cor: CoresProjeto.textoClaro.withOpacity(0.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: CoresProjeto.bordaCinza, width: 1.0),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: CoresProjeto.destaqueAtivo, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
