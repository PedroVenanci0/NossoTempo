class EventoModel {
  final String id;
  final String usuario; // 'Pedro' ou 'Namorada'
  final DateTime data;
  final String titulo;
  final String descricao;
  final String tipo; // 'Privado' ou 'Compartilhado'
  final String categoria; // 'Encontro', 'Estudo', 'Trabalho', 'Viagem', 'Especial', 'Outros'
  final String corHex; // Cor em formato hexadecimal (ex: #F3C5C5)
  final bool concluido; // Status para tarefas ou checklist
  final String? horaInicio; // Formato HH:mm
  final String? horaFim; // Formato HH:mm

  EventoModel({
    required this.id,
    required this.usuario,
    required this.data,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.categoria,
    required this.corHex,
    this.concluido = false,
    this.horaInicio,
    this.horaFim,
  });

  // Converte um EventoModel em uma linha de CSV
  // Garante que aspas e quebras de linha sejam escapadas
  List<String> toCsvRow() {
    return [
      id,
      usuario,
      _formatarData(data),
      _escaparCsv(titulo),
      _escaparCsv(descricao),
      tipo,
      categoria,
      corHex,
      concluido.toString(),
      horaInicio ?? '',
      horaFim ?? '',
    ];
  }

  // Cria um EventoModel a partir de uma linha parseada do CSV
  factory EventoModel.fromCsvRow(List<String> campos) {
    return EventoModel(
      id: campos[0],
      usuario: campos[1],
      data: DateTime.parse(campos[2]),
      titulo: _desescaparCsv(campos[3]),
      descricao: _desescaparCsv(campos[4]),
      tipo: campos[5],
      categoria: campos[6],
      corHex: campos[7],
      concluido: campos.length > 8 ? campos[8].toLowerCase() == 'true' : false,
      horaInicio: campos.length > 9 && campos[9].isNotEmpty ? campos[9] : null,
      horaFim: campos.length > 10 && campos[10].isNotEmpty ? campos[10] : null,
    );
  }

  // ----- Supabase (Map<String,dynamic>) -----

  // Converte o evento em um Map para inserir/atualizar no Supabase.
  // As chaves seguem o snake_case da tabela `public.eventos`.
  Map<String, dynamic> toSupabaseRow() {
    return {
      'id': id,
      'usuario': usuario,
      'data': _formatarData(data),
      'titulo': titulo,
      'descricao': descricao,
      'tipo': tipo,
      'categoria': categoria,
      'cor_hex': corHex,
      'concluido': concluido,
      'hora_inicio': horaInicio,
      'hora_fim': horaFim,
    };
  }

  // Constroi um EventoModel a partir de uma linha vinda do Supabase.
  factory EventoModel.fromSupabaseRow(Map<String, dynamic> row) {
    return EventoModel(
      id: row['id']?.toString() ?? '',
      usuario: row['usuario']?.toString() ?? '',
      data: DateTime.parse(row['data'].toString()),
      titulo: row['titulo']?.toString() ?? '',
      descricao: row['descricao']?.toString() ?? '',
      tipo: row['tipo']?.toString() ?? '',
      categoria: row['categoria']?.toString() ?? '',
      corHex: row['cor_hex']?.toString() ?? '',
      concluido: row['concluido'] == true,
      horaInicio: row['hora_inicio']?.toString().isNotEmpty == true ? row['hora_inicio'].toString() : null,
      horaFim: row['hora_fim']?.toString().isNotEmpty == true ? row['hora_fim'].toString() : null,
    );
  }

  EventoModel copyWith({
    String? id,
    String? usuario,
    DateTime? data,
    String? titulo,
    String? descricao,
    String? tipo,
    String? categoria,
    String? corHex,
    bool? concluido,
    String? horaInicio,
    String? horaFim,
    bool resetHoraInicio = false,
    bool resetHoraFim = false,
  }) {
    return EventoModel(
      id: id ?? this.id,
      usuario: usuario ?? this.usuario,
      data: data ?? this.data,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      tipo: tipo ?? this.tipo,
      categoria: categoria ?? this.categoria,
      corHex: corHex ?? this.corHex,
      concluido: concluido ?? this.concluido,
      horaInicio: resetHoraInicio ? null : (horaInicio ?? this.horaInicio),
      horaFim: resetHoraFim ? null : (horaFim ?? this.horaFim),
    );
  }

  // Auxiliares de formatação e escape do CSV
  static String _formatarData(DateTime data) {
    return '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
  }

  static String _escaparCsv(String texto) {
    String t = texto.replaceAll('"', '""');
    if (t.contains(',') || t.contains('\n') || t.contains('"')) {
      return '"$t"';
    }
    return t;
  }

  static String _desescaparCsv(String texto) {
    String t = texto;
    if (t.startsWith('"') && t.endsWith('"')) {
      t = t.substring(1, t.length - 1);
    }
    return t.replaceAll('""', '"');
  }
}
