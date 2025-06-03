import 'dart:async';

import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

class Database {
  Database() {
    _connect();
  }

  late Connection executor;

  Future<void> _connect() async {
    try {
      final env = DotEnv()..load();

      final dbHost = env['DB_HOST'] ?? '';
      final dbPort = int.tryParse(env['DB_PORT'] ?? '') ?? 5432;
      final dbName = env['DB_NAME'] ?? '';
      final dbUser = env['DB_USERNAME'] ?? '';
      final dbPass = env['DB_PASSWORD'] ?? '';

      executor = await Connection.open(
        Endpoint(
          host: dbHost,
          port: dbPort,
          database: dbName,
          username: dbUser,
          password: dbPass,
        ),
        settings: const ConnectionSettings(sslMode: SslMode.disable),
      );

      print('✅ Kết nối đến PostgreSQL thành công!');
    } catch (e) {
      print('❌ Lỗi kết nối đến PostgreSQL: $e');
    }
  }

  Connection get connection => executor;
}
