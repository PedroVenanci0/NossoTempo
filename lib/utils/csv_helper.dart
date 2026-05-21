import 'package:flutter/foundation.dart';
import '../models/evento_model.dart';

class CsvHelper {
  // Cabeçalho padrão do CSV
  static const String cabecalho = 'id,usuario,data,titulo,descricao,tipo,categoria,corHex,concluido,horaInicio,horaFim';

  // Transforma uma lista de eventos em uma string CSV completa
  static String converterParaCsv(List<EventoModel> eventos) {
    StringBuffer sb = StringBuffer();
    sb.writeln(cabecalho);
    for (var evento in eventos) {
      sb.writeln(evento.toCsvRow().join(','));
    }
    return sb.toString();
  }

  // Faz o parse de uma string CSV completa para uma lista de eventos
  static List<EventoModel> parsearCsv(String csvString) {
    if (csvString.isEmpty) return [];

    List<EventoModel> eventos = [];
    List<String> linhas = csvString.split('\n');

    for (int i = 0; i < linhas.length; i++) {
      String linha = linhas[i].trim();
      if (linha.isEmpty) continue;
      
      // Pula a primeira linha (cabeçalho)
      if (i == 0 && linha.toLowerCase().startsWith('id,')) {
        continue;
      }

      try {
        List<String> campos = _parsearLinhaCsv(linha);
        if (campos.length >= 8) {
          eventos.add(EventoModel.fromCsvRow(campos));
        }
      } catch (e) {
        debugPrint('Erro ao processar linha $i do CSV: $linha. Erro: $e');
      }
    }

    return eventos;
  }

  // Faz o parse inteligente de uma linha do CSV lidando com aspas e vírgulas internas
  static List<String> _parsearLinhaCsv(String linha) {
    List<String> campos = [];
    StringBuffer campoAtual = StringBuffer();
    bool dentroDeAspas = false;

    for (int i = 0; i < linha.length; i++) {
      String char = linha[i];

      if (char == '"') {
        // Verifica se é uma aspa dupla escapada dentro de aspas ""
        if (dentroDeAspas && i + 1 < linha.length && linha[i + 1] == '"') {
          campoAtual.write('"');
          i++; // Pula a próxima aspa
        } else {
          // Inverte o estado de estar dentro das aspas
          dentroDeAspas = !dentroDeAspas;
        }
      } else if (char == ',' && !dentroDeAspas) {
        // Vírgula fora das aspas delimita o fim do campo
        campos.add(campoAtual.toString());
        campoAtual.clear();
      } else {
        campoAtual.write(char);
      }
    }
    // Adiciona o último campo
    campos.add(campoAtual.toString());

    return campos;
  }
}
