import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

class DBHelper {
  static Future<sql.Database> database() async {
    final dbPath = await sql.getDatabasesPath();
    return sql.openDatabase(
      path.join(dbPath, 'posts.db'),
      onCreate: (db, version) {
        db.execute(
            'CREATE TABLE hashtags(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL , hashtag TEXT )');
        db.execute(
            'CREATE TABLE nickNames(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL , nickname TEXT )');
        db.execute(
            'CREATE TABLE newposts(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL , text TEXT, hashtags TEXT, image TEXT )');
        db.execute(
            'CREATE TABLE posts(id INTEGER PRIMARY KEY, ratings_count INTEGER, ratings_average REAL, hashtags TEXT, image TEXT, text TEXT)');
        db.execute(
            'CREATE TABLE hashtagPosts(hashtag TEXT PRIMARY KEY, ids TEXT)');
        db.execute(
            'CREATE TABLE nicknamePosts(nickname TEXT PRIMARY KEY, ids TEXT)');
        db.execute(
            'CREATE TABLE comments(postID INTEGER, comment TEXT, PRIMARY KEY(postID,comment))');
      },
      version: 1,
    );
  }

  static Future<void> insert(String table, Map<String, Object> data) async {
    final db = await DBHelper.database();
    db.insert(
      table,
      data,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getData(
      String table, List columns, conditions) async {
    try {
      final db = await DBHelper.database();
      return db.query(table, columns: [...columns], where: conditions);
    } catch (error) {
      throw (error);
    }
  }

  static Future<void> cleanTable(String table) async {
    final db = await DBHelper.database();
    db.delete(table);
  }
}
