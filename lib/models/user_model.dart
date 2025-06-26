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
  final List<String> favoriteProducers;
  final double? latitude;
  final double? longitude;

  UserModel({
    required this.uid,
    required this.email,
    this.nome = '',
    this.nif = '',
    this.telefone = '',
    this.morada = '',
    this.codigoPostal = '',
    this.tipo = 'consumidor',
    this.fcmToken,
    this.latitude,
    this.longitude,
    List<String>? favoritos,
    List<String>? favoriteProducers,
  }) : this.favoritos = favoritos ?? [],
       this.favoriteProducers = favoriteProducers ?? [];

  // Usamos um factory constructor para adicionar lógica antes da criação do objeto.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      nome: data['nome'] ?? '',
      nif: data['nif'] ?? '',
      telefone: data['telefone'] ?? '',
      morada: data['morada'] ?? '',
      codigoPostal: data['codigoPostal'] ?? '',
      tipo: data['tipo'] ?? 'consumidor',
      fcmToken: data['fcmToken'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      favoritos: List<String>.from(data['favoritos'] ?? []),
      favoriteProducers: List<String>.from(data['favoriteProducers'] ?? []),
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
      'favoriteProducers': favoriteProducers,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  Map<String, dynamic> toFirestore() {
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
      'favoriteProducers': favoriteProducers,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
