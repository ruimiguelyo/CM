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

  // Converte o objeto ProductModel para um Map.
  Map<String, dynamic> toMap() {
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

  // Mantido para compatibilidade com o código existente que usa toFirestore.
  // O ideal seria refatorar todo o código para usar toMap.
  Map<String, dynamic> toFirestore() => toMap();

  // Cria um objeto ProductModel a partir de um Documento do Firestore.
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
    data['id'] = doc.id; // Adiciona o ID do documento ao mapa
    return ProductModel.fromMap(data);
  }

  // Cria um objeto ProductModel a partir de um Map.
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'],
      nome: map['nome'] ?? '',
      descricao: map['descricao'] ?? '',
      preco: (map['preco'] ?? 0.0).toDouble(),
      unidade: map['unidade'] ?? '',
      imagemUrl: map['imagemUrl'] ?? '',
      produtorId: map['produtorId'] ?? '',
      dataCriacao: map['dataCriacao'] ?? Timestamp.now(),
    );
  }
} 