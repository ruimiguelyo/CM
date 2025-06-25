import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:hellofarmer_app/screens/product_detail_screen.dart';
import 'package:hellofarmer_app/screens/producer_detail_screen.dart';
import 'package:hellofarmer_app/models/product_model.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      setState(() {
        _isProcessing = true;
      });
      
      final String code = barcodes.first.rawValue ?? '';
      
      // Para o scanner para evitar múltiplas deteções
      _scannerController.stop();

      await _handleQRCode(code);
    }
  }

  Future<void> _handleQRCode(String code) async {
    try {
      // Tenta interpretar o código
      if (code.isNotEmpty) {
        String targetId = code;
        String targetType = 'product'; // Default
        
        // Verifica se é um código de produtor
        if (code.startsWith('producer:')) {
          targetId = code.substring(9);
          targetType = 'producer';
        } else if (code.startsWith('product:')) {
          targetId = code.substring(8);
          targetType = 'product';
        }

        if (targetType == 'producer') {
          // Navega para a página do produtor
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => ProducerDetailScreen(producerId: targetId),
              ),
            );
          }
        } else {
          // Busca o produto na base de dados
          final product = await _findProductById(targetId);
          
          if (product != null) {
            // Produto encontrado - navega para a página de detalhes
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(product: product),
                ),
              );
            }
          } else {
            // Produto não encontrado - mostra diálogo
            _showProductNotFoundDialog(code);
          }
        }
      } else {
        _showInvalidCodeDialog();
      }
    } catch (e) {
      _showErrorDialog('Erro ao processar código QR: $e');
    }
  }

  Future<ProductModel?> _findProductById(String productId) async {
    try {
      // Busca em todos os produtos usando collection group
      final allProducts = await _firestoreService.getAllProducts().first;
      
      // Procura o produto com o ID correspondente
      for (final product in allProducts) {
        if (product.id == productId) {
          return product;
        }
      }
      
      return null;
    } catch (e) {
      print('Erro ao buscar produto: $e');
      return null;
    }
  }

  void _showProductNotFoundDialog(String code) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Produto Não Encontrado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('O código QR foi lido com sucesso, mas o produto não foi encontrado.'),
              const SizedBox(height: 16),
              Text('Código: $code', style: const TextStyle(fontFamily: 'monospace')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartScanner();
              },
              child: const Text('Digitalizar Novamente'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Voltar'),
            ),
          ],
        );
      },
    );
  }

  void _showInvalidCodeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Código Inválido'),
          content: const Text('O código QR não pôde ser lido corretamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartScanner();
              },
              child: const Text('Tentar Novamente'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Voltar'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Erro'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartScanner();
              },
              child: const Text('Tentar Novamente'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Voltar'),
            ),
          ],
        );
      },
    );
  }

  void _restartScanner() {
    setState(() {
      _isProcessing = false;
    });
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leitor de QR Code'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
          ),
          // Sobreposição com instruções e guia visual
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
              child: Stack(
                children: [
                  // Área transparente para o scanner
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).primaryColor, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  // Instruções
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            color: Theme.of(context).primaryColor,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Aponte a câmara para o código QR do produto',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'O código será lido automaticamente',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Indicador de processamento
                  if (_isProcessing)
                    Container(
                      color: Colors.black.withOpacity(0.7),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 16),
                            Text(
                              'A processar código...',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 