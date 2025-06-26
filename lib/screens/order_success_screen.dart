import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:hellofarmer_app/screens/consumer_hub.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/order_success.json',
                width: 250,
                height: 250,
                repeat: false,
              ),
              const SizedBox(height: 24),
              Text(
                'Encomenda Confirmada!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Obrigado pela sua compra. Pode acompanhar o estado da sua encomenda na secção "Minhas Encomendas".',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const ConsumerHub()),
                    (Route<dynamic> route) => false,
                  );
                },
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Voltar ao Início'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
} 