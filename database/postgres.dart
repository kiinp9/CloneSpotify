import 'dart:async';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

class Database {
  Database() {
    _connect();
  }

  late Connection executor;

  Future<void> _connect() async {
    try {
      final env = DotEnv()..load();

      final String dbHost = env['DB_HOST'] ?? '';
      final int dbPort = int.tryParse(env['DB_PORT'] ?? '') ?? 5432;
      final String dbName = env['DB_NAME'] ?? '';
      final String dbUser = env['DB_USERNAME'] ?? '';
      final String dbPass = env['DB_PASSWORD'] ?? '';

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
