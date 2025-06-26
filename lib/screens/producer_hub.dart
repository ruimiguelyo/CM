import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/screens/producer_orders_screen.dart';
import 'package:hellofarmer_app/screens/producer_reviews_screen.dart';
import 'package:hellofarmer_app/screens/product_management_screen.dart';

class ProducerHub extends StatefulWidget {
  const ProducerHub({super.key});

  @override
  State<ProducerHub> createState() => _ProducerHubState();
}

class _ProducerHubState extends State<ProducerHub> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  final List<String> _pageTitles = ['Encomendas', 'Avaliações', 'Meus Produtos'];

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    // As páginas são inicializadas aqui para garantir que o userId está disponível.
    // Estes widgets serão refatorados para não terem o seu próprio Scaffold/AppBar.
    _pages = [
      ProducerOrdersScreen(), // Este widget será modificado
      ProducerReviewsScreen(), // Este widget também
      ProductManagementScreen(userId: userId), // E este também
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        automaticallyImplyLeading: false, // Remove a seta de 'back'
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Encomendas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.reviews_outlined),
            activeIcon: Icon(Icons.reviews),
            label: 'Avaliações',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Produtos',
          ),
        ],
      ),
    );
  }
} 