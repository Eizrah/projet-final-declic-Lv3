// dans le fichier DatabaseManager.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:semaine6/modele/User.dart';

class DatabaseManager {
  static late Database _database;

  static Future<void> initialisation() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'user.db'),
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE user_photos(
            idUser TEXT PRIMARY KEY, 
            photoUrl TEXT
          )
        ''',
        );
      },
      version: 1,
    );
  }

  // Insère ou met à jour le chemin de la photo de l'utilisateur
  static Future<void> insertOrUpdateUserPhoto(User user) async {
    await _database.insert(
      'user_photos',
      user.toMap(),
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  // Récupère le chemin de la photo de l'utilisateur
  static Future<String?> getUserPhotoUrl(String idUser) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      'user_photos',
      where: 'idUser = ?',
      whereArgs: [idUser],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['photoUrl'] as String?;
    }
    return null;
  }
}