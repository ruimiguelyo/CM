import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String? id;
  final String nome;
  final String descricao;
  final double preco;
  final String unidade; // Ex: "Kg", "Unidade", "L", "Molho"
  final String imagemUrl;
  final String produtorId;
  final Timestamp dataCriacao;

  ProductModel({
    this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.unidade,
    required this.imagemUrl,
    required this.produtorId,
    required this.dataCriacao,
  });

  // Converte um DocumentSnapshot para um objeto ProductModel
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      descricao: data['descricao'] ?? '',
      preco: (data['preco'] ?? 0.0).toDouble(),
      unidade: data['unidade'] ?? 'Unidade',
      imagemUrl: data['imagemUrl'] ?? '',
      produtorId: data['produtorId'] ?? '',
      dataCriacao: data['dataCriacao'] ?? Timestamp.now(),
    );
  }

  // Converte um objeto ProductModel para um Map para o Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'unidade': unidade,
      'imagemUrl': imagemUrl,
      'produtorId': produtorId,
      'dataCriacao': dataCriacao,
    };
  }
} 