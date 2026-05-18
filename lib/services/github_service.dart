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

  // Envia e commita o arquivo CSV no repositório do GitHub
  // Retorna um Map contendo {'sucesso': bool, 'mensagem': String}
  Future<Map<String, dynamic>> salvarNoGithub(ConfigModel config, List<EventoModel> eventos) async {
    if (!config.estaConfiguradoGithub) {
      return {
        'sucesso': false,
        'mensagem': 'GitHub não configurado para salvamento.'
      };
    }

    // Primeiro, tenta carregar para obter o SHA atualizado e evitar conflitos de commit (out-of-sync)
    if (_ultimoSha == null) {
      await carregarDoGithub(config);
    }

    final repo = _sanitizarRepo(config.githubRepo);
    final url = Uri.parse(
      'https://api.github.com/repos/$repo/contents/${config.caminhoArquivo}'
    );

    String csvConteudo = CsvHelper.converterParaCsv(eventos);
    List<int> bytes = utf8.encode(csvConteudo);
    String conteudoBase64 = base64Encode(bytes);

    Map<String, dynamic> body = {
      'message': 'Sincronização Calendário por ${config.usuarioAtivo.isEmpty ? "App" : config.usuarioAtivo}',
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
        _ultimoSha = dados['content']['sha']; // Atualiza o SHA local com o novo sha retornado
        return {
          'sucesso': true,
          'mensagem': 'Alterações salvas no GitHub com sucesso!'
        };
      } else {
        // Se der erro de conflito (409), significa que o SHA está desatualizado. Força uma recarga.
        if (resposta.statusCode == 409) {
          _ultimoSha = null; // Reseta sha para forçar recarga da próxima vez
          return {
            'sucesso': false,
            'mensagem': 'Erro de concorrência: Os dados no GitHub foram modificados. Recarregue a página antes de salvar.'
          };
        }
        return {
          'sucesso': false,
          'mensagem': 'Erro ao salvar (Código ${resposta.statusCode}): ${resposta.reasonPhrase}'
        };
      }
    } catch (e) {
      return {
        'sucesso': false,
        'mensagem': 'Erro de rede ao salvar: $e'
      };
    }
  }
}

