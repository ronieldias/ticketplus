class Estabelecimento {
  final int? id;
  final String nome;
  final double latitude;
  final double longitude;
  final int idCategoria;
  final int? criadoPor; // id do usuário que criou
  final List<int> bandeirasIds; // Lista de ids das bandeiras aceitas

  Estabelecimento({
    this.id,
    required this.nome,
    required this.latitude,
    required this.longitude,
    required this.idCategoria,
    this.criadoPor,
    required this.bandeirasIds,
  });

  // transforma objeto em map, para salvar no banco
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

  // transforma map para bjeto
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