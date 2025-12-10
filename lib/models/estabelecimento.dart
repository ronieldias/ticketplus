class Estabelecimento {
  final int? id;
  final String nome;
  final double latitude;
  final double longitude;
  final int idCategoria;
  final int? criadoPor; // ID do usuário que criou
  final List<int> bandeirasIds; // Lista de IDs das bandeiras aceitas

  Estabelecimento({
    this.id,
    required this.nome,
    required this.latitude,
    required this.longitude,
    required this.idCategoria,
    this.criadoPor,
    required this.bandeirasIds,
  });

  // Converte objeto para Map (para salvar no banco)
  // Nota: bandeirasIds não entra aqui, pois fica em outra tabela
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'latitude': latitude,
      'longitude': longitude,
      'id_categoria': idCategoria,
      'criado_por': criadoPor,
    };
  }

  // Converte Map (do banco) para Objeto
  factory Estabelecimento.fromMap(Map<String, dynamic> map, List<int> bandeiras) {
    return Estabelecimento(
      id: map['id'],
      nome: map['nome'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      idCategoria: map['id_categoria'],
      criadoPor: map['criado_por'],
      bandeirasIds: bandeiras,
    );
  }
}