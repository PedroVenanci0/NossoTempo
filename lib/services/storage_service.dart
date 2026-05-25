import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/config_model.dart';
import '../models/evento_model.dart';
import '../utils/cores_projeto.dart';
import '../utils/csv_helper.dart';

class StorageService {
  static const String keyConfig = 'calendario_config';
  static const String keyEventosLocais = 'calendario_eventos_locais';

  // Salva o modelo de configuração completo
  Future<bool> salvarConfig(ConfigModel config) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonStr = jsonEncode(config.toJson());
    CoresProjeto.temaAtivo = config.tema;
    return await prefs.setString(keyConfig, jsonStr);
  }

  // Carrega o modelo de configuração
  Future<ConfigModel> carregarConfig() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonStr = prefs.getString(keyConfig);
    if (jsonStr == null || jsonStr.isEmpty) {
      final config = ConfigModel();
      CoresProjeto.temaAtivo = config.tema;
      return config;
    }
    try {
      Map<String, dynamic> map = jsonDecode(jsonStr);
      final config = ConfigModel.fromJson(map);
      CoresProjeto.temaAtivo = config.tema;
      return config;
    } catch (e) {
      debugPrint('Erro ao decodificar configurações: $e');
      final config = ConfigModel();
      CoresProjeto.temaAtivo = config.tema;
      return config;
    }
  }

  // Salva a lista de eventos localmente em formato CSV
  Future<bool> salvarEventosLocais(List<EventoModel> eventos) async {
    final prefs = await SharedPreferences.getInstance();
    String csvStr = CsvHelper.converterParaCsv(eventos);
    return await prefs.setString(keyEventosLocais, csvStr);
  }

  // Carrega a lista de eventos localmente
  Future<List<EventoModel>> carregarEventosLocais() async {
    final prefs = await SharedPreferences.getInstance();
    String? csvStr = prefs.getString(keyEventosLocais);
    if (csvStr == null || csvStr.isEmpty) {
      return [];
    }
    return CsvHelper.parsearCsv(csvStr);
  }

  // Limpa todos os dados salvos localmente
  Future<void> limparDados() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyConfig);
    await prefs.remove(keyEventosLocais);
  }
}
