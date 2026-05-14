import 'package:outgoing_notifications/models/Notification.dart';
import 'dbhelper.dart';
import 'package:sqflite/sqflite.dart';

class AppNotificationDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(AppNotification notification) async {
    Database db = await _dbHelper.database;
    return await db.insert('notifications', notification.toMap());
  }

  Future<List<AppNotification>> queryAll() async {
    Database db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query('notifications');

    return maps.map((map) => AppNotification.fromMap(map)).toList();
  }
}
