import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/config_model.dart';
import '../models/evento_model.dart';
import '../utils/csv_helper.dart';

class GithubService {
  // Armazena o sha do arquivo retornado pelo GitHub para fazer a atualização corretamente
  String? _ultimoSha;

  // Sanitiza o campo de repositório para extrair apenas 'dono/repo'
  // Aceita formatos como:
  //   - 'PedroVenanci0/NossoTempoDataSet' (já correto)
  //   - 'https://github.com/PedroVenanci0/NossoTempoDataSet'
  //   - 'https://github.com/PedroVenanci0/NossoTempoDataSet.git'
  //   - 'github.com/PedroVenanci0/NossoTempoDataSet'
  String _sanitizarRepo(String repo) {
    String limpo = repo.trim();
    // Remove protocolo e domínio
    limpo = limpo.replaceAll(RegExp(r'^https?://'), '');
    limpo = limpo.replaceAll(RegExp(r'^github\.com/'), '');
    // Remove sufixo .git
    limpo = limpo.replaceAll(RegExp(r'\.git$'), '');
    // Remove barras extras no final
    limpo = limpo.replaceAll(RegExp(r'/+$'), '');
    return limpo;
  }

  // Carrega os eventos direto do repositório do GitHub
  // Retorna um Map contendo {'sucesso': bool, 'eventos': List<EventoModel>, 'mensagem': String}
  Future<Map<String, dynamic>> carregarDoGithub(ConfigModel config) async {
    if (!config.estaConfiguradoGithub) {
      return {
        'sucesso': false,
        'eventos': <EventoModel>[],
        'mensagem': 'GitHub não configurado.'
      };
    }

    final repo = _sanitizarRepo(config.githubRepo);
    final url = Uri.parse(
      'https://api.github.com/repos/$repo/contents/${config.caminhoArquivo}?ref=${config.ramo}'
    );

    try {
      final resposta = await http.get(
        url,
        headers: {
          'Authorization': 'token ${config.githubToken}',
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'Flutter-Calendario-App'
        },
      );

      if (resposta.statusCode == 200) {
        final dados = jsonDecode(resposta.body);
        _ultimoSha = dados['sha'];
        
        // O conteúdo vem codificado em Base64 com quebras de linha que precisamos remover antes de decodificar
        String conteudoBase64 = dados['content'].toString().replaceAll('\n', '').replaceAll('\r', '');
        List<int> bytes = base64Decode(conteudoBase64);
        String csvTexto = utf8.decode(bytes);

        List<EventoModel> eventos = CsvHelper.parsearCsv(csvTexto);
        return {
          'sucesso': true,
          'eventos': eventos,
          'mensagem': 'Calendário sincronizado com sucesso!'
        };
      } else if (resposta.statusCode == 404) {
        // Arquivo ainda não existe, precisamos criar ele na primeira gravação
        _ultimoSha = null;
        return {
          'sucesso': true,
          'eventos': <EventoModel>[],
          'mensagem': 'Arquivo não encontrado. Um novo será criado na primeira alteração.'
        };
      } else {
        return {
          'sucesso': false,
          'eventos': <EventoModel>[],
          'mensagem': 'Erro ao conectar (Código ${resposta.statusCode}): ${resposta.reasonPhrase}'
        };
      }
    } catch (e) {
      return {
        'sucesso': false,
        'eventos': <EventoModel>[],
        'mensagem': 'Erro de rede: $e'
      };
    }
  }

  // Mutex (Future) usado para serializar todas as operacoes de escrita no GitHub.
  // Garante que dois saves simultaneos nao racem buscando/sobrescrevendo SHA.
  Future<void>? _lockSalvar;

  // Envia e commita o arquivo CSV no repositorio do GitHub.
  // Estrategia anti-409:
  //   1. Serializa saves com mutex (sem races entre cliques rapidos)
  //   2. Sempre busca SHA FRESCO imediatamente antes do PUT (ignora cache)
  //   3. Em caso de 409, recarrega/mescla/retenta ate 3 vezes com backoff
  // Retorna {'sucesso': bool, 'mensagem': String, 'eventosMesclados': List<EventoModel>?}
  Future<Map<String, dynamic>> salvarNoGithub(
    ConfigModel config,
    List<EventoModel> eventos,
  ) async {
    if (!config.estaConfiguradoGithub) {
      return {
        'sucesso': false,
        'mensagem': 'GitHub nao configurado para salvamento.'
      };
    }

    // Espera qualquer save em andamento terminar antes de comecar este
    while (_lockSalvar != null) {
      try {
        await _lockSalvar;
      } catch (_) {}
    }

    final completer = Completer<void>();
    _lockSalvar = completer.future;
    try {
      return await _executarSalvar(config, eventos);
    } finally {
      _lockSalvar = null;
      completer.complete();
    }
  }

  Future<Map<String, dynamic>> _executarSalvar(
    ConfigModel config,
    List<EventoModel> eventos,
  ) async {
    final repo = _sanitizarRepo(config.githubRepo);
    final url = Uri.parse(
      'https://api.github.com/repos/$repo/contents/${config.caminhoArquivo}'
    );

    List<EventoModel> eventosParaSalvar = eventos;
    bool foiMesclado = false;
    const int maxTentativas = 3;

    for (int tentativa = 0; tentativa < maxTentativas; tentativa++) {
      // Sempre busca o SHA mais recente imediatamente antes do PUT.
      // Isso minimiza a janela de race entre GET e PUT.
      final resultadoRecarga = await carregarDoGithub(config);
      if (resultadoRecarga['sucesso'] != true) {
        return {
          'sucesso': false,
          'mensagem': 'Falha ao buscar versao atual antes de salvar: ${resultadoRecarga['mensagem']}',
        };
      }

      // Em retentativas, mescla eventos locais com o que o servidor tem agora.
      if (tentativa > 0) {
        final List<EventoModel> remotos = resultadoRecarga['eventos'];
        eventosParaSalvar = _mesclarEventos(eventosParaSalvar, remotos);
        foiMesclado = true;
      }

      final String csvConteudo = CsvHelper.converterParaCsv(eventosParaSalvar);
      final String conteudoBase64 = base64Encode(utf8.encode(csvConteudo));

      final Map<String, dynamic> body = {
        'message': 'Sincronizacao Calendario por ${config.usuarioAtivo.isEmpty ? "App" : config.usuarioAtivo}',
        'content': conteudoBase64,
        'branch': config.ramo,
      };
      if (_ultimoSha != null) {
        body['sha'] = _ultimoSha;
      }

      try {
        final resposta = await http.put(
          url,
          headers: {
            'Authorization': 'token ${config.githubToken}',
            'Accept': 'application/vnd.github+json',
            'Content-Type': 'application/json',
            'User-Agent': 'Flutter-Calendario-App'
          },
          body: jsonEncode(body),
        );

        if (resposta.statusCode == 200 || resposta.statusCode == 201) {
          final dados = jsonDecode(resposta.body);
          _ultimoSha = dados['content']['sha'];
          return {
            'sucesso': true,
            'mensagem': foiMesclado
                ? 'Sincronizado (mesclado com mudancas remotas).'
                : 'Alteracoes salvas no GitHub com sucesso!',
            'eventosMesclados': eventosParaSalvar,
          };
        }

        if (resposta.statusCode == 409) {
          _ultimoSha = null;
          // Backoff curto antes da proxima tentativa
          await Future.delayed(Duration(milliseconds: 200 * (tentativa + 1)));
          continue;
        }

        return {
          'sucesso': false,
          'mensagem': 'Erro ao salvar (Codigo ${resposta.statusCode}): ${resposta.reasonPhrase}',
        };
      } catch (e) {
        return {
          'sucesso': false,
          'mensagem': 'Erro de rede ao salvar: $e',
        };
      }
    }

    return {
      'sucesso': false,
      'mensagem': 'Conflito persistente apos $maxTentativas tentativas. Recarregue a pagina.',
    };
  }

  // Mescla eventos locais com remotos: locais têm prioridade em conflitos de ID,
  // remotos extras (criados por outro usuário enquanto isso) são preservados.
  List<EventoModel> _mesclarEventos(List<EventoModel> locais, List<EventoModel> remotos) {
    final idsLocais = {for (var e in locais) e.id};
    final List<EventoModel> resultado = List<EventoModel>.from(locais);
    for (final r in remotos) {
      if (!idsLocais.contains(r.id)) {
        resultado.add(r);
      }
    }
    return resultado;
  }
}

