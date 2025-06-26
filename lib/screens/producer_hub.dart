import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/screens/producer_orders_screen.dart';
import 'package:hellofarmer_app/screens/producer_reviews_screen.dart';
import 'package:hellofarmer_app/screens/product_management_screen.dart';
import 'package:hellofarmer_app/screens/auth_gate.dart';
import 'package:hellofarmer_app/screens/profile_screen.dart';
import 'package:hellofarmer_app/screens/producer_stats_screen.dart';

class ProducerHub extends StatefulWidget {
  const ProducerHub({super.key});

  @override
  State<ProducerHub> createState() => _ProducerHubState();
}

class _ProducerHubState extends State<ProducerHub> {
  int _selectedIndex = 0;
  PageController _pageController = PageController();

  List<Widget> _pages = [];
  final List<String> _pageTitles = ['Início', 'Encomendas', 'Meus Produtos', 'Avaliações'];

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;

    // Se o user não estiver logado, o AuthGate já deve ter tratado disto,
    // mas é uma boa prática de segurança verificar novamente.
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AuthGate()),
              (route) => false);
        }
      });
      return;
    }
    
    final userId = currentUser.uid;
    _pages = [
      const ProducerStatsScreen(), // Novo ecrã de estatísticas
      const ProducerOrdersScreen(),
      ProductManagementScreen(userId: userId),
      const ProducerReviewsScreen(),
    ];
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'O Meu Perfil',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('A terminar sessão...')),
              );
              try {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthGate()), 
                    (route) => false
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao sair: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Garante que todos os itens são visíveis
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Encomendas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Produtos',
          ),
           BottomNavigationBarItem(
            icon: Icon(Icons.reviews_outlined),
            activeIcon: Icon(Icons.reviews),
            label: 'Avaliações',
          ),
        ],
      ),
    );
  }
} 