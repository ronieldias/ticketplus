import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ticketplus_v2.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 1. Tabelas Básicas
        await db.execute('CREATE TABLE usuarios(id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT, senha TEXT)');
        await db.execute('CREATE TABLE bandeiras(id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT)');
        await db.execute('CREATE TABLE categorias(id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT)');
        
        // 2. Tabela Estabelecimentos
        await db.execute(
            'CREATE TABLE estabelecimentos('
                'id INTEGER PRIMARY KEY AUTOINCREMENT, '
                'nome TEXT, '
                'latitude REAL, '
                'longitude REAL, '
                'id_categoria INTEGER, '
                'criado_por INTEGER)'
        );

        // 3. Tabela de Junção (Muitos-para-Muitos)
        await db.execute(
            'CREATE TABLE estabelecimento_bandeiras('
                'id_estabelecimento INTEGER, '
                'id_bandeira INTEGER, '
                'PRIMARY KEY (id_estabelecimento, id_bandeira))'
        );

        // 4. Seeds (Dados Iniciais)
        List<String> bands = ['Ticket Restaurante', 'Alelo', 'Sodexo', 'VR', 'Caju', 'Ben Visa', 'Green Card'];
        for (var b in bands) await db.insert('bandeiras', {'nome': b});

        List<String> cats = ['Restaurante', 'Supermercado', 'Churrascaria', 'Pizzaria', 'Lanchonete', 'Gelateria', 'Café', 'Frutaria', 'Bar', 'Pub'];
        for (var c in cats) await db.insert('categorias', {'nome': c});

        // Usuário Admin
        await db.insert('usuarios', {'email': 'admin', 'senha': '123'});
      },
    );
  }

  // --- MÉTODOS DE ESTABELECIMENTO ---

  // Inserção complexa (Salva estabelecimento + vínculos de bandeiras)
  Future<int> inserirEstabelecimento(Map<String, dynamic> estData, List<int> bandeirasIds) async {
    final db = await database;
    // Insere o local
    int estId = await db.insert('estabelecimentos', estData);
    
    // Insere os vínculos
    for (int bandId in bandeirasIds) {
      await db.insert('estabelecimento_bandeiras', {
        'id_estabelecimento': estId,
        'id_bandeira': bandId
      });
    }
    return estId;
  }
  
  // Atualização complexa
  Future<void> atualizarEstabelecimento(Map<String, dynamic> estData, List<int> bandeirasIds) async {
    final db = await database;
    int idEst = estData['id'];

    // Atualiza dados básicos
    await db.update('estabelecimentos', estData, where: 'id = ?', whereArgs: [idEst]);

    // Atualiza bandeiras (Apaga todas antigas e insere as novas)
    await db.delete('estabelecimento_bandeiras', where: 'id_estabelecimento = ?', whereArgs: [idEst]);
    
    for (int bandId in bandeirasIds) {
      await db.insert('estabelecimento_bandeiras', {
        'id_estabelecimento': idEst,
        'id_bandeira': bandId
      });
    }
  }

  // Busca completa com as bandeiras
  Future<List<Map<String, dynamic>>> buscarTodosEstabelecimentos() async {
    final db = await database;
    var result = await db.query('estabelecimentos');
    
    List<Map<String, dynamic>> listaFinal = [];
    
    for (var row in result) {
      // Cria uma cópia mutável do mapa
      var map = Map<String, dynamic>.from(row);
      
      // Busca as bandeiras deste estabelecimento
      var vinculos = await db.query('estabelecimento_bandeiras', 
        where: 'id_estabelecimento = ?', whereArgs: [row['id']]);
      
      // Adiciona a lista de IDs ao mapa
      map['bandeirasIds'] = vinculos.map((v) => v['id_bandeira'] as int).toList();
      listaFinal.add(map);
    }
    return listaFinal;
  }
}