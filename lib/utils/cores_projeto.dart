import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CoresProjeto {
  static String temaAtivo = 'padrao'; // 'padrao', 'escuro', 'starwars', 'abelha'

  // Cores Principais do Caderno Bullet Journal
  static Color get fundoCaderno {
    if (temaAtivo == 'escuro') return const Color(0xFF161618);
    return const Color(0xFFFAF8F5);    // Creme suave / Off-white da imagem
  }

  static Color get bordaCinza {
    if (temaAtivo == 'escuro') return const Color(0xFF2C2C2E);
    if (temaAtivo == 'starwars') return const Color(0xFF3A3A3A);
    if (temaAtivo == 'abelha') return const Color(0xFFD4AF37); // Borda amarelada/dourada
    return const Color(0xFFB5B2A9);      // Cinza fino para as bordas das caixas
  }

  static Color get textoEscuro {
    if (temaAtivo == 'escuro') return const Color(0xFFE5E5EA);
    return const Color(0xFF2B2A27);     // Cinza escuro quase preto para os textos
  }

  static Color get textoClaro {
    if (temaAtivo == 'escuro') return const Color(0xFF8E8E93);
    return const Color(0xFF8C8A82);      // Cinza suave para dias de outros meses
  }

  static Color get marcadorCinza {
    if (temaAtivo == 'escuro') return const Color(0xFF2C2C2E);
    if (temaAtivo == 'abelha') return const Color(0xFFFFF6CC); // Amarelo bem suave
    return const Color(0xFFE5E2DA);   // Marcador de dia no canto superior direito
  }

  static Color get gradePapel {
    if (temaAtivo == 'escuro') return const Color(0xFF1C1C1E);
    if (temaAtivo == 'abelha') return const Color(0xFFFFFCE5); // Fundo amarelado
    return const Color(0xFFEFECE5);      // Linhas finas do papel milimetrado
  }

  // Cores de Destaque / Botões Selecionados
  static Color get destaqueAtivo {
    if (temaAtivo == 'escuro') return const Color(0xFFE5E5EA); // Destaque cinza claro no escuro
    if (temaAtivo == 'starwars') return const Color(0xFFFFC500); // Amarelo Star Wars
    if (temaAtivo == 'abelha') return const Color(0xFFFFD700); // Amarelo abelha / ouro
    return const Color(0xFF4A4944);   // Mês ativo, botões selecionados (cinza escuro)
  }

  static Color get destaqueTexto {
    if (temaAtivo == 'escuro') return const Color(0xFF1C1C1E);
    if (temaAtivo == 'starwars') return const Color(0xFF000000);
    if (temaAtivo == 'abelha') return const Color(0xFF000000);
    return const Color(0xFFFAF8F5);   // Texto sobre fundo ativo
  }

  // Texto de tag/compromisso (sempre escuro para ler sobre o fundo pastel do card)
  static Color get textoCard => const Color(0xFF2B2A27);

  // Paleta de Cores Pastéis para Categorias de Eventos
  static const Color pastelRosa = Color(0xFFF3C5C5);      // Encontro / Romântico
  static const Color pastelAzul = Color(0xFFC5DFF8);      // Estudo / Faculdade
  static const Color pastelVerde = Color(0xFFDFF1D8);     // Trabalho / Tarefas
  static const Color pastelAmarelo = Color(0xFFF7ECDE);   // Lazer / Viagem
  static const Color pastelRoxo = Color(0xFFE2D4F0);      // Especial / Aniversário
  static const Color pastelLaranja = Color(0xFFFCD3B6);   // Hobby
  static const Color pastelCinza = Color(0xFFEAEAEA);      // Outros

  // Cores para as Bordinhas de Categorias correspondentes
  static const Color bordaRosa = Color(0xFFDF9E9E);
  static const Color bordaAzul = Color(0xFF98C5EE);
  static const Color bordaVerde = Color(0xFFB5DCB5);
  static const Color bordaAmarelo = Color(0xFFE8CFB0);
  static const Color bordaRoxo = Color(0xFFC4ADDE);
  static const Color bordaLaranja = Color(0xFFE2A882);
  static const Color bordaCinzaEventos = Color(0xFFCCCCCC);

  // Mapeamento de Categoria para Cor
  static Color obterCorCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'encontro':
      case 'romântico':
      case 'lazer':
        return pastelRosa;
      case 'estudo':
      case 'faculdade':
      case 'curso':
        return pastelAzul;
      case 'trabalho':
      case 'tarefa':
        return pastelVerde;
      case 'viagem':
      case 'férias':
        return pastelAmarelo;
      case 'especial':
      case 'aniversário':
        return pastelRoxo;
      case 'hobby':
        return pastelLaranja;
      default:
        return pastelCinza;
    }
  }

  static Color obterCorBordaCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'encontro':
      case 'romântico':
      case 'lazer':
        return bordaRosa;
      case 'estudo':
      case 'faculdade':
      case 'curso':
        return bordaAzul;
      case 'trabalho':
      case 'tarefa':
        return bordaVerde;
      case 'viagem':
      case 'férias':
        return bordaAmarelo;
      case 'especial':
      case 'aniversário':
        return bordaRoxo;
      case 'hobby':
        return bordaLaranja;
      default:
        return bordaCinzaEventos;
    }
  }

  // Estilos de Texto Estilo Máquina de Escrever / Retro Moderno
  static TextStyle estiloTitulo(double tamanho) {
    return GoogleFonts.spaceMono(
      fontSize: tamanho,
      fontWeight: FontWeight.bold,
      color: textoEscuro,
      letterSpacing: 1.2,
    );
  }

  static TextStyle estiloTextoMono(double tamanho, {bool bold = false, Color? cor}) {
    return GoogleFonts.spaceMono(
      fontSize: tamanho,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: cor ?? textoEscuro,
    );
  }

  static TextStyle estiloTextoCorpo(double tamanho, {bool bold = false, Color? cor}) {
    return GoogleFonts.outfit(
      fontSize: tamanho,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: cor ?? textoEscuro,
    );
  }
}
