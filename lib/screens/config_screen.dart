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
      senhaPedro: _senhaPedroController.text.trim(),
      senhaMariaLuiza: _senhaMariaLuizaController.text.trim(),
      tema: _temaSelecionado,
    );

    await _storageService.salvarConfig(novaConfig);

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

  // Retorna o ícone e a cor de preview de cada tema
  Map<String, dynamic> _obterInfoTema(String tema) {
    switch (tema) {
      case 'escuro':
        return {
          'icone': Icons.dark_mode_outlined,
          'cor': const Color(0xFF161618),
          'corTexto': const Color(0xFFE5E5EA),
          'nome': 'MODO ESCURO',
          'desc': 'Fundo preto com texto claro — elegante e suave para a noite.',
        };
      case 'starwars':
        return {
          'icone': Icons.rocket_launch_outlined,
          'cor': const Color(0xFF0A0A14),
          'corTexto': const Color(0xFFFFC500),
          'nome': 'STAR WARS',
          'desc': 'Que a Força esteja com vocês! Amarelo galáctico no fundo estelar.',
        };
      case 'abelha':
        return {
          'icone': Icons.emoji_nature_outlined,
          'cor': const Color(0xFFFFF9E0),
          'corTexto': const Color(0xFF8B6914),
          'nome': 'ABELHA 🐝',
          'desc': 'Doce como mel! Tons de amarelo e preto com ícones de abelha.',
        };
      default:
        return {
          'icone': Icons.wb_sunny_outlined,
          'cor': const Color(0xFFFAF8F5),
          'corTexto': const Color(0xFF4A4944),
          'nome': 'PADRÃO (CREME)',
          'desc': 'O caderno clássico — tons suaves de creme e cinza.',
        };
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
                  // ============== SECAO SELECAO DE TEMA ==============
                  _buildCabecalhoSecao('TEMA DO APLICATIVO', Icons.palette_outlined),
                  const SizedBox(height: 8),
                  Text(
                    'Escolha o estilo visual do seu caderno.',
                    style: CoresProjeto.estiloTextoCorpo(12, cor: CoresProjeto.textoClaro),
                  ),
                  const SizedBox(height: 16),

                  // Cards visuais de tema
                  _buildCardTema('padrao'),
                  const SizedBox(height: 10),
                  _buildCardTema('escuro'),
                  const SizedBox(height: 10),
                  _buildCardTema('starwars'),
                  const SizedBox(height: 10),
                  _buildCardTema('abelha'),

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

  Widget _buildCardTema(String tema) {
    final info = _obterInfoTema(tema);
    final selecionado = _temaSelecionado == tema;

    return InkWell(
      onTap: () {
        setState(() {
          _temaSelecionado = tema;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: info['cor'] as Color,
          border: Border.all(
            color: selecionado
                ? (info['corTexto'] as Color)
                : CoresProjeto.bordaCinza,
            width: selecionado ? 2.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Ícone do tema
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (info['corTexto'] as Color).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                info['icone'] as IconData,
                color: info['corTexto'] as Color,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            // Textos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info['nome'] as String,
                    style: CoresProjeto.estiloTextoMono(
                      12,
                      bold: true,
                      cor: info['corTexto'] as Color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info['desc'] as String,
                    style: CoresProjeto.estiloTextoCorpo(
                      11,
                      cor: (info['corTexto'] as Color).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Indicador de selecionado
            if (selecionado)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: info['corTexto'] as Color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: info['cor'] as Color,
                  size: 16,
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (info['corTexto'] as Color).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
              ),
          ],
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
