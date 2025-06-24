import 'package:flutter/material.dart';

// Arquivo simples para criar o logo do HelloFarmer
// Execute com: flutter run lib/create_logo.dart

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('HelloFarmer Logo Generator'),
          backgroundColor: Colors.green,
        ),
        body: const Center(
          child: LogoGenerator(),
        ),
      ),
    );
  }
}

class LogoGenerator extends StatefulWidget {
  const LogoGenerator({super.key});

  @override
  State<LogoGenerator> createState() => _LogoGeneratorState();
}

class _LogoGeneratorState extends State<LogoGenerator> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CustomPaint(
              size: const Size(300, 300),
              painter: LogoPainter(),
            ),
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          'Logo do HelloFarmer',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Para exportar o logo, use um aplicativo de design gráfico.'),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
          ),
          child: const Text('Exportar Logo'),
        ),
      ],
    );
  }
}

class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Desenhar círculo verde como base do logo
    final paint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2), 
      size.width * 0.4, 
      paint
    );
    
    // Desenhar uma folha estilizada
    paint.color = Colors.white;
    final path = Path();
    path.moveTo(size.width * 0.3, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.4, size.height * 0.3,
      size.width * 0.5, size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.6, size.height * 0.7,
      size.width * 0.7, size.height * 0.5,
    );
    path.lineTo(size.width * 0.5, size.height * 0.7);
    path.close();
    canvas.drawPath(path, paint);

    // Desenhar um caule para a folha
    paint.color = Colors.white;
    paint.strokeWidth = 8.0;
    paint.style = PaintingStyle.stroke;
    paint.strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.7),
      Offset(size.width * 0.5, size.height * 0.75),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
