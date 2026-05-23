import 'dart:async';
import 'package:flutter/material.dart';
import '../models/config_model.dart';
import '../models/evento_model.dart';
import '../services/github_service.dart';
import '../services/storage_service.dart';
import '../utils/cores_projeto.dart';
import '../widgets/grade_milimetrada.dart';
import 'config_screen.dart';
import 'login_screen.dart';

class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  final StorageService _storageService = StorageService();
  final GithubService _githubService = GithubService();

  ConfigModel _config = ConfigModel();
  List<EventoModel> _eventos = [];
  
  bool _carregando = true;
  bool _sincronizando = false;
  bool _sincronizandoSilencioso = false;
  String _mensagemSinc = '';
  
  Timer? _timerSincronizacao;
  
  DateTime _dataSelecionada = DateTime.now();
  final List<String> _mesesAbreviados = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
  ];
  
  final List<String> _diasSemana = ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB', 'DOM'];

  // Controladores do painel esquerdo
  final TextEditingController _notasController = TextEditingController();
  final TextEditingController _novaTarefaController = TextEditingController();
  String _tipoNovaTarefa = 'Privado';
  String _tipoNotaAtivo = 'Compartilhado';

  @override
  void initState() {
    super.initState();
    _inicializarDados();
    
    // Configura sincronização automática periódica a cada 30 segundos
    _timerSincronizacao = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_config.estaConfiguradoGithub && !_sincronizando && !_sincronizandoSilencioso) {
        _sincronizarComGithubSilencioso();
      }
    });
  }

  @override
  void dispose() {
    _timerSincronizacao?.cancel();
    _notasController.dispose();
    _novaTarefaController.dispose();
    super.dispose();
  }

  Future<void> _inicializarDados() async {
    // 1. Carrega configurações locais
    final config = await _storageService.carregarConfig();
    
    setState(() {
      _config = config;
    });

    // 2. Carrega eventos do cache local inicialmente para abrir rápido
    final eventosLocais = await _storageService.carregarEventosLocais();
    setState(() {
      _eventos = eventosLocais;
      _carregando = false;
    });

    _atualizarNotasController();

    // 3. Sincroniza com o GitHub se configurado
    if (_config.estaConfiguradoGithub) {
      _sincronizarComGithub();
    }
  }

  Future<void> _sincronizarComGithub() async {
    if (_sincronizando) return;

    setState(() {
      _sincronizando = true;
      _mensagemSinc = 'Sincronizando...';
    });

    final resultado = await _githubService.carregarDoGithub(_config);

    if (!mounted) return;

    if (resultado['sucesso'] == true) {
      final List<EventoModel> eventosGithub = resultado['eventos'];
      
      // Salva no cache local para uso futuro
      await _storageService.salvarEventosLocais(eventosGithub);

      setState(() {
        _eventos = eventosGithub;
        _sincronizando = false;
        _mensagemSinc = resultado['mensagem'];
      });
      
      _atualizarNotasController();
    } else {
      setState(() {
        _sincronizando = false;
        _mensagemSinc = resultado['mensagem'];
      });
      
      // Exibe erro amigável na barra inferior
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Offline: usando cache local. (${resultado['mensagem']})',
            style: CoresProjeto.estiloTextoMono(12),
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    }
  }

  Future<void> _salvarDadosGerais() async {
    // Salva localmente primeiro
    await _storageService.salvarEventosLocais(_eventos);
    
    // Se o GitHub estiver configurado, envia para lá
    if (_config.estaConfiguradoGithub) {
      setState(() {
        _sincronizando = true;
        _mensagemSinc = 'Enviando ao GitHub...';
      });

      final resultado = await _githubService.salvarNoGithub(_config, _eventos);

      if (!mounted) return;

      // Se houve mesclagem com mudancas remotas, atualiza o estado local
      if (resultado['sucesso'] == true && resultado['eventosMesclados'] != null) {
        final List<EventoModel> mesclados = resultado['eventosMesclados'];
        if (mesclados.length != _eventos.length) {
          setState(() {
            _eventos = mesclados;
          });
          await _storageService.salvarEventosLocais(mesclados);
          _atualizarNotasController();
        }
      }

      setState(() {
        _sincronizando = false;
        _mensagemSinc = resultado['mensagem'];
      });

      if (!resultado['sucesso']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['mensagem'], style: CoresProjeto.estiloTextoMono(12)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Obtém o texto da nota do mês/ano selecionados
  String _obterNotasDoMes() {
    final eventoNota = _eventos.firstWhere(
      (e) => e.categoria == 'Nota' &&
             e.tipo == _tipoNotaAtivo &&
             (_tipoNotaAtivo == 'Compartilhado' || e.usuario == _config.usuarioAtivo) &&
             e.data.year == _dataSelecionada.year &&
             e.data.month == _dataSelecionada.month,
      orElse: () => EventoModel(
        id: '',
        usuario: '',
        data: DateTime.now(),
        titulo: '',
        descricao: '',
        tipo: _tipoNotaAtivo,
        categoria: 'Nota',
        corHex: '',
      ),
    );
    return eventoNota.titulo;
  }

  // Atualiza o TextEditingController de notas
  void _atualizarNotasController() {
    final notas = _obterNotasDoMes();
    if (_notasController.text != notas) {
      _notasController.text = notas;
    }
  }

  // Notas do mês: salva no CSV e sincroniza com o GitHub
  Future<void> _salvarNotas() async {
    final novasNotas = _notasController.text.trim();
    final notasAntigas = _obterNotasDoMes();

    if (novasNotas == notasAntigas) return;
    
    // Procura se já existe uma nota para o mês/ano
    final index = _eventos.indexWhere(
      (e) => e.categoria == 'Nota' &&
             e.tipo == _tipoNotaAtivo &&
             (_tipoNotaAtivo == 'Compartilhado' || e.usuario == _config.usuarioAtivo) &&
             e.data.year == _dataSelecionada.year &&
             e.data.month == _dataSelecionada.month,
    );

    if (index != -1) {
      if (novasNotas.isEmpty) {
        setState(() {
          _eventos.removeAt(index);
        });
      } else {
        setState(() {
          _eventos[index] = _eventos[index].copyWith(
            titulo: novasNotas,
            usuario: _config.usuarioAtivo,
          );
        });
      }
      await _salvarDadosGerais();
    } else if (novasNotas.isNotEmpty) {
      final idNota = _tipoNotaAtivo == 'Compartilhado'
          ? 'nota_compartilhada_${_dataSelecionada.year}_${_dataSelecionada.month}'
          : 'nota_${_config.usuarioAtivo}_${_dataSelecionada.year}_${_dataSelecionada.month}';

      final novaNota = EventoModel(
        id: idNota,
        usuario: _config.usuarioAtivo,
        data: DateTime(_dataSelecionada.year, _dataSelecionada.month, 1),
        titulo: novasNotas,
        descricao: '',
        tipo: _tipoNotaAtivo,
        categoria: 'Nota',
        corHex: '#EAEAEA',
      );
      setState(() {
        _eventos.add(novaNota);
      });
      await _salvarDadosGerais();
    }
  }

  // Sincronização periódica em segundo plano
  Future<void> _sincronizarComGithubSilencioso() async {
    if (_sincronizando || _sincronizandoSilencioso) return;

    setState(() {
      _sincronizandoSilencioso = true;
    });

    final resultado = await _githubService.carregarDoGithub(_config);

    if (!mounted) return;

    if (resultado['sucesso'] == true) {
      final List<EventoModel> eventosGithub = resultado['eventos'];
      
      // Compara se houve alguma mudança nos eventos salvos
      bool mudou = _eventos.length != eventosGithub.length;
      if (!mudou) {
        for (var evG in eventosGithub) {
          final evL = _eventos.firstWhere(
            (e) => e.id == evG.id,
            orElse: () => EventoModel(
              id: '',
              usuario: '',
              data: DateTime.now(),
              titulo: '',
              descricao: '',
              tipo: '',
              categoria: '',
              corHex: '',
            ),
          );
          if (evL.id.isEmpty || 
              evL.titulo != evG.titulo || 
              evL.descricao != evG.descricao || 
              evL.concluido != evG.concluido ||
              evL.categoria != evG.categoria ||
              evL.tipo != evG.tipo ||
              evL.data != evG.data ||
              evL.horaInicio != evG.horaInicio ||
              evL.horaFim != evG.horaFim) {
            mudou = true;
            break;
          }
        }
      }

      if (mudou) {
        await _storageService.salvarEventosLocais(eventosGithub);
        setState(() {
          _eventos = eventosGithub;
          _mensagemSinc = 'Sincronizado';
        });
        
        // Só atualiza o texto se o usuário não estiver focado digitando
        final focus = FocusScope.of(context);
        if (!focus.hasFocus) {
          _atualizarNotasController();
        }
      }
    }

    setState(() {
      _sincronizandoSilencioso = false;
    });
  }

  // --- Lógica de Geração do Calendário ---
  
  int _obterDiasNoMes(int ano, int mes) {
    return DateTime(ano, mes + 1, 0).day;
  }

  List<DateTime?> _gerarDiasGrade() {
    final primeiroDiaMes = DateTime(_dataSelecionada.year, _dataSelecionada.month, 1);
    
    // weekday no Dart: 1 = Segunda, 7 = Domingo.
    // Se o primeiro dia cai numa Quarta (3), precisamos de 2 dias em branco antes (Segunda e Terça)
    final diasEmBrancoAntes = primeiroDiaMes.weekday - 1;
    final totalDiasNoMes = _obterDiasNoMes(_dataSelecionada.year, _dataSelecionada.month);
    
    List<DateTime?> dias = [];
    
    // Preenche os dias vazios no início da grade
    for (int i = 0; i < diasEmBrancoAntes; i++) {
      dias.add(null);
    }
    
    // Preenche os dias reais do mês
    for (int i = 1; i <= totalDiasNoMes; i++) {
      dias.add(DateTime(_dataSelecionada.year, _dataSelecionada.month, i));
    }
    
    // Completa a grade para ter 35 (5 semanas) ou 42 (6 semanas) células
    final totalCelulas = dias.length <= 35 ? 35 : 42;
    while (dias.length < totalCelulas) {
      dias.add(null);
    }
    
    return dias;
  }

  // --- Operações de Eventos ---

  // Filtra eventos do dia que o usuário logado pode ver
  List<EventoModel> _obterEventosDoDia(DateTime data) {
    final evs = _eventos.where((e) {
      // Ignora tarefas rápidas (que têm a categoria 'Tarefa') na exibição do grid central
      if (e.categoria == 'Tarefa') return false;

      final mesmaData = e.data.year == data.year && e.data.month == data.month && e.data.day == data.day;
      if (!mesmaData) return false;

      // Pedro vê os seus privados + compartilhados
      // Namorada vê os dela privados + compartilhados
      if (e.tipo == 'Compartilhado') return true;
      return e.usuario == _config.usuarioAtivo;
    }).toList();

    evs.sort((a, b) {
      if (a.horaInicio != null && b.horaInicio == null) return -1;
      if (a.horaInicio == null && b.horaInicio != null) return 1;
      if (a.horaInicio != null && b.horaInicio != null) {
        return a.horaInicio!.compareTo(b.horaInicio!);
      }
      return 0;
    });

    return evs;
  }

  // Filtra as tarefas do mês selecionado
  List<EventoModel> _obterTarefasDoMes() {
    return _eventos.where((e) {
      final mesmaData = e.categoria == 'Tarefa' &&
             e.data.year == _dataSelecionada.year &&
             e.data.month == _dataSelecionada.month;
      if (!mesmaData) return false;

      // Retorna tarefas compartilhadas OU privadas que pertencem ao usuário ativo
      return e.tipo == 'Compartilhado' || e.usuario == _config.usuarioAtivo;
    }).toList();
  }

  Future<void> _adicionarOuEditarEvento(EventoModel? eventoExistente, {DateTime? dataInicial}) async {
    final formKey = GlobalKey<FormState>();
    final tituloCtrl = TextEditingController(text: eventoExistente?.titulo ?? '');
    final descCtrl = TextEditingController(text: eventoExistente?.descricao ?? '');
    
    DateTime dataSel = eventoExistente?.data ?? dataInicial ?? DateTime.now();
    String tipoSel = eventoExistente?.tipo ?? 'Compartilhado';
    String catSel = eventoExistente?.categoria ?? 'Encontro';
    String? horaInicioSel = eventoExistente?.horaInicio;
    String? horaFimSel = eventoExistente?.horaFim;
    
    final categoriasDisp = ['Encontro', 'Estudo', 'Trabalho', 'Viagem', 'Hobby', 'Especial', 'Outros'];
    final tiposDisp = ['Compartilhado', 'Privado'];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: CoresProjeto.fundoCaderno,
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: CoresProjeto.bordaCinza, width: 1.0),
              ),
              title: Text(
                eventoExistente == null ? 'CRIAR COMPROMISSO' : 'EDITAR COMPROMISSO',
                style: CoresProjeto.estiloTitulo(14),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Título
                      Text(
                        'TÍTULO',
                        style: CoresProjeto.estiloTextoMono(9, bold: true, cor: CoresProjeto.textoClaro),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: tituloCtrl,
                        style: CoresProjeto.estiloTextoMono(12),
                        cursorColor: CoresProjeto.textoEscuro,
                        decoration: _buildModalInputDecoration('Ex: Jantar de Namoro ou Estudo de IA'),
                        validator: (v) => v == null || v.isEmpty ? 'Insira um título' : null,
                      ),
                      const SizedBox(height: 12),

                      // Descrição
                      Text(
                        'DESCRIÇÃO / DETALHES',
                        style: CoresProjeto.estiloTextoMono(9, bold: true, cor: CoresProjeto.textoClaro),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: descCtrl,
                        style: CoresProjeto.estiloTextoMono(12),
                        cursorColor: CoresProjeto.textoEscuro,
                        maxLines: 2,
                        decoration: _buildModalInputDecoration('Mais detalhes sobre o programa...'),
                      ),
                      const SizedBox(height: 12),

                      // Data Selecionada
                      Text(
                        'DATA',
                        style: CoresProjeto.estiloTextoMono(9, bold: true, cor: CoresProjeto.textoClaro),
                      ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () async {
                          final dataPick = await showDatePicker(
                            context: context,
                            initialDate: dataSel,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: CoresProjeto.destaqueAtivo,
                                    onPrimary: CoresProjeto.destaqueTexto,
                                    onSurface: CoresProjeto.textoEscuro,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (dataPick != null) {
                            setDialogState(() {
                              dataSel = dataPick;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: CoresProjeto.bordaCinza, width: 1.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${dataSel.day.toString().padLeft(2, '0')}/${dataSel.month.toString().padLeft(2, '0')}/${dataSel.year}',
                                style: CoresProjeto.estiloTextoMono(12),
                              ),
                              const Icon(Icons.calendar_month, color: CoresProjeto.textoEscuro, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Horários (Início e Fim)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'INÍCIO',
                                  style: CoresProjeto.estiloTextoMono(9, bold: true, cor: CoresProjeto.textoClaro),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () async {
                                    final initialTime = horaInicioSel != null
                                        ? TimeOfDay(
                                            hour: int.parse(horaInicioSel!.split(':')[0]),
                                            minute: int.parse(horaInicioSel!.split(':')[1]),
                                          )
                                        : const TimeOfDay(hour: 9, minute: 0);
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: initialTime,
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: const ColorScheme.light(
                                              primary: CoresProjeto.destaqueAtivo,
                                              onPrimary: CoresProjeto.destaqueTexto,
                                              onSurface: CoresProjeto.textoEscuro,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (time != null) {
                                      setDialogState(() {
                                        horaInicioSel = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: CoresProjeto.bordaCinza, width: 1.0),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          horaInicioSel ?? '--:--',
                                          style: CoresProjeto.estiloTextoMono(12),
                                        ),
                                        if (horaInicioSel != null)
                                          GestureDetector(
                                            onTap: () {
                                              setDialogState(() {
                                                horaInicioSel = null;
                                                horaFimSel = null;
                                              });
                                            },
                                            child: const Icon(Icons.clear, color: Colors.redAccent, size: 14),
                                          )
                                        else
                                          const Icon(Icons.access_time, color: CoresProjeto.textoEscuro, size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'FIM',
                                  style: CoresProjeto.estiloTextoMono(9, bold: true, cor: CoresProjeto.textoClaro),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: horaInicioSel == null
                                      ? null
                                      : () async {
                                          final initialTime = horaFimSel != null
                                              ? TimeOfDay(
                                                  hour: int.parse(horaFimSel!.split(':')[0]),
                                                  minute: int.parse(horaFimSel!.split(':')[1]),
                                                )
                                              : TimeOfDay(
                                                  hour: (int.parse(horaInicioSel!.split(':')[0]) + 1) % 24,
                                                  minute: int.parse(horaInicioSel!.split(':')[1]),
                                                );
                                          final time = await showTimePicker(
                                            context: context,
                                            initialTime: initialTime,
                                            builder: (context, child) {
                                              return Theme(
                                                data: Theme.of(context).copyWith(
                                                  colorScheme: const ColorScheme.light(
                                                    primary: CoresProjeto.destaqueAtivo,
                                                    onPrimary: CoresProjeto.destaqueTexto,
                                                    onSurface: CoresProjeto.textoEscuro,
                                                  ),
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );
                                          if (time != null) {
                                            setDialogState(() {
                                              horaFimSel = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                            });
                                          }
                                        },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: horaInicioSel == null ? Colors.black.withOpacity(0.03) : Colors.transparent,
                                      border: Border.all(
                                        color: horaInicioSel == null ? CoresProjeto.bordaCinza.withOpacity(0.5) : CoresProjeto.bordaCinza,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          horaFimSel ?? '--:--',
                                          style: CoresProjeto.estiloTextoMono(
                                            12,
                                            cor: horaInicioSel == null ? CoresProjeto.textoClaro.withOpacity(0.5) : CoresProjeto.textoEscuro,
                                          ),
                                        ),
                                        if (horaFimSel != null)
                                          GestureDetector(
                                            onTap: () {
                                              setDialogState(() {
                                                horaFimSel = null;
                                              });
                                            },
                                            child: const Icon(Icons.clear, color: Colors.redAccent, size: 14),
                                          )
                                        else
                                          Icon(
                                            Icons.access_time,
                                            color: horaInicioSel == null ? CoresProjeto.textoClaro.withOpacity(0.3) : CoresProjeto.textoEscuro,
                                            size: 14,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Categoria e Tipo lado a lado
                      Row(
                        children: [
                          // Categoria
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'CATEGORIA',
                                  style: CoresProjeto.estiloTextoMono(9, bold: true, cor: CoresProjeto.textoClaro),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: CoresProjeto.bordaCinza, width: 1.0),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: catSel,
                                      style: CoresProjeto.estiloTextoMono(11),
                                      iconSize: 16,
                                      onChanged: (v) {
                                        if (v != null) {
                                          setDialogState(() {
                                            catSel = v;
                                          });
                                        }
                                      },
                                      items: categoriasDisp.map((c) {
                                        return DropdownMenuItem(
                                          value: c,
                                          child: Text(c.toUpperCase()),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Tipo (Privado/Compartilhado)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'VISIBILIDADE',
                                  style: CoresProjeto.estiloTextoMono(9, bold: true, cor: CoresProjeto.textoClaro),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: CoresProjeto.bordaCinza, width: 1.0),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: tipoSel,
                                      style: CoresProjeto.estiloTextoMono(11),
                                      iconSize: 16,
                                      onChanged: (v) {
                                        if (v != null) {
                                          setDialogState(() {
                                            tipoSel = v;
                                          });
                                        }
                                      },
                                      items: tiposDisp.map((t) {
                                        return DropdownMenuItem(
                                          value: t,
                                          child: Text(t.toUpperCase()),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                if (eventoExistente != null)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _excluirEvento(eventoExistente.id);
                    },
                    child: Text(
                      'EXCLUIR',
                      style: CoresProjeto.estiloTextoMono(11, bold: true, cor: Colors.redAccent),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'CANCELAR',
                    style: CoresProjeto.estiloTextoMono(11, cor: CoresProjeto.textoClaro),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final id = eventoExistente?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
                      final novoEv = EventoModel(
                        id: id,
                        usuario: eventoExistente?.usuario ?? _config.usuarioAtivo,
                        data: dataSel,
                        titulo: tituloCtrl.text.trim(),
                        descricao: descCtrl.text.trim(),
                        tipo: tipoSel,
                        categoria: catSel,
                        corHex: _obterHexDaCategoria(catSel),
                        concluido: eventoExistente?.concluido ?? false,
                        horaInicio: horaInicioSel,
                        horaFim: horaFimSel,
                      );

                      setState(() {
                        if (eventoExistente == null) {
                          _eventos.add(novoEv);
                        } else {
                          final idx = _eventos.indexWhere((e) => e.id == id);
                          if (idx != -1) _eventos[idx] = novoEv;
                        }
                      });

                      Navigator.of(context).pop();
                      _salvarDadosGerais();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CoresProjeto.destaqueAtivo,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: Text(
                    'GRAVAR',
                    style: CoresProjeto.estiloTextoMono(11, bold: true, cor: CoresProjeto.destaqueTexto),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _excluirEvento(String id) async {
    setState(() {
      _eventos.removeWhere((e) => e.id == id);
    });
    await _salvarDadosGerais();
  }

  // --- Operações do Checklist de Tarefas ---

  Future<void> _adicionarTarefaRapida() async {
    final titulo = _novaTarefaController.text.trim();
    if (titulo.isEmpty) return;

    // A tarefa do mês é salva como um evento especial no dia 1 daquele mês, com a categoria 'Tarefa'
    final novaTarefa = EventoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      usuario: _config.usuarioAtivo,
      data: DateTime(_dataSelecionada.year, _dataSelecionada.month, 1),
      titulo: titulo,
      descricao: '',
      tipo: _tipoNovaTarefa,
      categoria: 'Tarefa',
      corHex: '#CCCCCC',
      concluido: false,
    );

    setState(() {
      _eventos.add(novaTarefa);
      _novaTarefaController.clear();
    });

    await _salvarDadosGerais();
  }

  Future<void> _alternarStatusTarefa(EventoModel tarefa) async {
    final atualizada = tarefa.copyWith(concluido: !tarefa.concluido);
    setState(() {
      final idx = _eventos.indexWhere((e) => e.id == tarefa.id);
      if (idx != -1) _eventos[idx] = atualizada;
    });
    await _salvarDadosGerais();
  }

  // --- Auxiliares Visuais ---

  String _obterHexDaCategoria(String cat) {
    switch (cat) {
      case 'Encontro':
        return '#F3C5C5';
      case 'Estudo':
        return '#C5DFF8';
      case 'Trabalho':
        return '#DFF1D8';
      case 'Viagem':
        return '#F7ECDE';
      case 'Hobby':
        return '#FCD3B6';
      case 'Especial':
        return '#E2D4F0';
      default:
        return '#EAEAEA';
    }
  }

  InputDecoration _buildModalInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: CoresProjeto.estiloTextoMono(10, cor: CoresProjeto.textoClaro.withOpacity(0.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: CoresProjeto.bordaCinza, width: 1.0),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: CoresProjeto.destaqueAtivo, width: 1.5),
      ),
    );
  }

  // --- RENDERIZADORES DO WIDGET ---

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

    // Calcula a largura da tela para torná-lo responsivo
    final larguraTela = MediaQuery.of(context).size.width;
    final usarLayoutCompacto = larguraTela < 1000;

    return Scaffold(
      backgroundColor: CoresProjeto.fundoCaderno,
      body: SafeArea(
        child: Column(
          children: [
            // 1. BARRA SUPERIOR DE CONEXÃO E NAVEGAÇÃO
            _buildBarraSuperior(),

            // 2. CORPO PRINCIPAL DO CADERNO
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: usarLayoutCompacto
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSeletorMeses(true),
                            const SizedBox(height: 16),
                            _buildCalendarioCentral(),
                            const SizedBox(height: 24),
                            _buildPainelLateral(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Painel Esquerdo (Notas e Grade)
                            SizedBox(
                              width: 280,
                              child: _buildPainelLateral(),
                            ),
                            const SizedBox(width: 24),
                            // Calendário e Meses à Direita
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildSeletorMeses(false),
                                  const SizedBox(height: 16),
                                  _buildCalendarioCentral(),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Barra Superior com Informações
  Widget _buildBarraSuperior() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: CoresProjeto.fundoCaderno,
        border: Border(
          bottom: BorderSide(color: CoresProjeto.bordaCinza, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo/Título
          Row(
            children: [
              Text(
                'PLANEJAMENTO MENSAL',
                style: CoresProjeto.estiloTitulo(16),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: CoresProjeto.destaqueAtivo, width: 1.0),
                ),
                child: Text(
                  _config.usuarioAtivo.toUpperCase(),
                  style: CoresProjeto.estiloTextoMono(9, bold: true, cor: CoresProjeto.destaqueAtivo),
                ),
              ),
            ],
          ),

          // Controles (Sincronizar, Configurar, Logout)
          Row(
            children: [
              // Indicador de Sincronização
              if (_config.estaConfiguradoGithub) ...[
                if (_sincronizando)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5, color: CoresProjeto.destaqueAtivo),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.sync, color: CoresProjeto.textoEscuro, size: 18),
                    tooltip: 'Sincronizar agora',
                    onPressed: _sincronizarComGithub,
                  ),
                const SizedBox(width: 8),
                Text(
                  _mensagemSinc.toUpperCase(),
                  style: CoresProjeto.estiloTextoMono(9, cor: CoresProjeto.textoClaro),
                ),
                const SizedBox(width: 16),
              ],

              // Botão Configurações
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: CoresProjeto.textoEscuro, size: 20),
                tooltip: 'Ajustes / GitHub API',
                onPressed: () async {
                  final mudou = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (context) => const ConfigScreen()),
                  );
                  if (mudou == true) {
                    _inicializarDados(); // Recarrega se alterou configs
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Linha superior de seletor de meses
  Widget _buildSeletorMeses(bool compacto) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: compacto ? WrapAlignment.center : WrapAlignment.end,
        children: List.generate(12, (index) {
          final selecionado = _dataSelecionada.month == (index + 1);
          return InkWell(
            onTap: () async {
              await _salvarNotas();
              setState(() {
                _dataSelecionada = DateTime(_dataSelecionada.year, index + 1, 1);
              });
              _atualizarNotasController();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selecionado ? CoresProjeto.destaqueAtivo : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selecionado ? CoresProjeto.destaqueAtivo : CoresProjeto.bordaCinza.withOpacity(0.5),
                  width: 1.0,
                ),
              ),
              child: Text(
                _mesesAbreviados[index],
                style: CoresProjeto.estiloTextoMono(
                  11,
                  bold: selecionado,
                  cor: selecionado ? CoresProjeto.destaqueTexto : CoresProjeto.textoEscuro,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBotaoFiltroNota(String tipo, IconData icone) {
    final ativo = _tipoNotaAtivo == tipo;
    return Tooltip(
      message: tipo == 'Compartilhado' ? 'Notas Compartilhadas' : 'Minhas Notas Particulares',
      child: InkWell(
        onTap: () async {
          if (_tipoNotaAtivo == tipo) return;
          await _salvarNotas();
          setState(() {
            _tipoNotaAtivo = tipo;
            _atualizarNotasController();
          });
        },
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: ativo ? CoresProjeto.textoEscuro : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            icone,
            size: 11,
            color: ativo
                ? CoresProjeto.fundoCaderno
                : (tipo == 'Compartilhado' ? Colors.redAccent : CoresProjeto.textoClaro),
          ),
        ),
      ),
    );
  }

  // Painel Esquerdo (Notas e Grade quadriculada de tarefas)
  Widget _buildPainelLateral() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // CAIXA 1: NOTAS DO MÊS
        Container(
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: CoresProjeto.bordaCinza, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: CoresProjeto.bordaCinza, width: 1.0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NOTAS DO MÊS',
                      style: CoresProjeto.estiloTextoMono(10, bold: true),
                    ),
                    Row(
                      children: [
                        _buildBotaoFiltroNota('Compartilhado', Icons.favorite),
                        const SizedBox(width: 4),
                        _buildBotaoFiltroNota('Privado', Icons.lock),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: CoresProjeto.fundoCaderno,
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      if (!hasFocus) {
                        _salvarNotas();
                      }
                    },
                    child: TextField(
                      controller: _notasController,
                      maxLines: null,
                      expands: true,
                      cursorColor: CoresProjeto.textoEscuro,
                      style: CoresProjeto.estiloTextoMono(12),
                      decoration: const InputDecoration(
                        hintText: 'Escreva pensamentos, planos livres...',
                        hintStyle: TextStyle(color: Colors.black26, fontSize: 11),
                        contentPadding: EdgeInsets.all(12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),

        // CAIXA 2: GRADE MILIMETRADA (CHECKLIST TAREFAS DO MÊS)
        Container(
          height: 380,
          decoration: BoxDecoration(
            border: Border.all(color: CoresProjeto.bordaCinza, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: CoresProjeto.bordaCinza, width: 1.0)),
                ),
                child: Text(
                  'METAS & TAREFAS',
                  style: CoresProjeto.estiloTextoMono(10, bold: true),
                ),
              ),
              // Campo para criar nova tarefa rápida
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _novaTarefaController,
                        style: CoresProjeto.estiloTextoMono(11),
                        cursorColor: CoresProjeto.textoEscuro,
                        decoration: _buildModalInputDecoration('Nova meta...'),
                        onSubmitted: (_) => _adicionarTarefaRapida(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Seletor de tipo de nova meta (Compartilhado vs Privado)
                    Tooltip(
                      message: _tipoNovaTarefa == 'Compartilhado' ? 'Meta Compartilhada' : 'Meta Particular',
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _tipoNovaTarefa = _tipoNovaTarefa == 'Compartilhado' ? 'Privado' : 'Compartilhado';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(color: CoresProjeto.bordaCinza, width: 1.0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            _tipoNovaTarefa == 'Compartilhado' ? Icons.favorite : Icons.lock,
                            size: 14,
                            color: _tipoNovaTarefa == 'Compartilhado' ? Colors.redAccent : CoresProjeto.textoEscuro,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.add, color: CoresProjeto.textoEscuro, size: 20),
                      onPressed: _adicionarTarefaRapida,
                    ),
                  ],
                ),
              ),
              const Divider(color: CoresProjeto.bordaCinza, height: 1.0, thickness: 1.0),
              // Checklist sobre papel quadriculado
              Expanded(
                child: GradeMilimetrada(
                  espacamento: 15.0,
                  child: _buildChecklistTarefas(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Lista de Tarefas / Checklist
  Widget _buildChecklistTarefas() {
    final tarefas = _obterTarefasDoMes();
    if (tarefas.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma meta este mês.',
          style: CoresProjeto.estiloTextoMono(10, cor: CoresProjeto.textoClaro),
        ),
      );
    }

    return ListView.builder(
      itemCount: tarefas.length,
      itemBuilder: (context, index) {
        final t = tarefas[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: Row(
            children: [
              InkWell(
                onTap: () => _alternarStatusTarefa(t),
                child: Icon(
                  t.concluido ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                  size: 16,
                  color: CoresProjeto.textoEscuro,
                ),
              ),
              const SizedBox(width: 8),
              // Ícone indicando se é compartilhada (coração) ou privada (cadeado)
              Icon(
                t.tipo == 'Compartilhado' ? Icons.favorite : Icons.lock,
                size: 11,
                color: t.tipo == 'Compartilhado' ? Colors.redAccent : CoresProjeto.textoClaro,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t.titulo,
                  style: CoresProjeto.estiloTextoMono(
                    11,
                    cor: t.concluido ? CoresProjeto.textoClaro : CoresProjeto.textoEscuro,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.clear, size: 12, color: Colors.redAccent),
                onPressed: () => _excluirEvento(t.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Calendário Central Grid
  Widget _buildCalendarioCentral() {
    final diasGrade = _gerarDiasGrade();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: CoresProjeto.bordaCinza, width: 1.0),
      ),
      child: Column(
        children: [
          // Cabeçalhos (Dias da Semana SEG, TER...)
          Row(
            children: _diasSemana.map((d) {
              return Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: CoresProjeto.fundoCaderno,
                    border: Border(
                      right: d != 'DOM' ? const BorderSide(color: CoresProjeto.bordaCinza, width: 0.5) : BorderSide.none,
                      bottom: const BorderSide(color: CoresProjeto.bordaCinza, width: 1.0),
                    ),
                  ),
                  child: Text(
                    d,
                    style: CoresProjeto.estiloTextoMono(11, bold: true),
                  ),
                ),
              );
            }).toList(),
          ),

          // Grid de Células
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.1, // Células levemente horizontais como na imagem
            ),
            itemCount: diasGrade.length,
            itemBuilder: (context, index) {
              final data = diasGrade[index];
              final eUltimaColuna = (index + 1) % 7 == 0;

              if (data == null) {
                // Célula vazia (dia de outro mês)
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      right: !eUltimaColuna ? const BorderSide(color: CoresProjeto.bordaCinza, width: 0.5) : BorderSide.none,
                      bottom: const BorderSide(color: CoresProjeto.bordaCinza, width: 0.5),
                    ),
                  ),
                );
              }

              final evs = _obterEventosDoDia(data);
              final eHoje = data.day == DateTime.now().day &&
                            data.month == DateTime.now().month &&
                            data.year == DateTime.now().year;

              return InkWell(
                onTap: () => _adicionarOuEditarEvento(null, dataInicial: data),
                child: Container(
                  decoration: BoxDecoration(
                    color: eHoje ? CoresProjeto.gradePapel.withOpacity(0.4) : Colors.transparent,
                    border: Border(
                      right: !eUltimaColuna ? const BorderSide(color: CoresProjeto.bordaCinza, width: 0.5) : BorderSide.none,
                      bottom: const BorderSide(color: CoresProjeto.bordaCinza, width: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Número do Dia (Canto superior direito)
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                          margin: const EdgeInsets.only(top: 2, right: 2),
                          decoration: const BoxDecoration(
                            color: CoresProjeto.marcadorCinza,
                          ),
                          child: Text(
                            data.day.toString(),
                            style: CoresProjeto.estiloTextoMono(
                              10,
                              bold: true,
                              cor: CoresProjeto.textoEscuro,
                            ),
                          ),
                        ),
                      ),
                      
                      // Compromissos/Tags do Dia
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          itemCount: evs.length,
                          itemBuilder: (context, evIdx) {
                            final ev = evs[evIdx];
                            final corFundo = CoresProjeto.obterCorCategoria(ev.categoria);
                            final corBorda = CoresProjeto.obterCorBordaCategoria(ev.categoria);
                            
                            // Determina qual foto exibir com base no tipo do evento
                            final fotoEvento = ev.tipo == 'Compartilhado'
                                ? LoginScreen.obterFotoCasal()
                                : LoginScreen.obterFotoPerfil(ev.usuario);

                            return GestureDetector(
                              onTap: () => _adicionarOuEditarEvento(ev),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 3.0),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                decoration: BoxDecoration(
                                  color: corFundo,
                                  border: Border.all(color: corBorda, width: 0.7),
                                ),
                                child: Row(
                                  children: [
                                    // Mini foto de perfil circular
                                    ClipOval(
                                      child: SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: Image.network(
                                          fotoEvento,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.person,
                                            size: 10,
                                            color: CoresProjeto.textoClaro,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        ev.horaInicio != null
                                            ? '${ev.horaInicio} ${ev.titulo}'
                                            : ev.titulo,
                                        style: CoresProjeto.estiloTextoMono(
                                          8, 
                                          bold: true, 
                                          cor: CoresProjeto.textoEscuro
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
