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
    String path = join(await getDatabasesPath(), 'ticketplus.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabela Usuários
        await db.execute('CREATE TABLE usuarios(id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT, senha TEXT)');
        // Tabela Bandeiras (Empresa do cartão)
        await db.execute('CREATE TABLE bandeiras(id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT)');
        // Tabela Categorias
        await db.execute('CREATE TABLE categorias(id INTEGER PRIMARY KEY AUTOINCREMENT, nome TEXT)');
        // Tabela Estabelecimentos
        await db.execute(
            'CREATE TABLE estabelecimentos('
                'id INTEGER PRIMARY KEY AUTOINCREMENT, '
                'nome TEXT, '
                'latitude REAL, '
                'longitude REAL, '
                'id_bandeira INTEGER, '
                'id_categoria INTEGER)'
        );

        // Inserir dados iniciais (Seed)
        await db.insert('bandeiras', {'nome': 'Ticket Restaurante'});
        await db.insert('bandeiras', {'nome': 'Alelo'});
        await db.insert('categorias', {'nome': 'Restaurante'});
        await db.insert('categorias', {'nome': 'Supermercado'});
        await db.insert('usuarios', {'email': 'admin', 'senha': '123'});
      },
    );
  }
}