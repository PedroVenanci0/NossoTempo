import 'package:flutter/material.dart';
import '../models/config_model.dart';
import '../services/storage_service.dart';
import '../utils/cores_projeto.dart';
import 'calendario_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final StorageService _storageService = StorageService();
  final TextEditingController _senhaController = TextEditingController();
  
  String _usuarioSelecionado = 'Pedro'; // Pedro por padrão
  ConfigModel _config = ConfigModel();
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarConfigs();
  }

  Future<void> _carregarConfigs() async {
    final config = await _storageService.carregarConfig();
    setState(() {
      _config = config;
      _carregando = false;
      
      // Se já tiver uma sessão ativa (usuarioAtivo), direciona direto para o Calendário
      if (config.usuarioAtivo.isNotEmpty) {
        _irParaCalendario();
      }
    });
  }

  void _irParaCalendario() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const CalendarioScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _fazerLogin() async {
    setState(() {
      _erro = null;
    });

    final senhaDigitada = _senhaController.text;
    final senhaCorreta = _usuarioSelecionado == 'Pedro' 
        ? _config.senhaPedro 
        : _config.senhaMariaLuiza;

    if (senhaDigitada == senhaCorreta) {
      // Salva o usuário ativo na sessão
      final novaConfig = _config.copyWith(usuarioAtivo: _usuarioSelecionado);
      await _storageService.salvarConfig(novaConfig);
      _irParaCalendario();
    } else {
      setState(() {
        _erro = 'Senha incorreta. Tente novamente.';
      });
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
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: CoresProjeto.fundoCaderno,
              border: Border.all(color: CoresProjeto.bordaCinza, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: CoresProjeto.textoEscuro.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(5, 5),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabeçalho Estilo Caderno
                Center(
                  child: Text(
                    'CALENDARIO - NOSSOTEMPO',
                    style: CoresProjeto.estiloTitulo(24),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Planejamento & Sincronia',
                    style: CoresProjeto.estiloTextoMono(12, cor: CoresProjeto.textoClaro),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: CoresProjeto.bordaCinza, thickness: 1.0),
                const SizedBox(height: 24),

                // Seletor de Usuário
                Text(
                  'QUEM ESTÁ ENTRANDO?',
                  style: CoresProjeto.estiloTextoMono(10, bold: true, cor: CoresProjeto.textoClaro),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildOpcaoUsuario('Pedro', Icons.face),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildOpcaoUsuario('Maria Luiza', Icons.favorite_border),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Campo de Senha
                Text(
                  'DIGITE SUA SENHA',
                  style: CoresProjeto.estiloTextoMono(10, bold: true, cor: CoresProjeto.textoClaro),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  style: CoresProjeto.estiloTextoMono(14),
                  cursorColor: CoresProjeto.textoEscuro,
                  decoration: InputDecoration(
                    hintText: 'Digite sua senha',
                    hintStyle: CoresProjeto.estiloTextoMono(12, cor: CoresProjeto.textoClaro.withOpacity(0.6)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: CoresProjeto.bordaCinza, width: 1.0),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: CoresProjeto.destaqueAtivo, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _fazerLogin(),
                ),

                if (_erro != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _erro!,
                    style: CoresProjeto.estiloTextoCorpo(12, cor: Colors.redAccent, bold: true),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 32),

                // Botão Entrar
                InkWell(
                  onTap: _fazerLogin,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: CoresProjeto.destaqueAtivo,
                      border: Border.all(color: CoresProjeto.textoEscuro, width: 1.0),
                    ),
                    child: Center(
                      child: Text(
                        'ENTRAR NO CADERNO',
                        style: CoresProjeto.estiloTextoMono(13, bold: true, cor: CoresProjeto.destaqueTexto),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'feito com ♥ por vocês',
                    style: CoresProjeto.estiloTextoMono(10, cor: CoresProjeto.textoClaro),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpcaoUsuario(String nome, IconData icone) {
    final selecionado = _usuarioSelecionado == nome;
    return InkWell(
      onTap: () {
        setState(() {
          _usuarioSelecionado = nome;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selecionado ? CoresProjeto.destaqueAtivo : CoresProjeto.fundoCaderno,
          border: Border.all(
            color: selecionado ? CoresProjeto.textoEscuro : CoresProjeto.bordaCinza,
            width: 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icone,
              color: selecionado ? CoresProjeto.destaqueTexto : CoresProjeto.textoEscuro,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              nome.toUpperCase(),
              style: CoresProjeto.estiloTextoMono(
                12, 
                bold: selecionado, 
                cor: selecionado ? CoresProjeto.destaqueTexto : CoresProjeto.textoEscuro
              ),
            ),
          ],
        ),
      ),
    );
  }
}
