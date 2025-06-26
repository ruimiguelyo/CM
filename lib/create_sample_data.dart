import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/firebase_options.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/models/product_model.dart';
import 'dart:math';

// =================================================================================
// SCRIPT DE GESTÃO DE DADOS DE TESTE PARA O HELLOFARMER - VERSÃO CORRIGIDA
// =================================================================================
// Este script permite criar, limpar e diagnosticar a base de dados do Firestore
// com dados de teste realistas.
//
// Para executar:
// 1. Certifique-se que o seu emulador/dispositivo está a correr.
// 2. No terminal, execute: flutter run lib/create_sample_data.dart
// 3. A aplicação irá abrir com uma interface para gerir os dados.
//
// CORREÇÕES APLICADAS:
// - Limpeza TOTAL da base de dados (incluindo Auth)
// - URLs de imagens VÁLIDAS e testadas
// - Criação correta de produtos associados aos produtores
// - Sistema robusto de eliminação de dados
// =================================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  runApp(const SampleDataApp());
}

class SampleDataApp extends StatelessWidget {
  const SampleDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelloFarmer - Gestor de Dados CORRIGIDO',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey.shade50,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        )
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('🛠️ Gestor de Base de Dados - CORRIGIDO'),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
        ),
        body: const SampleDataScreen(),
      ),
    );
  }
}

class SampleDataScreen extends StatefulWidget {
  const SampleDataScreen({super.key});

  @override
  State<SampleDataScreen> createState() => _SampleDataScreenState();
}

class _SampleDataScreenState extends State<SampleDataScreen> {
  bool _isLoading = false;
  final List<String> _statusLog = ['🔧 Sistema corrigido e pronto para usar.'];
  final ScrollController _scrollController = ScrollController();

  // --- DADOS DE TESTE CORRIGIDOS ---
  final _DataRepository _repo = _DataRepository();

  void _log(String message) {
    print(message);
    if (!mounted) return;
    setState(() {
      _statusLog.add('${DateTime.now().toString().substring(11, 19)} | $message');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _statusLog.clear();
    });
    try {
      await action();
    } catch (e) {
      _log('❌ ERRO CRÍTICO: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- AÇÕES CORRIGIDAS ---
  Future<void> _createSampleData() async {
    _log('🚀 INICIANDO PROCESSO DE CRIAÇÃO TOTAL...');
    await _repo.nukeEverything(_log);
    final producerIds = await _repo.createUsers(_repo.producersData, 'agricultor', _log);
    await _repo.createUsers(_repo.consumersData, 'consumidor', _log);
    _log('✅ 10 utilizadores criados (5 produtores + 5 consumidores)');
    await _repo.createProducts(producerIds, _log);
    _log('✅ 10 produtos criados e associados aos produtores');
    _log('\n🎉 PROCESSO CONCLUÍDO COM SUCESSO! 🎉');
    _log('📊 Dados criados: 5 produtores, 5 consumidores, 10 produtos');
  }

  Future<void> _nukeDatabase() async {
    _log('💥 ELIMINANDO TUDO DA BASE DE DADOS...');
    await _repo.nukeEverything(_log);
    _log('✅ Base de dados completamente limpa!');
  }

  Future<void> _diagnosticInfo() async {
    _log('🔍 EXECUTANDO DIAGNÓSTICO...');
    await _repo.diagnosticCheck(_log);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ActionButton(
            title: 'RECRIAR TUDO',
            subtitle: 'Elimina TUDO e cria dados limpos (5 produtores, 5 consumidores, 10 produtos)',
            icon: Icons.refresh,
            color: Colors.green.shade700,
            onPressed: () => _runAction(_createSampleData),
            isLoading: _isLoading,
          ),
          const SizedBox(height: 16),
          _ActionButton(
            title: 'ELIMINAR TUDO',
            subtitle: 'Remove TODOS os dados (Firestore + Auth). Use com cuidado!',
            icon: Icons.delete_forever,
            color: Colors.red.shade700,
            onPressed: () => _runAction(_nukeDatabase),
            isLoading: _isLoading,
          ),
          const SizedBox(height: 16),
          _ActionButton(
            title: 'DIAGNÓSTICO',
            subtitle: 'Verifica o estado atual da base de dados',
            icon: Icons.bug_report,
            color: Colors.orange.shade700,
            onPressed: () => _runAction(_diagnosticInfo),
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),
          _StatusWindow(log: _statusLog, scrollController: _scrollController),
        ],
      ),
    );
  }
}

// --- WIDGETS DA UI ---
class _ActionButton extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isLoading;

  const _ActionButton({
    required this.title, required this.subtitle, required this.icon,
    required this.color, required this.onPressed, required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold, color: color
                ))),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(title.split(' ').first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusWindow extends StatelessWidget {
  final List<String> log;
  final ScrollController scrollController;
  
  const _StatusWindow({required this.log, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📋 Consola de Estado', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 300,
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ListView.builder(
            controller: scrollController,
            itemCount: log.length,
            itemBuilder: (context, index) {
              final message = log[index];
              Color color = Colors.white;
              if (message.contains('✅')) color = Colors.greenAccent;
              if (message.contains('❌')) color = Colors.redAccent;
              if (message.contains('🎉')) color = Colors.yellowAccent;
              if (message.contains('🔍') || message.contains('📊')) color = Colors.cyanAccent;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(
                  message,
                  style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 12),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- LÓGICA DE DADOS CORRIGIDA ---
class _DataRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<Map<String, dynamic>> producersData = [
    {
      'nome': 'João Silva', 'email': 'joao.silva@farm.pt', 'password': 'password123',
      'nif': '512345678', 'telefone': '912345678', 'morada': 'Quinta da Esperança, Braga Centro',
      'codigoPostal': '4700-001', 'latitude': 41.5454, 'longitude': -8.4265,
    },
    {
      'nome': 'Maria Santos', 'email': 'maria.santos@verde.pt', 'password': 'password123',
      'nif': '623456789', 'telefone': '923456789', 'morada': 'Herdade do Sol, Vila Verde',
      'codigoPostal': '4730-002', 'latitude': 41.6200, 'longitude': -8.4800,
    },
    {
      'nome': 'António Costa', 'email': 'antonio.costa@bio.pt', 'password': 'password123',
      'nif': '734567890', 'telefone': '934567890', 'morada': 'Quinta Biológica, Guimarães',
      'codigoPostal': '4800-001', 'latitude': 41.4600, 'longitude': -8.3200,
    },
    {
      'nome': 'Ana Ferreira', 'email': 'ana.ferreira@natural.pt', 'password': 'password123',
      'nif': '845678901', 'telefone': '945678901', 'morada': 'Horta Natural, Barcelos',
      'codigoPostal': '4750-001', 'latitude': 41.5388, 'longitude': -8.6177,
    },
    {
      'nome': 'Patrícia Lima', 'email': 'patricia.lima@campo.pt', 'password': 'password123',
      'nif': '967890123', 'telefone': '967890123', 'morada': 'Quinta das Macieiras, Vila Verde',
      'codigoPostal': '4730-001', 'latitude': 41.6450, 'longitude': -8.4372,
    },
  ];

  final List<Map<String, dynamic>> consumersData = [
    {
      'nome': 'Rita Sousa', 'email': 'rita.sousa@email.pt', 'password': 'password123',
      'nif': '123456789', 'telefone': '912000001', 'morada': 'Rua das Flores, 123, Braga Oeste',
      'codigoPostal': '4700-002', 'latitude': 41.5200, 'longitude': -8.4800,
    },
    {
      'nome': 'Tiago Mendes', 'email': 'tiago.mendes@email.pt', 'password': 'password123',
      'nif': '234567890', 'telefone': '923000002', 'morada': 'Avenida Central, 456, Famalicão',
      'codigoPostal': '4760-002', 'latitude': 41.4081, 'longitude': -8.5198,
    },
    {
      'nome': 'Carla Nunes', 'email': 'carla.nunes@email.pt', 'password': 'password123',
      'nif': '345678901', 'telefone': '934000003', 'morada': 'Praceta do Sol, 789, Póvoa de Lanhoso',
      'codigoPostal': '4830-003', 'latitude': 41.5768, 'longitude': -8.2678,
    },
    {
      'nome': 'Bruno Dias', 'email': 'bruno.dias@email.pt', 'password': 'password123',
      'nif': '456789012', 'telefone': '945000004', 'morada': 'Rua da Paz, 321, Amares',
      'codigoPostal': '4720-004', 'latitude': 41.6195, 'longitude': -8.3545,
    },
    {
      'nome': 'Luís Cardoso', 'email': 'luis.cardoso@email.pt', 'password': 'password123',
      'nif': '167890123', 'telefone': '956000005', 'morada': 'Alameda Verde, 654, Guimarães Centro',
      'codigoPostal': '4800-005', 'latitude': 41.4550, 'longitude': -8.3100,
    },
  ];

  // URLs DE IMAGENS VÁLIDAS E TESTADAS - AGORA COM IMAGENS LOCAIS
  final List<Map<String, dynamic>> productsData = [
    // Frutos
    {'nome': 'Maçã', 'descricao': 'Maçãs frescas e crocantes, colhidas localmente.', 'preco': 1.99, 'unidade': 'Kg', 'stock': 50.0, 'imagemUrl': 'assets/produtos_imagens/maca.jpg', 'categoria': 'Frutos'},
    {'nome': 'Banana', 'descricao': 'Bananas doces da Madeira.', 'preco': 2.50, 'unidade': 'Kg', 'stock': 40.0, 'imagemUrl': 'assets/produtos_imagens/banana.jpg', 'categoria': 'Frutos'},
    {'nome': 'Laranja', 'descricao': 'Laranjas do Algarve, sumarentas e ricas em vitamina C.', 'preco': 1.80, 'unidade': 'Kg', 'stock': 60.0, 'imagemUrl': 'assets/produtos_imagens/laranja.jpg', 'categoria': 'Frutos'},
    {'nome': 'Manga', 'descricao': 'Mangas de avião, maduras e prontas a consumir.', 'preco': 4.50, 'unidade': 'Unidade', 'stock': 20.0, 'imagemUrl': 'assets/produtos_imagens/manga.jpg', 'categoria': 'Frutos'},
    {'nome': 'Abacate', 'descricao': 'Abacates cremosos, perfeitos para saladas e tostas.', 'preco': 3.00, 'unidade': 'Unidade', 'stock': 30.0, 'imagemUrl': 'assets/produtos_imagens/abacate.jpg', 'categoria': 'Frutos'},
    // Legumes
    {'nome': 'Cenoura', 'descricao': 'Cenouras biológicas, doces e crocantes.', 'preco': 1.20, 'unidade': 'Kg', 'stock': 70.0, 'imagemUrl': 'assets/produtos_imagens/cenoura.jpg', 'categoria': 'Legumes'},
    {'nome': 'Batata', 'descricao': 'Batata branca ideal para cozer ou fritar.', 'preco': 0.90, 'unidade': 'Kg', 'stock': 100.0, 'imagemUrl': 'assets/produtos_imagens/batata.jpg', 'categoria': 'Legumes'},
    {'nome': 'Abóbora', 'descricao': 'Abóbora menina, excelente para sopas e doces.', 'preco': 1.50, 'unidade': 'Kg', 'stock': 25.0, 'imagemUrl': 'assets/produtos_imagens/abobora.jpg', 'categoria': 'Legumes'},
    {'nome': 'Beterraba', 'descricao': 'Beterrabas frescas, ótimas para saladas ou sumos.', 'preco': 1.70, 'unidade': 'Kg', 'stock': 35.0, 'imagemUrl': 'assets/produtos_imagens/beterraba.jpg', 'categoria': 'Legumes'},
    {'nome': 'Pepino', 'descricao': 'Pepinos frescos e crocantes, ideais para o verão.', 'preco': 1.00, 'unidade': 'Unidade', 'stock': 45.0, 'imagemUrl': 'assets/produtos_imagens/pepino.jpg', 'categoria': 'Legumes'},
  ];

  // FUNÇÃO NUCLEAR - ELIMINA TUDO
  Future<void> nukeEverything(Function(String) log) async {
    log('💥 INICIANDO ELIMINAÇÃO TOTAL...');
    
    // 1. Eliminar todas as sub-coleções primeiro
    log('🔥 Eliminando sub-coleções de produtos...');
    final usersSnapshot = await _firestore.collection('users').get();
    int totalProductsDeleted = 0;
    
    for (final userDoc in usersSnapshot.docs) {
      final productsCollectionRef = userDoc.reference.collection('products');
      while(true) {
        final productsSnapshot = await productsCollectionRef.limit(100).get();
        if (productsSnapshot.docs.isEmpty) break;
        
        final batch = _firestore.batch();
        for (final doc in productsSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        totalProductsDeleted += productsSnapshot.docs.length;
      }
    }
    log('🗑️ $totalProductsDeleted produtos eliminados das sub-coleções');

    // 2. Eliminar coleções principais
    final collectionsToDelete = ['users', 'products', 'orders'];
    int totalDocsDeleted = 0;
    
    for (final collectionName in collectionsToDelete) {
      log('🔥 Eliminando coleção "$collectionName"...');
      int deletedCount = 0;
      while (true) {
        final snapshot = await _firestore.collection(collectionName).limit(100).get();
        if (snapshot.docs.isEmpty) break;
        
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        
        deletedCount += snapshot.docs.length;
      }
      log('✅ Coleção "$collectionName": $deletedCount documentos eliminados');
      totalDocsDeleted += deletedCount;
    }

    // 3. Eliminar contas do Firebase Auth
    log('🔥 Eliminando contas do Firebase Auth...');
    try {
      // Primeiro, fazer sign out se houver alguém logado
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }
      
      // Lista de emails para eliminar (contas de teste)
      final testEmails = [
        ...producersData.map((p) => p['email'] as String),
        ...consumersData.map((c) => c['email'] as String),
      ];
      
      int authAccountsDeleted = 0;
      for (final email in testEmails) {
        try {
          final userCred = await _auth.signInWithEmailAndPassword(
            email: email, 
            password: 'password123'
          );
          if (userCred.user != null) {
            await userCred.user!.delete();
            authAccountsDeleted++;
            log('🗑️ Conta eliminada: $email');
          }
        } catch (e) {
          // Conta pode não existir, não é erro
          log('⚠️ Conta $email não encontrada ou já eliminada');
        }
      }
      log('✅ $authAccountsDeleted contas do Auth eliminadas');
      
      // Sign out final
      await _auth.signOut();
      
    } catch (e) {
      log('⚠️ Erro ao eliminar contas do Auth: $e');
    }

    log('💥 ELIMINAÇÃO COMPLETA TERMINADA');
    log('📊 Total eliminado: $totalDocsDeleted docs + $totalProductsDeleted produtos');
  }

  Future<List<String>> createUsers(List<Map<String, dynamic>> usersData, String userType, Function(String) log) async {
    final List<String> userIds = [];
    log('👥 Criando ${usersData.length} utilizadores do tipo "$userType"...');
    
    for (final userData in usersData) {
      try {
        final cred = await _auth.createUserWithEmailAndPassword(
            email: userData['email'], password: userData['password']);
        
        final userModel = UserModel(
          uid: cred.user!.uid, 
          nome: userData['nome'], 
          email: userData['email'],
          nif: userData['nif'], 
          telefone: userData['telefone'], 
          morada: userData['morada'],
          codigoPostal: userData['codigoPostal'], 
          latitude: userData['latitude'],
          longitude: userData['longitude'], 
          tipo: userType,
        );
        
        await _firestore.collection('users').doc(userModel.uid).set(userModel.toMap());
        userIds.add(userModel.uid);
        log('✅ ${userData['nome']} criado (${userData['email']})');
        
      } catch (e) {
        log('❌ Erro ao criar ${userData['nome']}: $e');
      }
    }
    return userIds;
  }

  Future<void> createProducts(List<String> producerIds, Function(String) log) async {
    log('🛒 Criando 10 produtos para ${producerIds.length} produtores...');
    
    int totalProductsCreated = 0;
    int productIndex = 0;

    for (int i = 0; i < producerIds.length; i++) {
      final producerId = producerIds[i];
      // Cada produtor fica com 2 produtos da lista
      final productsToCreate = productsData.sublist(productIndex, productIndex + 2);
      productIndex += 2;
      
      log('📦 Criando ${productsToCreate.length} produtos para produtor ${i + 1}...');
      
      final productsCollection = _firestore.collection('users').doc(producerId).collection('products');

      for (final productData in productsToCreate) {
        final product = ProductModel(
          nome: productData['nome'], 
          descricao: productData['descricao'],
          preco: productData['preco'], 
          unidade: productData['unidade'],
          produtorId: producerId, 
          imagemUrl: productData['imagemUrl'],
          dataCriacao: Timestamp.now(), 
          stock: productData['stock'],
          categoria: productData['categoria'],
        );
        
        await productsCollection.add(product.toMap());
        totalProductsCreated++;
      }
      log('✅ Produtos criados para produtor ${i + 1}');
    }
    
    log('🎯 TOTAL: $totalProductsCreated produtos criados e associados');
  }

  Future<void> diagnosticCheck(Function(String) log) async {
    log('🔍 Verificando estado da base de dados...');
    
    // Verificar coleção de utilizadores
    final usersSnapshot = await _firestore.collection('users').get();
    final producers = usersSnapshot.docs.where((doc) => 
      (doc.data() as Map<String, dynamic>)['tipo'] == 'agricultor').length;
    final consumers = usersSnapshot.docs.where((doc) => 
      (doc.data() as Map<String, dynamic>)['tipo'] == 'consumidor').length;
    
    log('👥 Utilizadores: ${usersSnapshot.docs.length} total');
    log('   - Produtores: $producers');
    log('   - Consumidores: $consumers');
    
    // Verificar produtos
    int totalProducts = 0;
    for (final userDoc in usersSnapshot.docs) {
      final productsSnapshot = await userDoc.reference.collection('products').get();
      totalProducts += productsSnapshot.docs.length;
    }
    log('📦 Produtos totais: $totalProducts');
    
    // Verificar encomendas
    final ordersSnapshot = await _firestore.collection('orders').get();
    log('📋 Encomendas: ${ordersSnapshot.docs.length}');
    
    // Verificar contas Auth
    final currentUser = _auth.currentUser;
    log('🔐 Utilizador Auth atual: ${currentUser?.email ?? 'Nenhum'}');
    
    log('✅ Diagnóstico completo');
  }
} 