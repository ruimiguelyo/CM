import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/firebase_options.dart';
import 'package:hellofarmer_app/models/user_model.dart';
import 'package:hellofarmer_app/models/product_model.dart';

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
      home: Scaffold(
        appBar: AppBar(title: const Text('Criar Dados de Exemplo')),
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
  String _status = '';

  final List<Map<String, dynamic>> _producers = [
    {
      'nome': 'João Silva',
      'email': 'joao.silva@farm.pt',
      'password': 'password123',
      'nif': '512345678',
      'telefone': '912345678',
      'morada': 'Quinta da Esperança, Braga',
      'codigoPostal': '4700-001',
      'latitude': 41.5454,
      'longitude': -8.4265,
    },
    {
      'nome': 'Maria Santos',
      'email': 'maria.santos@verde.pt',
      'password': 'password123',
      'nif': '623456789',
      'telefone': '923456789',
      'morada': 'Herdade do Sol, Évora',
      'codigoPostal': '7000-001',
      'latitude': 38.5664,
      'longitude': -7.9138,
    },
    {
      'nome': 'António Costa',
      'email': 'antonio.costa@bio.pt',
      'password': 'password123',
      'nif': '734567890',
      'telefone': '934567890',
      'morada': 'Quinta Biológica, Viseu',
      'codigoPostal': '3500-001',
      'latitude': 40.6566,
      'longitude': -7.9139,
    },
    {
      'nome': 'Ana Ferreira',
      'email': 'ana.ferreira@natural.pt',
      'password': 'password123',
      'nif': '845678901',
      'telefone': '945678901',
      'morada': 'Horta Natural, Coimbra',
      'codigoPostal': '3000-001',
      'latitude': 40.2033,
      'longitude': -8.4103,
    },
    {
      'nome': 'Carlos Oliveira',
      'email': 'carlos.oliveira@campo.pt',
      'password': 'password123',
      'nif': '956789012',
      'telefone': '956789012',
      'morada': 'Campos do Norte, Viana do Castelo',
      'codigoPostal': '4900-001',
      'latitude': 41.6938,
      'longitude': -8.8342,
    },
    {
      'nome': 'Isabel Rodrigues',
      'email': 'isabel.rodrigues@terra.pt',
      'password': 'password123',
      'nif': '567890123',
      'telefone': '967890123',
      'morada': 'Terra Fértil, Santarém',
      'codigoPostal': '2000-001',
      'latitude': 39.2369,
      'longitude': -8.6868,
    },
    {
      'nome': 'Pedro Almeida',
      'email': 'pedro.almeida@fresco.pt',
      'password': 'password123',
      'nif': '678901234',
      'telefone': '978901234',
      'morada': 'Quinta Fresca, Aveiro',
      'codigoPostal': '3800-001',
      'latitude': 40.6412,
      'longitude': -8.6534,
    },
    {
      'nome': 'Luísa Martins',
      'email': 'luisa.martins@organico.pt',
      'password': 'password123',
      'nif': '789012345',
      'telefone': '989012345',
      'morada': 'Orgânico da Serra, Guarda',
      'codigoPostal': '6300-001',
      'latitude': 40.5364,
      'longitude': -7.2683,
    },
    {
      'nome': 'Miguel Pereira',
      'email': 'miguel.pereira@sustentavel.pt',
      'password': 'password123',
      'nif': '890123456',
      'telefone': '990123456',
      'morada': 'Sustentável & Cia, Leiria',
      'codigoPostal': '2400-001',
      'latitude': 39.7436,
      'longitude': -8.8071,
    },
    {
      'nome': 'Sofia Gomes',
      'email': 'sofia.gomes@tradicional.pt',
      'password': 'password123',
      'nif': '901234567',
      'telefone': '901234567',
      'morada': 'Tradicional do Minho, Porto',
      'codigoPostal': '4000-001',
      'latitude': 41.1579,
      'longitude': -8.6291,
    },
  ];

  final List<Map<String, dynamic>> _consumers = [
    {
      'nome': 'Rita Sousa',
      'email': 'rita.sousa@email.pt',
      'password': 'password123',
      'nif': '123456789',
      'telefone': '912000001',
      'morada': 'Rua das Flores, 123, Lisboa',
      'codigoPostal': '1000-001',
    },
    {
      'nome': 'Tiago Mendes',
      'email': 'tiago.mendes@email.pt',
      'password': 'password123',
      'nif': '234567890',
      'telefone': '923000002',
      'morada': 'Avenida Central, 456, Porto',
      'codigoPostal': '4000-002',
    },
    {
      'nome': 'Carla Nunes',
      'email': 'carla.nunes@email.pt',
      'password': 'password123',
      'nif': '345678901',
      'telefone': '934000003',
      'morada': 'Praceta do Sol, 789, Faro',
      'codigoPostal': '8000-003',
    },
    {
      'nome': 'Bruno Dias',
      'email': 'bruno.dias@email.pt',
      'password': 'password123',
      'nif': '456789012',
      'telefone': '945000004',
      'morada': 'Rua da Paz, 321, Coimbra',
      'codigoPostal': '3000-004',
    },
    {
      'nome': 'Patrícia Lima',
      'email': 'patricia.lima@email.pt',
      'password': 'password123',
      'nif': '123890123',
      'telefone': '956000005',
      'morada': 'Alameda Verde, 654, Braga',
      'codigoPostal': '4700-005',
    },
  ];

  final List<List<Map<String, dynamic>>> _productsForProducers = [
    // Produtos para João Silva
    [
      {'nome': 'Tomates Cherry Bio', 'descricao': 'Tomates cherry biológicos, doces e suculentos', 'preco': 3.50, 'unidade': 'Kg', 'stock': 25.0, 'imagemUrl': 'https://images.unsplash.com/photo-1546094096-0df4bcaaa337?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Alface Romana', 'descricao': 'Alface romana fresca, ideal para saladas', 'preco': 1.20, 'unidade': 'Unidade', 'stock': 40.0, 'imagemUrl': 'https://images.unsplash.com/photo-1622206151226-18ca2c9ab4a1?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Cenouras Baby', 'descricao': 'Cenouras baby tenras e doces', 'preco': 2.80, 'unidade': 'Kg', 'stock': 30.0, 'imagemUrl': 'https://images.unsplash.com/photo-1447175008436-054170c2e979?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Ervas Aromáticas Mix', 'descricao': 'Mistura de ervas aromáticas frescas', 'preco': 4.00, 'unidade': 'Molho', 'stock': 15.0, 'imagemUrl': 'https://images.unsplash.com/photo-1466692476868-aef1dfb1e735?w=400&h=300&fit=crop', 'categoria': 'Ervas'},
      {'nome': 'Pepinos Bio', 'descricao': 'Pepinos biológicos crocantes', 'preco': 2.20, 'unidade': 'Kg', 'stock': 20.0, 'imagemUrl': 'https://images.unsplash.com/photo-1449300079323-02e209d9d3a6?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
    ],
    // Produtos para Maria Santos
    [
      {'nome': 'Azeite Extra Virgem', 'descricao': 'Azeite extra virgem da primeira prensagem', 'preco': 12.00, 'unidade': 'L', 'stock': 50.0, 'imagemUrl': 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400&h=300&fit=crop', 'categoria': 'Condimentos'},
      {'nome': 'Azeitonas Pretas', 'descricao': 'Azeitonas pretas curadas tradicionalmente', 'preco': 6.50, 'unidade': 'Kg', 'stock': 35.0, 'imagemUrl': 'https://images.unsplash.com/photo-1632481247824-e22de9c9cc11?w=400&h=300&fit=crop', 'categoria': 'Conservas'},
      {'nome': 'Mel de Rosmaninho', 'descricao': 'Mel puro de rosmaninho do Alentejo', 'preco': 8.00, 'unidade': 'Kg', 'stock': 25.0, 'imagemUrl': 'https://images.unsplash.com/photo-1587049016823-83eb5d07ad3c?w=400&h=300&fit=crop', 'categoria': 'Condimentos'},
      {'nome': 'Queijo de Cabra', 'descricao': 'Queijo artesanal de cabra curado', 'preco': 15.00, 'unidade': 'Kg', 'stock': 12.0, 'imagemUrl': 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=400&h=300&fit=crop', 'categoria': 'Laticínios'},
      {'nome': 'Figos Secos', 'descricao': 'Figos secos naturais sem aditivos', 'preco': 7.50, 'unidade': 'Kg', 'stock': 18.0, 'imagemUrl': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400&h=300&fit=crop', 'categoria': 'Frutas'},
    ],
    // Produtos para António Costa
    [
      {'nome': 'Maçãs Reineta', 'descricao': 'Maçãs reineta biológicas crocantes', 'preco': 2.50, 'unidade': 'Kg', 'stock': 60.0, 'imagemUrl': 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=400&h=300&fit=crop', 'categoria': 'Frutas'},
      {'nome': 'Peras Rocha', 'descricao': 'Peras rocha doces e suculentas', 'preco': 3.00, 'unidade': 'Kg', 'stock': 45.0, 'imagemUrl': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=400&h=300&fit=crop', 'categoria': 'Frutas'},
      {'nome': 'Nozes Descascadas', 'descricao': 'Nozes frescas descascadas', 'preco': 12.00, 'unidade': 'Kg', 'stock': 20.0, 'imagemUrl': 'https://images.unsplash.com/photo-1448043552756-e747b7c2b763?w=400&h=300&fit=crop', 'categoria': 'Frutos Secos'},
      {'nome': 'Castanhas', 'descricao': 'Castanhas da época, doces e cremosas', 'preco': 4.50, 'unidade': 'Kg', 'stock': 30.0, 'imagemUrl': 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=400&h=300&fit=crop', 'categoria': 'Frutos Secos'},
      {'nome': 'Sidra Artesanal', 'descricao': 'Sidra artesanal de maçã bio', 'preco': 5.00, 'unidade': 'L', 'stock': 24.0, 'imagemUrl': 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=400&h=300&fit=crop', 'categoria': 'Bebidas'},
    ],
    // Produtos para Ana Ferreira
    [
      {'nome': 'Espinafres Baby', 'descricao': 'Espinafres baby tenros para saladas', 'preco': 3.20, 'unidade': 'Kg', 'stock': 28.0, 'imagemUrl': 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Rúcula Selvagem', 'descricao': 'Rúcula selvagem com sabor intenso', 'preco': 4.50, 'unidade': 'Kg', 'stock': 22.0, 'imagemUrl': 'https://images.unsplash.com/photo-1604977042946-1eecc30f269e?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Brócolos Bio', 'descricao': 'Brócolos biológicos frescos', 'preco': 2.80, 'unidade': 'Kg', 'stock': 35.0, 'imagemUrl': 'https://images.unsplash.com/photo-1459411621453-7b03977f4bfc?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Couve-Flor', 'descricao': 'Couve-flor branca e compacta', 'preco': 2.20, 'unidade': 'Unidade', 'stock': 25.0, 'imagemUrl': 'https://images.unsplash.com/photo-1568584711271-9127dfbb8511?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Acelgas Coloridas', 'descricao': 'Acelgas coloridas nutritivas', 'preco': 2.60, 'unidade': 'Kg', 'stock': 30.0, 'imagemUrl': 'https://images.unsplash.com/photo-1579952363873-27d3bfad9c0d?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
    ],
    // Produtos para Carlos Oliveira
    [
      {'nome': 'Batatas Novas', 'descricao': 'Batatas novas da época, cremosas', 'preco': 1.80, 'unidade': 'Kg', 'stock': 100.0, 'imagemUrl': 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=400&h=300&fit=crop', 'categoria': 'Tubérculos'},
      {'nome': 'Cebolas Roxas', 'descricao': 'Cebolas roxas doces e aromáticas', 'preco': 2.00, 'unidade': 'Kg', 'stock': 50.0, 'imagemUrl': 'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Alho Francês', 'descricao': 'Alho francês fresco para sopas', 'preco': 3.50, 'unidade': 'Kg', 'stock': 25.0, 'imagemUrl': 'https://images.unsplash.com/photo-1553978297-667178ecad33?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Nabos Baby', 'descricao': 'Nabos baby tenros e doces', 'preco': 2.70, 'unidade': 'Kg', 'stock': 20.0, 'imagemUrl': 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=400&h=300&fit=crop', 'categoria': 'Tubérculos'},
      {'nome': 'Rabanetes', 'descricao': 'Rabanetes crocantes e picantes', 'preco': 2.20, 'unidade': 'Molho', 'stock': 40.0, 'imagemUrl': 'https://images.unsplash.com/photo-1542990253-a781e04c0082?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
    ],
    // Produtos para Isabel Rodrigues
    [
      {'nome': 'Morangos Bio', 'descricao': 'Morangos biológicos doces e aromáticos', 'preco': 6.00, 'unidade': 'Kg', 'stock': 15.0, 'imagemUrl': 'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=400&h=300&fit=crop', 'categoria': 'Frutas'},
      {'nome': 'Framboesas', 'descricao': 'Framboesas frescas da quinta', 'preco': 8.50, 'unidade': 'Kg', 'stock': 10.0, 'imagemUrl': 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=400&h=300&fit=crop', 'categoria': 'Frutas'},
      {'nome': 'Mirtilos', 'descricao': 'Mirtilos antioxidantes frescos', 'preco': 9.00, 'unidade': 'Kg', 'stock': 12.0, 'imagemUrl': 'https://images.unsplash.com/photo-1498557850523-fd3d118b962e?w=400&h=300&fit=crop', 'categoria': 'Frutas'},
      {'nome': 'Amoras Silvestres', 'descricao': 'Amoras silvestres colhidas à mão', 'preco': 7.50, 'unidade': 'Kg', 'stock': 8.0, 'imagemUrl': 'https://images.unsplash.com/photo-1526318896980-cf78c088247c?w=400&h=300&fit=crop', 'categoria': 'Frutas'},
      {'nome': 'Compota Artesanal', 'descricao': 'Compota artesanal de frutos vermelhos', 'preco': 5.50, 'unidade': 'Unidade', 'stock': 30.0, 'imagemUrl': 'https://images.unsplash.com/photo-1571197119282-7c4e99eab38c?w=400&h=300&fit=crop', 'categoria': 'Conservas'},
    ],
    // Produtos para Pedro Almeida
    [
      {'nome': 'Pimentos Coloridos', 'descricao': 'Mix de pimentos vermelhos, amarelos e verdes', 'preco': 4.20, 'unidade': 'Kg', 'stock': 32.0, 'imagemUrl': 'https://images.unsplash.com/photo-1525607551316-4a8e16d1f9ba?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Beringelas Bio', 'descricao': 'Beringelas biológicas brilhantes', 'preco': 3.80, 'unidade': 'Kg', 'stock': 28.0, 'imagemUrl': 'https://images.unsplash.com/photo-1659261200833-ec8761558af7?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Curgetes Baby', 'descricao': 'Curgetes baby tenras e saborosas', 'preco': 3.20, 'unidade': 'Kg', 'stock': 35.0, 'imagemUrl': 'https://images.unsplash.com/photo-1559978303-f64f6ad5ba3a?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Abóbora Butternut', 'descricao': 'Abóbora butternut doce e cremosa', 'preco': 2.50, 'unidade': 'Kg', 'stock': 40.0, 'imagemUrl': 'https://images.unsplash.com/photo-1541876653740-9eb6b74ac9d1?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
      {'nome': 'Feijão Verde', 'descricao': 'Feijão verde fresco e crocante', 'preco': 4.80, 'unidade': 'Kg', 'stock': 22.0, 'imagemUrl': 'https://images.unsplash.com/photo-1525607551316-4a8e16d1f9ba?w=400&h=300&fit=crop', 'categoria': 'Legumes'},
    ],
    // Produtos para Luísa Martins
    [
      {'nome': 'Quinoa Bio', 'descricao': 'Quinoa biológica rica em proteínas', 'preco': 8.00, 'unidade': 'Kg', 'stock': 25.0, 'imagemUrl': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400&h=300&fit=crop', 'categoria': 'Cereais'},
      {'nome': 'Amaranto', 'descricao': 'Grãos de amaranto nutritivos', 'preco': 7.50, 'unidade': 'Kg', 'stock': 20.0, 'imagemUrl': 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400&h=300&fit=crop', 'categoria': 'Cereais'},
      {'nome': 'Trigo Sarraceno', 'descricao': 'Trigo sarraceno sem glúten', 'preco': 6.00, 'unidade': 'Kg', 'stock': 30.0, 'imagemUrl': 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop', 'categoria': 'Cereais'},
      {'nome': 'Chia Bio', 'descricao': 'Sementes de chia biológicas', 'preco': 12.00, 'unidade': 'Kg', 'stock': 15.0, 'imagemUrl': 'https://images.unsplash.com/photo-1553024307-8ce4c9eab38c?w=400&h=300&fit=crop', 'categoria': 'Sementes'},
      {'nome': 'Farinha de Espelta', 'descricao': 'Farinha de espelta moída na pedra', 'preco': 4.50, 'unidade': 'Kg', 'stock': 35.0, 'imagemUrl': 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400&h=300&fit=crop', 'categoria': 'Cereais'},
    ],
    // Produtos para Miguel Pereira
    [
      {'nome': 'Ovos Caipira', 'descricao': 'Ovos de galinhas criadas ao ar livre', 'preco': 3.50, 'unidade': 'Dúzia', 'stock': 50.0, 'imagemUrl': 'https://images.unsplash.com/photo-1518569656558-1f25e69d93d7?w=400&h=300&fit=crop', 'categoria': 'Laticínios'},
      {'nome': 'Frango Bio', 'descricao': 'Frango biológico criado na quinta', 'preco': 8.50, 'unidade': 'Kg', 'stock': 15.0, 'imagemUrl': 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?w=400&h=300&fit=crop', 'categoria': 'Carnes'},
      {'nome': 'Leite de Cabra', 'descricao': 'Leite fresco de cabra pastoreada', 'preco': 2.80, 'unidade': 'L', 'stock': 40.0, 'imagemUrl': 'https://images.unsplash.com/photo-1550583724-b2692b85169f?w=400&h=300&fit=crop', 'categoria': 'Laticínios'},
      {'nome': 'Iogurte Natural', 'descricao': 'Iogurte natural sem aditivos', 'preco': 1.50, 'unidade': 'Unidade', 'stock': 60.0, 'imagemUrl': 'https://images.unsplash.com/photo-1571212515416-6b2ce739d668?w=400&h=300&fit=crop', 'categoria': 'Laticínios'},
      {'nome': 'Manteiga Artesanal', 'descricao': 'Manteiga artesanal de leite de vaca', 'preco': 6.00, 'unidade': 'Kg', 'stock': 25.0, 'imagemUrl': 'https://images.unsplash.com/photo-1587049016823-83eb5d07ad3c?w=400&h=300&fit=crop', 'categoria': 'Laticínios'},
    ],
    // Produtos para Sofia Gomes
    [
      {'nome': 'Vinho Verde Bio', 'descricao': 'Vinho verde biológico do Minho', 'preco': 8.00, 'unidade': 'L', 'stock': 30.0, 'imagemUrl': 'https://images.unsplash.com/photo-1566566202205-57815b7f5fe6?w=400&h=300&fit=crop', 'categoria': 'Bebidas'},
      {'nome': 'Broa de Milho', 'descricao': 'Broa de milho tradicional', 'preco': 2.50, 'unidade': 'Unidade', 'stock': 20.0, 'imagemUrl': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&h=300&fit=crop', 'categoria': 'Padaria'},
      {'nome': 'Chouriço Caseiro', 'descricao': 'Chouriço tradicional feito em casa', 'preco': 12.00, 'unidade': 'Kg', 'stock': 18.0, 'imagemUrl': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&h=300&fit=crop', 'categoria': 'Charcutaria'},
      {'nome': 'Presunto do Campo', 'descricao': 'Presunto curado tradicionalmente', 'preco': 25.00, 'unidade': 'Kg', 'stock': 8.0, 'imagemUrl': 'https://images.unsplash.com/photo-1562158079-6b3f0c7e6c0c?w=400&h=300&fit=crop', 'categoria': 'Charcutaria'},
      {'nome': 'Linguiça Defumada', 'descricao': 'Linguiça defumada artesanalmente', 'preco': 10.00, 'unidade': 'Kg', 'stock': 15.0, 'imagemUrl': 'https://images.unsplash.com/photo-1544025162-d76694265947?w=400&h=300&fit=crop', 'categoria': 'Charcutaria'},
    ],
  ];

  Future<void> _createSampleData() async {
    setState(() {
      _isCreating = true;
      _status = 'Iniciando criação de dados...';
    });

    try {
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

      setState(() => _status = 'Dados criados com sucesso!');
    } catch (e) {
      setState(() => _status = 'Erro: $e');
    } finally {
      setState(() => _isCreating = false);
    }
  }

  Future<void> _clearExistingData() async {
    final firestore = FirebaseFirestore.instance;
    
    // Primeiro, deletar contas antigas do Firebase Auth
    await _deleteOldAuthAccounts();
    
    // Deletar usuários (incluindo as contas antigas específicas)
    final usersSnapshot = await firestore.collection('users').get();
    for (final doc in usersSnapshot.docs) {
      final email = doc.data()['email'] as String?;
      // Remover todas as contas, incluindo as antigas especificadas
      if (email == 'tomasgamer2000@gmail.com' || email == 'ruimiguelsa.stb@gmail.com') {
        await doc.reference.delete();
        print('Removida conta antiga: $email');
      } else if (email != null && !email.contains('@farm.pt') && !email.contains('@verde.pt') && 
                 !email.contains('@bio.pt') && !email.contains('@natural.pt') && !email.contains('@campo.pt') &&
                 !email.contains('@terra.pt') && !email.contains('@fresco.pt') && !email.contains('@organico.pt') &&
                 !email.contains('@sustentavel.pt') && !email.contains('@tradicional.pt') && !email.contains('@email.pt')) {
        // Remove outras contas que não são do sistema atual
        await doc.reference.delete();
      }
    }

    // Deletar encomendas
    final ordersSnapshot = await firestore.collection('orders').get();
    for (final doc in ordersSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _deleteOldAuthAccounts() async {
    final List<String> oldEmails = [
      'tomasgamer2000@gmail.com',
      'ruimiguelsa.stb@gmail.com'
    ];

    for (final email in oldEmails) {
      try {
        // Tentar fazer login com a conta antiga para poder deletá-la
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: email == 'tomasgamer2000@gmail.com' ? 'teste123' : 'ruimiguel11',
        );
        
        if (userCredential.user != null) {
          await userCredential.user!.delete();
          print('Conta Auth removida: $email');
        }
      } catch (e) {
        print('Erro ao remover conta $email do Auth (pode já não existir): $e');
      }
    }
    
    // Fazer logout após a limpeza
    await FirebaseAuth.instance.signOut();
  }

  Future<List<String>> _createProducers() async {
    final List<String> producerIds = [];
    
    for (int i = 0; i < _producers.length; i++) {
      final producer = _producers[i];
      
      // Criar conta no Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: producer['email'],
        password: producer['password'],
      );

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
          .set(userModel.toMap());

      setState(() => _status = 'Criado produtor: ${producer['nome']}');
    }

    return producerIds;
  }

  Future<void> _createProducts(List<String> producerIds) async {
    for (int i = 0; i < producerIds.length; i++) {
      final producerId = producerIds[i];
      final products = _productsForProducers[i];

      for (final productData in products) {
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
            .add(product.toMap());
      }

      setState(() => _status = 'Criados produtos para produtor ${i + 1}');
    }
  }

  Future<void> _createConsumers() async {
    for (final consumer in _consumers) {
      // Criar conta no Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: consumer['email'],
        password: consumer['password'],
      );

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
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userModel.toMap());

      setState(() => _status = 'Criado consumidor: ${consumer['nome']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Criar Dados de Exemplo',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Isto irá criar:\n• 10 produtores com localização\n• 50 produtos (5 por produtor)\n• 5 consumidores',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 40),
          if (_isCreating)
            Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(_status, textAlign: TextAlign.center),
              ],
            )
          else
            ElevatedButton(
              onPressed: _createSampleData,
              child: const Text('Criar Dados'),
            ),
        ],
      ),
    );
  }
} 