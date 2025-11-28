class Estabelecimento {
  final int? id;
  final String nome;
  final double latitude;
  final double longitude;
  final int idBandeira;
  final int idCategoria;

  Estabelecimento({this.id, required this.nome, required this.latitude, required this.longitude, required this.idBandeira, required this.idCategoria});

  // Converte para Map para salvar no SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'latitude': latitude,
      'longitude': longitude,
      'id_bandeira': idBandeira,
      'id_categoria': idCategoria,
    };
  }

  // Converte de Map (do banco) para Objeto
  factory Estabelecimento.fromMap(Map<String, dynamic> map) {
    return Estabelecimento(
      id: map['id'],
      nome: map['nome'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      idBandeira: map['id_bandeira'],
      idCategoria: map['id_categoria'],
    );
  }
}