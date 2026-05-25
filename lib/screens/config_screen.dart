import 'package:flutter/material.dart';
import '../models/config_model.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../utils/cores_projeto.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final StorageService _storageService = StorageService();
  final SupabaseService _supabaseService = SupabaseService();

  final _formKey = GlobalKey<FormState>();

  // Supabase
  final _supabaseUrlController = TextEditingController();
  final _supabaseKeyController = TextEditingController();

  // Senhas
  final _senhaPedroController = TextEditingController();
  final _senhaMariaLuizaController = TextEditingController();

  // Tema selecionado
  String _temaSelecionado = 'padrao';

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
      _supabaseUrlController.text = config.supabaseUrl;
      _supabaseKeyController.text = config.supabaseAnonKey;
      _senhaPedroController.text = config.senhaPedro;
      _senhaMariaLuizaController.text = config.senhaMariaLuiza;
      _temaSelecionado = config.tema;
      _carregando = false;
    });
  }

  Future<void> _salvarConfigs() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _salvando = true;
    });

    final novaConfig = _config.copyWith(
      supabaseUrl: _supabaseUrlController.text.trim(),
      supabaseAnonKey: _supabaseKeyController.text.trim(),
      senhaPedro: _senhaPedroController.text.trim(),
      senhaMariaLuiza: _senhaMariaLuizaController.text.trim(),
      tema: _temaSelecionado,
    );

    await _storageService.salvarConfig(novaConfig);

    // Inicializa Supabase com as novas credenciais (se ainda nao foi).
    if (novaConfig.estaConfiguradoSupabase) {
      await SupabaseService.inicializar(novaConfig);
    }

    if (!mounted) return;

    setState(() {
      _config = novaConfig;
      _salvando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: CoresProjeto.destaqueAtivo,
        content: Text(
          'Configuracoes salvas!',
          style: CoresProjeto.estiloTextoMono(12, cor: CoresProjeto.destaqueTexto),
        ),
      ),
    );

    Navigator.of(context).pop(true);
  }

  Future<void> _logout() async {
    final novaConfig = _config.copyWith(usuarioAtivo: '');
    await _storageService.salvarConfig(novaConfig);
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return Scaffold(
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
          icon: Icon(Icons.arrow_back, color: CoresProjeto.textoEscuro),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'CONFIGURACOES',
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
                  // ============== SECAO SUPABASE ==============
                  _buildCabecalhoSecao('BANCO DE DADOS (SUPABASE)', Icons.storage_outlined),
                  const SizedBox(height: 8),
                  Text(
                    'Cole a URL e a Anon Key do projeto do Supabase. Sem isso, o app roda apenas no cache local deste navegador.',
                    style: CoresProjeto.estiloTextoCorpo(12, cor: CoresProjeto.textoClaro),
                  ),
                  const SizedBox(height: 24),

                  _buildInputLabel('SUPABASE PROJECT URL'),
                  TextFormField(
                    controller: _supabaseUrlController,
                    style: CoresProjeto.estiloTextoMono(13),
                    cursorColor: CoresProjeto.textoEscuro,
                    decoration: _buildInputDecoration('https://xxx.supabase.co'),
                  ),
                  const SizedBox(height: 16),

                  _buildInputLabel('SUPABASE ANON / PUBLISHABLE KEY'),
                  TextFormField(
                    controller: _supabaseKeyController,
                    style: CoresProjeto.estiloTextoMono(13),
                    cursorColor: CoresProjeto.textoEscuro,
                    decoration: _buildInputDecoration('sb_publishable_... ou eyJ...'),
                  ),

                  const SizedBox(height: 32),
                  Divider(color: CoresProjeto.bordaCinza, thickness: 1.0),
                  const SizedBox(height: 24),

                  // ============== SECAO SELECAO DE TEMA ==============
                  _buildCabecalhoSecao('TEMA DO APLICATIVO', Icons.palette_outlined),
                  const SizedBox(height: 8),
                  Text(
                    'Escolha o estilo visual do seu caderno.',
                    style: CoresProjeto.estiloTextoCorpo(12, cor: CoresProjeto.textoClaro),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: CoresProjeto.bordaCinza, width: 1.0),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _temaSelecionado,
                        dropdownColor: CoresProjeto.fundoCaderno,
                        style: CoresProjeto.estiloTextoMono(13, cor: CoresProjeto.textoEscuro),
                        iconEnabledColor: CoresProjeto.textoEscuro,
                        onChanged: (String? novoTema) {
                          if (novoTema != null) {
                            setState(() {
                              _temaSelecionado = novoTema;
                            });
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'padrao',
                            child: Text('PADRÃO (CREME)'),
                          ),
                          DropdownMenuItem(
                            value: 'escuro',
                            child: Text('ESCURO (PRETO)'),
                          ),
                          DropdownMenuItem(
                            value: 'starwars',
                            child: Text('STAR WARS'),
                          ),
                          DropdownMenuItem(
                            value: 'abelha',
                            child: Text('ABELHA 🐝'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  Divider(color: CoresProjeto.bordaCinza, thickness: 1.0),
                  const SizedBox(height: 24),

                  // ============== SECAO SENHAS ==============
                  _buildCabecalhoSecao('SENHAS DE ACESSO LOCAL', Icons.lock_outline),
                  const SizedBox(height: 24),

                  Row(
                    children: [
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
                            ? SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(color: CoresProjeto.destaqueTexto, strokeWidth: 2),
                              )
                            : Text(
                                'SALVAR CONFIGURACOES',
                                style: CoresProjeto.estiloTextoMono(13, bold: true, cor: CoresProjeto.destaqueTexto),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

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
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: CoresProjeto.bordaCinza, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
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
