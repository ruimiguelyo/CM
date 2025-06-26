import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/screens/home_screen.dart';
import 'package:hellofarmer_app/screens/all_products_screen.dart';
import 'package:hellofarmer_app/screens/orders_screen.dart';
import 'package:hellofarmer_app/screens/favorites_screen.dart';
import 'package:hellofarmer_app/screens/profile_screen.dart';
import 'package:hellofarmer_app/widgets/custom_badge.dart';
import 'package:provider/provider.dart';
import 'package:hellofarmer_app/providers/cart_provider.dart';
import 'package:hellofarmer_app/screens/cart_screen.dart';
import 'package:hellofarmer_app/screens/favorites_hub_screen.dart';

class ConsumerHub extends StatefulWidget {
  const ConsumerHub({super.key});

  @override
  State<ConsumerHub> createState() => _ConsumerHubState();
}

class _ConsumerHubState extends State<ConsumerHub> {
  int _selectedIndex = 0;

  // As páginas que correspondem à barra de navegação.
  // A HomeScreen será refatorada para aceitar um parâmetro que controla a vista.
  static final List<Widget> _pages = <Widget>[
    const HomeScreen(isMapView: false), // Vista de Lista
    const HomeScreen(isMapView: true), // Vista de Mapa
    const AllProductsScreen(),
    const OrdersScreen(),
  ];

  final List<String> _pageTitles = ['Produtores', 'Mapa', 'Produtos', 'Minhas Encomendas'];

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
        automaticallyImplyLeading: false,
        actions: [
          // Ícone do carrinho de compras
          Consumer<CartProvider>(
            builder: (context, cart, child) => CustomBadge(
              value: cart.itemCount.toString(),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
            ),
          ),
          // Ícone dos favoritos
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Favoritos',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const FavoritesHubScreen(),
              ));
            },
          ),
          // Ícone do perfil
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ));
            },
          ),
          // Ícone de logout
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
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Produtores',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_basket_outlined),
            activeIcon: Icon(Icons.shopping_basket),
            label: 'Produtos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Encomendas',
          ),
        ],
      ),
    );
  }
} 