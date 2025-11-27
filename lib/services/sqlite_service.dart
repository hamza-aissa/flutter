import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/client.dart';
import '../models/waiting_room.dart';

class SQLiteService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'waiting_room.db');

    return await openDatabase(
      path,
      version: 2, // ✅ CHANGE 1 → 2 (force la mise à jour)
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        print('🔄 Mise à jour DB: v$oldVersion → v$newVersion');
        // Supprimer les anciennes tables
        await db.execute('DROP TABLE IF EXISTS clients');
        await db.execute('DROP TABLE IF EXISTS waiting_rooms');
        // Créer les nouvelles
        await _onCreate(db, newVersion);
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table waiting_rooms
    await db.execute('''
      CREATE TABLE waiting_rooms (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      )
    ''');

    // Table clients
    await db.execute('''
      CREATE TABLE clients (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        lng REAL NOT NULL,
        lat REAL NOT NULL,
        waiting_room_id TEXT NOT NULL,
        FOREIGN KEY (waiting_room_id) REFERENCES waiting_rooms (id)
      )
    ''');
  }

  // ========== WAITING ROOMS ==========

  Future<void> insertWaitingRoom(WaitingRoom room) async {
    final db = await database;
    await db.insert(
      'waiting_rooms',
      room.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WaitingRoom>> getWaitingRooms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('waiting_rooms');
    return List.generate(maps.length, (i) => WaitingRoom.fromMap(maps[i]));
  }

  Future<WaitingRoom?> getWaitingRoomById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'waiting_rooms',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return WaitingRoom.fromMap(maps.first);
  }

  // ========== CLIENTS ==========

  Future<void> insertClient(Client client) async {
    final db = await database;
    await db.insert(
      'clients',
      client.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Client>> getClients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Client.fromMap(maps[i]));
  }

  Future<void> updateClient(Client client) async {
    final db = await database;
    await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<void> deleteClient(String id) async {
    final db = await database;
    await db.delete(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Client?> getClientById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Client.fromMap(maps.first);
  }

  /// Get the count of clients for a specific waiting room
  Future<int> getClientCountByRoomId(String roomId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM clients WHERE waiting_room_id = ?',
      [roomId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get clients for a specific waiting room
  Future<List<Client>> getClientsByRoomId(String roomId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      where: 'waiting_room_id = ?',
      whereArgs: [roomId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => Client.fromMap(maps[i]));
  }

  // Nettoyer toutes les données
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('clients');
    await db.delete('waiting_rooms');
  }
}
