import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/config_model.dart';
import '../models/evento_model.dart';

// Servico responsavel por todo o CRUD e o stream em tempo real
// da tabela `public.eventos` no Supabase.
class SupabaseService {
  static const String _tabela = 'eventos';

  static bool _inicializado = false;
  static String? _urlAtual;
  static String? _anonKeyAtual;

  // Inicializa o cliente Supabase. Pode ser chamado novamente quando o usuario
  // troca as credenciais na tela de configuracao (re-init nao e suportado
  // diretamente, mas se as credenciais nao mudaram, apenas retorna).
  static Future<void> inicializar(ConfigModel config) async {
    if (!config.estaConfiguradoSupabase) return;
    if (_inicializado &&
        _urlAtual == config.supabaseUrl &&
        _anonKeyAtual == config.supabaseAnonKey) {
      return;
    }

    try {
      await Supabase.initialize(
        url: config.supabaseUrl,
        anonKey: config.supabaseAnonKey,
        debug: false,
      );
      _inicializado = true;
      _urlAtual = config.supabaseUrl;
      _anonKeyAtual = config.supabaseAnonKey;
    } catch (e) {
      debugPrint('Erro ao inicializar Supabase: $e');
    }
  }

  static bool get prontoParaUsar => _inicializado;

  SupabaseClient get _client => Supabase.instance.client;

  // Stream que emite a lista completa de eventos sempre que algo muda no banco.
  // Funciona em tempo real via WebSocket (canal Realtime).
  Stream<List<EventoModel>> streamEventos() {
    return _client
        .from(_tabela)
        .stream(primaryKey: ['id'])
        .map((rows) => rows
            .map((r) => EventoModel.fromSupabaseRow(r))
            .toList());
  }

  // Carrega todos os eventos uma unica vez (usado como fallback inicial).
  Future<List<EventoModel>> carregarTodos() async {
    final response = await _client.from(_tabela).select();
    return (response as List)
        .map((r) => EventoModel.fromSupabaseRow(r as Map<String, dynamic>))
        .toList();
  }

  // Insere ou atualiza um evento (upsert por chave primaria `id`).
  Future<void> salvarEvento(EventoModel evento) async {
    await _client.from(_tabela).upsert(evento.toSupabaseRow());
  }

  // Atualiza um evento existente.
  Future<void> atualizarEvento(EventoModel evento) async {
    await _client
        .from(_tabela)
        .update(evento.toSupabaseRow())
        .eq('id', evento.id);
  }

  // Deleta um evento pelo id.
  Future<void> deletarEvento(String id) async {
    await _client.from(_tabela).delete().eq('id', id);
  }

  // Upsert em lote (usado na migracao a partir do CSV).
  Future<void> upsertEmLote(List<EventoModel> eventos) async {
    if (eventos.isEmpty) return;
    final rows = eventos.map((e) => e.toSupabaseRow()).toList();
    await _client.from(_tabela).upsert(rows);
  }
}
