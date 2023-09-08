import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseManager {
  Database? _database;

  Future<void> initDatabase() async {
    if (_database == null) {
      _database = await openDatabase(
        join(await getDatabasesPath(), 'dialogflow.db'),
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE dialogflow_responses(id INTEGER PRIMARY KEY, responseText TEXT)',
          );
        },
        version: 1,
      );
    }
  }

  Future<Database?> get database async {
    if (_database != null) {
      return _database;
    }
    await initDatabase();
    return _database;
  }

  Future<void> saveResponseToDatabase(String responseText) async {
    final Database? db = await DatabaseManager().database;
    if (db != null) {
      await db.insert(
        'dialogflow_responses',
        {'responseText': responseText},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<Object> getDataFromDatabase() async {
    final Database? db = await DatabaseManager().database;
    return db?.query('dialogflow_responses') ?? [];
  }

}
