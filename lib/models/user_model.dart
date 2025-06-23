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
    };
  }
}
