import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? 'Código não encontrado';
      
      // Para o scanner para evitar múltiplas deteções
      _scannerController.stop();

      // Mostra um diálogo com o código e um botão para voltar a digitalizar
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text('Código Detetado'),
            content: Text('O valor do código é: $code'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _scannerController.start(); // Volta a ligar o scanner
                },
                child: const Text('Digitalizar Novamente'),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implementar navegação para o ecrã do produto
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Volta ao ecrã anterior
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leitor de QR Code')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          // Adiciona uma sobreposição visual para guiar o utilizador
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 4),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
} 