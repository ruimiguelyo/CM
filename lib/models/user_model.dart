import 'package:cloud_firestore/cloud_firestore.dart';

// Esta classe representa o modelo de dados para um utilizador na nossa aplicação.
class UserModel {
  final String uid; // O ID único do Firebase Auth.
  final String nome;
  final String email;
  final String nif;
  final String telefone;
  final String morada;
  final String codigoPostal;
  // O tipo de utilizador, agora determinado pela lógica do NIF.
  final String tipo; 
  final String? fcmToken;
  final List<String> favoritos;
  final double? latitude;
  final double? longitude;

  // Tornamos o construtor principal privado para forçar a utilização do factory.
  // Desta forma, garantimos que a lógica de verificação do NIF é sempre aplicada.
  UserModel._({
    required this.uid,
    required this.nome,
    required this.email,
    required this.nif,
    required this.telefone,
    required this.morada,
    required this.codigoPostal,
    required this.tipo,
    this.fcmToken,
    this.favoritos = const [],
    this.latitude,
    this.longitude,
  });

  // Usamos um factory constructor para adicionar lógica antes da criação do objeto.
  factory UserModel({
    required String uid,
    required String nome,
    required String email,
    required String nif,
    required String telefone,
    required String morada,
    required String codigoPostal,
    String? fcmToken,
    List<String>? favoritos,
    double? latitude,
    double? longitude,
  }) {
    // Aplicamos a lógica para determinar o tipo de utilizador com base no NIF.
    String tipoUtilizador = 'consumidor'; // Assumimos 'consumidor' por defeito.
    
    // Verificamos se o NIF não está vazio antes de o analisar.
    if (nif.isNotEmpty) {
      final primeiroDigito = nif.substring(0, 1);
      // Se o primeiro dígito for 5, 6, 7, 8 ou 9, classificamos como 'agricultor'.
      if (['5', '6', '7', '8', '9'].contains(primeiroDigito)) {
        tipoUtilizador = 'agricultor';
      }
    }
    
    // Por fim, chamamos o construtor privado com o tipo de utilizador correto.
    return UserModel._(
      uid: uid,
      nome: nome,
      email: email,
      nif: nif,
      telefone: telefone,
      morada: morada,
      codigoPostal: codigoPostal,
      tipo: tipoUtilizador,
      fcmToken: fcmToken,
      favoritos: favoritos ?? [],
      latitude: latitude,
      longitude: longitude,
    );
  }

  // NOVO: Factory para criar um UserModel a partir de um documento do Firestore.
  // Isto é essencial para ler os dados da base de dados.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel._(
      uid: doc.id,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      nif: data['nif'] ?? '',
      telefone: data['telefone'] ?? '',
      morada: data['morada'] ?? '',
      codigoPostal: data['codigoPostal'] ?? '',
      tipo: data['tipo'] ?? 'consumidor',
      fcmToken: data['fcmToken'],
      favoritos: List<String>.from(data['favoritos'] ?? []),
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
    );
  }

  // Este método converte o nosso objeto UserModel para um Map<String, dynamic>,
  // que é o formato que o Firestore usa para guardar dados.
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nome': nome,
      'email': email,
      'nif': nif,
      'telefone': telefone,
      'morada': morada,
      'codigoPostal': codigoPostal,
      'tipo': tipo,
      'fcmToken': fcmToken,
      'favoritos': favoritos,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
