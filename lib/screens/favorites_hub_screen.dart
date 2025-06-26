import 'package:flutter/material.dart';
import 'package:hellofarmer_app/screens/favorites_screen.dart';
import 'package:hellofarmer_app/screens/favorite_producers_screen.dart';

class FavoritesHubScreen extends StatefulWidget {
  const FavoritesHubScreen({super.key});

  @override
  _FavoritesHubScreenState createState() => _FavoritesHubScreenState();
}

class _FavoritesHubScreenState extends State<FavoritesHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Os Meus Favoritos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_basket), text: 'Produtos'),
            Tab(icon: Icon(Icons.store), text: 'Produtores'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FavoritesScreen(),
          FavoriteProducersScreen(),
        ],
      ),
    );
  }
} 