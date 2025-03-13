import 'dart:async';
import 'package:postgres/postgres.dart';

class Database {
  Database() {
    _connect();
  }

  final String dbHost = 'localhost';
  final int dbPort = 5432;
  final String dbName = 'spotify';
  final String dbUser = 'postgres';
  final String dbPass = '6901ag';

  late Connection executor;

  Future<void> _connect() async {
    try {
      executor = await Connection.open(
        Endpoint(
          host: dbHost,
          port: dbPort,
          database: dbName,
          username: dbUser,
          password: dbPass,
        ),
        settings: ConnectionSettings(sslMode: SslMode.disable),
      );
      print('✅ Kết nối đến PostgreSQL thành công!');
    } catch (e) {
      print('❌ Lỗi kết nối đến PostgreSQL: $e');
    }
  }

  Connection get connection => executor;
}
