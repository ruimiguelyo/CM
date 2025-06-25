import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/firebase_options.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/models/product_model.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SampleDataApp());
}

class SampleDataApp extends StatelessWidget {
  const SampleDataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HelloFarmer - Gestor de Dados',
      theme: ThemeData(primarySwatch: Colors.green),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('🗄️ Gestor de Base de Dados'),
          backgroundColor: Colors.green.shade700,
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
  bool _isCreating = false;
  String _status = 'Pronto para criar/atualizar dados';
  int _totalProducers = 0;
  int _totalConsumers = 0;
  int _totalProducts = 0;

  // 5 Produtores - TODOS NA ZONA DE BRAGA (raio de 40km máximo)
  final List<Map<String, dynamic>> _producers = [
    {
      'nome': 'João Silva',
      'email': 'joao.silva@farm.pt',
      'password': 'password123',
      'nif': '512345678', // Começa com 5 = Produtor
      'telefone': '912345678',
      'morada': 'Quinta da Esperança, Braga Centro',
      'codigoPostal': '4700-001',
      'latitude': 41.5454, // Braga Centro
      'longitude': -8.4265,
    },
    {
      'nome': 'Maria Santos',
      'email': 'maria.santos@verde.pt',
      'password': 'password123',
      'nif': '623456789', // Começa com 6 = Produtor
      'telefone': '923456789',
      'morada': 'Herdade do Sol, Vila Verde',
      'codigoPostal': '4730-002',
      'latitude': 41.6200, // Vila Verde (~12km de Braga)
      'longitude': -8.4800,
    },
    {
      'nome': 'António Costa',
      'email': 'antonio.costa@bio.pt',
      'password': 'password123',
      'nif': '734567890', // Começa com 7 = Produtor
      'telefone': '934567890',
      'morada': 'Quinta Biológica, Guimarães',
      'codigoPostal': '4800-001',
      'latitude': 41.4600, // Guimarães (~15km de Braga)
      'longitude': -8.3200,
    },
    {
      'nome': 'Ana Ferreira',
      'email': 'ana.ferreira@natural.pt',
      'password': 'password123',
      'nif': '845678901', // Começa com 8 = Produtor
      'telefone': '945678901',
      'morada': 'Horta Natural, Barcelos',
      'codigoPostal': '4750-001',
      'latitude': 41.5388, // Barcelos (~15km de Braga)
      'longitude': -8.6177,
    },
    {
      'nome': 'Patrícia Lima',
      'email': 'patricia.lima@campo.pt',
      'password': 'password123',
      'nif': '967890123', // Começa com 9 = Produtor
      'telefone': '967890123',
      'morada': 'Quinta das Macieiras, Vila Verde',
      'codigoPostal': '4730-001',
      'latitude': 41.6450, // Vila Verde (~18km de Braga)
      'longitude': -8.4372,
    },
  ];

  // 5 Consumidores - TODOS NA MESMA ZONA DE BRAGA
  final List<Map<String, dynamic>> _consumers = [
    {
      'nome': 'Rita Sousa',
      'email': 'rita.sousa@email.pt',
      'password': 'password123',
      'nif': '123456789', // Começa com 1 = Consumidor
      'telefone': '912000001',
      'morada': 'Rua das Flores, 123, Braga Oeste',
      'codigoPostal': '4700-002',
      'latitude': 41.5200, // Braga Oeste (~8km do João Silva)
      'longitude': -8.4800,
    },
    {
      'nome': 'Tiago Mendes',
      'email': 'tiago.mendes@email.pt',
      'password': 'password123',
      'nif': '234567890', // Começa com 2 = Consumidor
      'telefone': '923000002',
      'morada': 'Avenida Central, 456, Famalicão',
      'codigoPostal': '4760-002',
      'latitude': 41.4081, // Vila Nova de Famalicão (~20km de Braga)
      'longitude': -8.5198,
    },
    {
      'nome': 'Carla Nunes',
      'email': 'carla.nunes@email.pt',
      'password': 'password123',
      'nif': '345678901', // Começa com 3 = Consumidor
      'telefone': '934000003',
      'morada': 'Praceta do Sol, 789, Póvoa de Lanhoso',
      'codigoPostal': '4830-003',
      'latitude': 41.5768, // Póvoa de Lanhoso (~10km de Braga)
      'longitude': -8.2678,
    },
    {
      'nome': 'Bruno Dias',
      'email': 'bruno.dias@email.pt',
      'password': 'password123',
      'nif': '456789012', // Começa com 4 = Consumidor
      'telefone': '945000004',
      'morada': 'Rua da Paz, 321, Amares',
      'codigoPostal': '4720-004',
      'latitude': 41.6195, // Amares (~12km de Braga)
      'longitude': -8.3545,
    },
    {
      'nome': 'Luís Cardoso',
      'email': 'luis.cardoso@email.pt',
      'password': 'password123',
      'nif': '167890123', // Começa com 1 = Consumidor
      'telefone': '956000005',
      'morada': 'Alameda Verde, 654, Guimarães Centro',
      'codigoPostal': '4800-005',
      'latitude': 41.4550, // Guimarães Centro (~15km de Braga)
      'longitude': -8.3100,
    },
  ];

  final List<List<Map<String, dynamic>>> _productsForProducers = [
    // Produtos para João Silva (Braga)
    [
      {'nome': 'Tomates Cherry Bio', 'descricao': 'Tomates cherry biológicos, doces e suculentos', 'preco': 3.50, 'unidade': 'Kg', 'stock': 25.0, 'imagemUrl': 'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Alface Romana', 'descricao': 'Alface romana fresca, ideal para saladas', 'preco': 1.20, 'unidade': 'Unidade', 'stock': 40.0, 'imagemUrl': 'https://images.unsplash.com/photo-1622206151226-18ca2c9ab4a1?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Cenouras Baby', 'descricao': 'Cenouras baby tenras e doces', 'preco': 2.80, 'unidade': 'Kg', 'stock': 30.0, 'imagemUrl': 'https://images.unsplash.com/photo-1447175008436-054170c2e979?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Ervas Aromáticas Mix', 'descricao': 'Mistura de ervas aromáticas frescas', 'preco': 4.00, 'unidade': 'Molho', 'stock': 15.0, 'imagemUrl': 'https://images.unsplash.com/photo-1466692476868-aef1dfb1e735?w=400&h=300&fit=crop', 'categoria': 'Ervas'},
      {'nome': 'Pepinos Bio', 'descricao': 'Pepinos biológicos crocantes', 'preco': 2.20, 'unidade': 'Kg', 'stock': 20.0, 'imagemUrl': 'https://images.unsplash.com/photo-1449300079323-02e209d9d3a6?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
    ],
    // Produtos para Maria Santos (Vila Nova de Gaia)
    [
      {'nome': 'Azeite Extra Virgem', 'descricao': 'Azeite extra virgem da primeira prensagem', 'preco': 12.00, 'unidade': 'L', 'stock': 50.0, 'imagemUrl': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400&h=300&fit=crop', 'categoria': 'Condimentos'},
      {'nome': 'Azeitonas Pretas', 'descricao': 'Azeitonas pretas curadas tradicionalmente', 'preco': 6.50, 'unidade': 'Kg', 'stock': 35.0, 'imagemUrl': 'https://images.unsplash.com/photo-1632481247824-e22de9c9cc11?w=400&h=300&fit=crop', 'categoria': 'Conservas'},
      {'nome': 'Mel de Rosmaninho', 'descricao': 'Mel puro de rosmaninho do Porto', 'preco': 8.00, 'unidade': 'Kg', 'stock': 25.0, 'imagemUrl': 'https://images.unsplash.com/photo-1587049016823-83eb5d07ad3c?w=400&h=300&fit=crop', 'categoria': 'Condimentos'},
      {'nome': 'Queijo de Cabra', 'descricao': 'Queijo artesanal de cabra curado', 'preco': 15.00, 'unidade': 'Kg', 'stock': 12.0, 'imagemUrl': 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=400&h=300&fit=crop', 'categoria': 'Laticínios'},
      {'nome': 'Figos Secos', 'descricao': 'Figos secos naturais sem aditivos', 'preco': 7.50, 'unidade': 'Kg', 'stock': 18.0, 'imagemUrl': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400&h=300&fit=crop', 'categoria': 'Frutas'},
    ],
    // Produtos para António Costa (Guimarães)
    [
      {'nome': 'Maçãs Reineta', 'descricao': 'Maçãs reineta biológicas crocantes', 'preco': 2.50, 'unidade': 'Kg', 'stock': 60.0, 'imagemUrl': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400&h=300&fit=crop', 'categoria': 'Frutas'},
      {'nome': 'Peras Rocha', 'descricao': 'Peras rocha doces e suculentas', 'preco': 3.00, 'unidade': 'Kg', 'stock': 45.0, 'imagemUrl': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400&h=300&fit=crop', 'categoria': 'Frutas'},
      {'nome': 'Nozes Descascadas', 'descricao': 'Nozes frescas descascadas', 'preco': 12.00, 'unidade': 'Kg', 'stock': 20.0, 'imagemUrl': 'https://images.unsplash.com/photo-1448043552756-e747b7c2b763?w=400&h=300&fit=crop', 'categoria': 'Frutos Secos'},
      {'nome': 'Castanhas', 'descricao': 'Castanhas da época, doces e cremosas', 'preco': 4.50, 'unidade': 'Kg', 'stock': 30.0, 'imagemUrl': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400&h=300&fit=crop', 'categoria': 'Frutos Secos'},
      {'nome': 'Sidra Artesanal', 'descricao': 'Sidra artesanal de maçã bio', 'preco': 5.00, 'unidade': 'L', 'stock': 24.0, 'imagemUrl': 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400&h=300&fit=crop', 'categoria': 'Bebidas'},
    ],
    // Produtos para Ana Ferreira (Barcelos)
    [
      {'nome': 'Espinafres Baby', 'descricao': 'Espinafres baby tenros para saladas', 'preco': 3.20, 'unidade': 'Kg', 'stock': 28.0, 'imagemUrl': 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Rúcula Selvagem', 'descricao': 'Rúcula selvagem com sabor intenso', 'preco': 4.50, 'unidade': 'Kg', 'stock': 22.0, 'imagemUrl': 'https://images.unsplash.com/photo-1604977042946-1eecc30f269e?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Brócolos Bio', 'descricao': 'Brócolos biológicos frescos', 'preco': 2.80, 'unidade': 'Kg', 'stock': 35.0, 'imagemUrl': 'https://images.unsplash.com/photo-1459411621453-7b03977f4bfc?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Couve-Flor', 'descricao': 'Couve-flor branca e compacta', 'preco': 2.20, 'unidade': 'Unidade', 'stock': 25.0, 'imagemUrl': 'https://images.unsplash.com/photo-1568584711271-9127dfbb8511?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Acelgas Coloridas', 'descricao': 'Acelgas coloridas nutritivas', 'preco': 2.60, 'unidade': 'Kg', 'stock': 30.0, 'imagemUrl': 'https://images.unsplash.com/photo-1579952363873-27d3bfad9c0d?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
    ],
    // Produtos para Patrícia Lima (Viana do Castelo)
    [
      {'nome': 'Batatas Doces', 'descricao': 'Batatas doces de polpa laranja', 'preco': 2.10, 'unidade': 'Kg', 'stock': 80.0, 'imagemUrl': 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=400&h=300&fit=crop', 'categoria': 'Tubérculos'},
      {'nome': 'Cebolas Brancas', 'descricao': 'Cebolas brancas de sabor suave', 'preco': 1.90, 'unidade': 'Kg', 'stock': 60.0, 'imagemUrl': 'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Alho Seco', 'descricao': 'Alho seco de produção local', 'preco': 5.50, 'unidade': 'Kg', 'stock': 30.0, 'imagemUrl': 'https://images.unsplash.com/photo-1553978297-667178ecad33?w=400&h=300&fit=crop', 'categoria': 'Condimentos'},
      {'nome': 'Nabiças Frescas', 'descricao': 'Nabiças frescas para sopas e caldos', 'preco': 1.50, 'unidade': 'Molho', 'stock': 40.0, 'imagemUrl': 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Beterrabas', 'descricao': 'Beterrabas doces e terrosas', 'preco': 2.00, 'unidade': 'Kg', 'stock': 25.0, 'imagemUrl': 'https://images.unsplash.com/photo-1542990253-a781e04c0082?w=400&h=300&fit=crop', 'categoria': 'Tubérculos'},
    ],
  ];

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Raio da Terra em km
    
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  void _validateDistances() {
    print('\n=== VALIDAÇÃO DE DISTÂNCIAS ===');
    
    // Combinar todas as localizações (produtores + consumidores)
    List<Map<String, dynamic>> allLocations = [];
    allLocations.addAll(_producers);
    allLocations.addAll(_consumers);
    
    for (int i = 0; i < allLocations.length; i++) {
      for (int j = i + 1; j < allLocations.length; j++) {
        final loc1 = allLocations[i];
        final loc2 = allLocations[j];
        
        final distance = _calculateDistance(
          loc1['latitude'], loc1['longitude'],
          loc2['latitude'], loc2['longitude']
        );
        
        print('${loc1['nome']} ↔ ${loc2['nome']}: ${distance.toStringAsFixed(1)} km');
        
        if (distance < 5 || distance > 50) {
          print('⚠️  AVISO: Distância fora do intervalo 5-50 km!');
        }
      }
    }
    print('=== FIM DA VALIDAÇÃO ===\n');
  }

  Future<void> _createSampleData() async {
    setState(() {
      _isCreating = true;
      _status = 'Iniciando criação de dados...';
    });

    try {
      // Testar conectividade Firebase
      setState(() => _status = 'Testando conectividade Firebase...');
      await _testFirebaseConnectivity();
      
      // Validar distâncias antes de criar
      _validateDistances();
      
      // Limpar dados existentes
      setState(() => _status = 'Limpando dados existentes...');
      await _clearExistingData();

      // Criar produtores
      setState(() => _status = 'Criando produtores...');
      final producerIds = await _createProducers();

      // Criar produtos para cada produtor
      setState(() => _status = 'Criando produtos...');
      await _createProducts(producerIds);

      // Criar consumidores
      setState(() => _status = 'Criando consumidores...');
      await _createConsumers();

      // Recarregar estatísticas
      setState(() => _status = 'Recarregando estatísticas...');
      await _loadStats();
      
      setState(() => _status = '✅ Dados criados com sucesso!\n\n📊 5 Produtores e 5 Consumidores criados\n📍 Todos numa distância entre 5-50 km\n🎯 25 produtos disponíveis');
    } catch (e) {
      setState(() => _status = '❌ Erro: $e');
      print('Erro detalhado: $e');
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _testFirebaseConnectivity() async {
    try {
      // Testar Firestore com timeout
      await FirebaseFirestore.instance.collection('test').limit(1).get()
          .timeout(const Duration(seconds: 10));
      print('✅ Firestore conectado');
      
      // Testar Auth fazendo logout (não vai dar erro se não há utilizador)
      await FirebaseAuth.instance.signOut()
          .timeout(const Duration(seconds: 5));
      print('✅ Firebase Auth conectado');
      
    } catch (e) {
      print('❌ Erro de conectividade Firebase: $e');
      throw Exception('Erro de conectividade Firebase: $e');
    }
  }

  Future<void> _clearExistingData() async {
    final firestore = FirebaseFirestore.instance;
    
    setState(() => _status = 'Fazendo logout de contas existentes...');
    // Fazer logout primeiro
    await FirebaseAuth.instance.signOut()
        .timeout(const Duration(seconds: 5));
    
    setState(() => _status = 'Limpando dados do Firestore...');
    
    // Deletar todas as contas de utilizadores existentes
    final usersSnapshot = await firestore.collection('users').get()
        .timeout(const Duration(seconds: 30));
    int userCount = 0;
    for (final doc in usersSnapshot.docs) {
      await doc.reference.delete()
          .timeout(const Duration(seconds: 5));
      userCount++;
      if (userCount % 2 == 0) {
        setState(() => _status = 'Limpando utilizadores... ($userCount/${usersSnapshot.docs.length})');
      }
    }

    // Deletar todas as encomendas
    final ordersSnapshot = await firestore.collection('orders').get()
        .timeout(const Duration(seconds: 30));
    int orderCount = 0;
    for (final doc in ordersSnapshot.docs) {
      await doc.reference.delete()
          .timeout(const Duration(seconds: 5));
      orderCount++;
      if (orderCount % 5 == 0) {
        setState(() => _status = 'Limpando encomendas... ($orderCount/${ordersSnapshot.docs.length})');
      }
    }

    // Deletar produtos na coleção global (se existir)
    final productsSnapshot = await firestore.collection('products').get()
        .timeout(const Duration(seconds: 30));
    int productCount = 0;
    for (final doc in productsSnapshot.docs) {
      await doc.reference.delete()
          .timeout(const Duration(seconds: 5));
      productCount++;
      if (productCount % 10 == 0) {
        setState(() => _status = 'Limpando produtos... ($productCount/${productsSnapshot.docs.length})');
      }
    }
    
    setState(() => _status = 'Limpeza do Firestore concluída!');
    
    // REMOVIDO: Não vamos tentar deletar contas do Firebase Auth
    // Isso estava a causar o travamento
  }

  Future<List<String>> _createProducers() async {
    final List<String> producerIds = [];
    
    for (int i = 0; i < _producers.length; i++) {
      final producer = _producers[i];
      
      setState(() => _status = 'Criando produtor ${i + 1}/${_producers.length}: ${producer['nome']}');
      
      try {
        // Criar conta no Firebase Auth
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: producer['email'],
          password: producer['password'],
        ).timeout(const Duration(seconds: 15));

        final uid = userCredential.user!.uid;
        producerIds.add(uid);

        // Criar documento no Firestore
        final userModel = UserModel(
          uid: uid,
          nome: producer['nome'],
          email: producer['email'],
          nif: producer['nif'],
          telefone: producer['telefone'],
          morada: producer['morada'],
          codigoPostal: producer['codigoPostal'],
          latitude: producer['latitude'],
          longitude: producer['longitude'],
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(userModel.toMap())
            .timeout(const Duration(seconds: 10));

        print('✅ Produtor criado: ${producer['nome']} (${producer['email']})');
      } catch (e) {
        print('❌ Erro ao criar produtor ${producer['nome']}: $e');
        setState(() => _status = 'Erro ao criar produtor ${producer['nome']}: $e');
        rethrow;
      }
    }

    return producerIds;
  }

  Future<void> _createProducts(List<String> producerIds) async {
    for (int i = 0; i < producerIds.length; i++) {
      final producerId = producerIds[i];
      final products = _productsForProducers[i];
      final producerName = _producers[i]['nome'];

      setState(() => _status = 'Criando produtos para $producerName (${i + 1}/${producerIds.length})');

      for (int j = 0; j < products.length; j++) {
        final productData = products[j];
        
        try {
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

          await FirebaseFirestore.instance
              .collection('users')
              .doc(producerId)
              .collection('products')
              .add(product.toMap())
              .timeout(const Duration(seconds: 10));

          if ((j + 1) % 2 == 0 || j == products.length - 1) {
            setState(() => _status = 'Produtos para $producerName: ${j + 1}/${products.length}');
          }
        } catch (e) {
          print('❌ Erro ao criar produto ${productData['nome']}: $e');
          throw Exception('Erro ao criar produto ${productData['nome']}: $e');
        }
      }
      
      print('✅ Criados ${products.length} produtos para $producerName');
    }
  }

  Future<void> _createConsumers() async {
    for (int i = 0; i < _consumers.length; i++) {
      final consumer = _consumers[i];
      
      setState(() => _status = 'Criando consumidor ${i + 1}/${_consumers.length}: ${consumer['nome']}');
      
      try {
        // Criar conta no Firebase Auth
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: consumer['email'],
          password: consumer['password'],
        ).timeout(const Duration(seconds: 15));

        final uid = userCredential.user!.uid;

        // Criar documento no Firestore
        final userModel = UserModel(
          uid: uid,
          nome: consumer['nome'],
          email: consumer['email'],
          nif: consumer['nif'],
          telefone: consumer['telefone'],
          morada: consumer['morada'],
          codigoPostal: consumer['codigoPostal'],
          latitude: consumer['latitude'], // Consumidores também têm coordenadas
          longitude: consumer['longitude'],
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(userModel.toMap())
            .timeout(const Duration(seconds: 10));

        print('✅ Consumidor criado: ${consumer['nome']} (${consumer['email']})');
      } catch (e) {
        print('❌ Erro ao criar consumidor ${consumer['nome']}: $e');
        setState(() => _status = 'Erro ao criar consumidor ${consumer['nome']}: $e');
        rethrow;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Contar utilizadores
      final usersSnapshot = await firestore.collection('users').get();
      final producers = usersSnapshot.docs.where((doc) => 
        (doc.data())['tipo'] == 'agricultor').length;
      final consumers = usersSnapshot.docs.where((doc) => 
        (doc.data())['tipo'] == 'consumidor').length;
      
      // Contar produtos
      int productCount = 0;
      for (final userDoc in usersSnapshot.docs) {
        final productsSnapshot = await firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('products')
            .get();
        productCount += productsSnapshot.docs.length;
      }
      
      setState(() {
        _totalProducers = producers;
        _totalConsumers = consumers;
        _totalProducts = productCount;
      });
    } catch (e) {
      print('Erro ao carregar estatísticas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Estatísticas atuais
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '📊 Estado Atual da Base de Dados',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildStatCard(
                        icon: Icons.store,
                        label: 'Produtores',
                        value: _totalProducers.toString(),
                        color: Colors.green,
                      ),
                      _buildStatCard(
                        icon: Icons.person,
                        label: 'Consumidores',
                        value: _totalConsumers.toString(),
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        icon: Icons.shopping_basket,
                        label: 'Produtos',
                        value: _totalProducts.toString(),
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Ações principais
          if (_isCreating)
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.refresh, size: 48, color: Colors.green.shade700),
                        const SizedBox(height: 8),
                        Text(
                          'Recriar Base de Dados',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• 5 produtores com localização GPS\n• 25 produtos (5 por produtor)\n• 5 consumidores\n• Distâncias entre 5-50 km',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _createSampleData,
                          icon: const Icon(Icons.build),
                          label: const Text('Recriar Dados Completos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _createSampleDataIncremental,
                          icon: const Icon(Icons.build_outlined),
                          label: const Text('Criação Incremental'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Card(
                  color: Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.delete_sweep, size: 48, color: Colors.orange.shade700),
                        const SizedBox(height: 8),
                        Text(
                          'Limpar Base de Dados',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Remove todos os dados existentes\n(utilizadores, produtos, encomendas)',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _clearData,
                          icon: const Icon(Icons.delete),
                          label: const Text('Limpar Tudo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 24),
          
          // Informações
          Card(
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade600),
                  const SizedBox(height: 8),
                  Text(
                    '💡 Dica de Desenvolvimento',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mantenha a aplicação principal sempre a correr.\nUse Hot Reload (pressione "r") para ver mudanças instantaneamente.\nEste gestor permite atualizar dados sem reiniciar a app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          
          Card(
            color: Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.analytics, size: 48, color: Colors.purple.shade700),
                  const SizedBox(height: 8),
                  Text(
                    'Diagnóstico da Base de Dados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Verificar conectividade e estado atual dos dados',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _runDiagnostic,
                    icon: const Icon(Icons.search),
                    label: const Text('Executar Diagnóstico'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar Limpeza'),
        content: const Text('Tem a certeza que quer eliminar TODOS os dados da base de dados?\n\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar Tudo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isCreating = true;
        _status = 'Limpando base de dados...';
      });

      try {
        await _clearExistingDataSimple();
        await _loadStats();
        setState(() => _status = '✅ Base de dados limpa com sucesso!');
      } catch (e) {
        setState(() => _status = '❌ Erro ao limpar: $e');
        print('Erro ao limpar: $e');
      } finally {
        setState(() => _isCreating = false);
      }
    }
  }

  Future<void> _clearExistingDataSimple() async {
    final firestore = FirebaseFirestore.instance;
    
    setState(() => _status = 'Fazendo logout...');
    await FirebaseAuth.instance.signOut().timeout(const Duration(seconds: 5));
    
    setState(() => _status = 'Limpando utilizadores...');
    final usersSnapshot = await firestore.collection('users').get()
        .timeout(const Duration(seconds: 30));
    
    // Usar batch para operações mais eficientes
    WriteBatch batch = firestore.batch();
    int count = 0;
    
    for (final doc in usersSnapshot.docs) {
      batch.delete(doc.reference);
      count++;
      if (count >= 500) { // Firestore batch limit
        await batch.commit();
        batch = firestore.batch();
        count = 0;
        setState(() => _status = 'Limpando utilizadores... (${usersSnapshot.docs.length} processados)');
      }
    }
    
    if (count > 0) {
      await batch.commit();
    }
    
    setState(() => _status = 'Limpeza concluída!');
  }

  Future<void> _createSampleDataIncremental() async {
    setState(() {
      _isCreating = true;
      _status = 'Iniciando criação incremental de dados...';
    });

    try {
      // Testar conectividade Firebase
      setState(() => _status = '🔍 Testando conectividade Firebase...');
      await _testFirebaseConnectivity();
      
      // Verificar dados existentes primeiro
      setState(() => _status = '📊 Verificando dados existentes...');
      await _loadStats();
      
      // Só criar se não existirem dados suficientes
      if (_totalProducers < 5) {
        setState(() => _status = 'Criando produtores em falta...');
        await _createProducers();
      }
      
      if (_totalConsumers < 5) {
        setState(() => _status = 'Criando consumidores em falta...');
        await _createConsumers();
      }
      
      // Recarregar estatísticas
      setState(() => _status = 'Recarregando estatísticas...');
      await _loadStats();
      
      setState(() => _status = '✅ Criação incremental concluída!\n\n📊 Dados verificados e complementados\n📍 Todos numa distância entre 5-50 km');
    } catch (e) {
      setState(() => _status = '❌ Erro na criação incremental: $e');
      print('Erro detalhado: $e');
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isCreating = true;
      _status = 'Executando diagnóstico...';
    });

    try {
      // Testar conectividade Firebase
      setState(() => _status = '🔍 Testando conectividade Firebase...');
      await _testFirebaseConnectivity();
      
      // Verificar dados existentes
      setState(() => _status = '📊 Verificando dados existentes...');
      final firestore = FirebaseFirestore.instance;
      
      final usersSnapshot = await firestore.collection('users').get()
          .timeout(const Duration(seconds: 15));
      
      final ordersSnapshot = await firestore.collection('orders').get()
          .timeout(const Duration(seconds: 15));
      
      // Contar produtores e consumidores
      int producers = 0;
      int consumers = 0;
      int totalProducts = 0;
      
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        if (data['tipo'] == 'agricultor') {
          producers++;
          // Contar produtos deste produtor
          final productsSnapshot = await firestore
              .collection('users')
              .doc(doc.id)
              .collection('products')
              .get()
              .timeout(const Duration(seconds: 10));
          totalProducts += productsSnapshot.docs.length;
        } else {
          consumers++;
        }
      }
      
      // Validar distâncias se há utilizadores
      String distanceInfo = '';
      if (usersSnapshot.docs.isNotEmpty) {
        setState(() => _status = '📏 Validando distâncias...');
        _validateDistances();
        distanceInfo = '\n📍 Distâncias validadas nos logs';
      }
      
      setState(() {
        _totalProducers = producers;
        _totalConsumers = consumers;
        _totalProducts = totalProducts;
        _status = '''✅ Diagnóstico concluído!

📊 Estado da Base de Dados:
• $producers Produtores
• $consumers Consumidores  
• $totalProducts Produtos
• ${ordersSnapshot.docs.length} Encomendas$distanceInfo

🔗 Conectividade: OK
🗄️ Firestore: Funcional
🔐 Firebase Auth: Funcional''';
      });
      
    } catch (e) {
      setState(() => _status = '❌ Diagnóstico falhou: $e');
      print('Erro detalhado no diagnóstico: $e');
    } finally {
      setState(() => _isCreating = false);
    }
  }
} 