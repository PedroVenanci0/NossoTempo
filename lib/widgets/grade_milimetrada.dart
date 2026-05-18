import 'package:flutter/material.dart';
import '../utils/cores_projeto.dart';

class GradeMilimetrada extends StatelessWidget {
  final Widget? child;
  final double espacamento;

  const GradeMilimetrada({
    super.key,
    this.child,
    this.espacamento = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GradeMilimetradaPainter(espacamento: espacamento),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        child: child,
      ),
    );
  }
}

class _GradeMilimetradaPainter extends CustomPainter {
  final double espacamento;

  _GradeMilimetradaPainter({required this.espacamento});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = CoresProjeto.gradePapel
      ..strokeWidth = 0.5;

    // Desenha linhas verticais
    for (double x = 0; x < size.width; x += espacamento) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Desenha linhas horizontais
    for (double y = 0; y < size.height; y += espacamento) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
