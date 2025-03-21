import 'dart:async';
import 'package:redis/redis.dart';
import '../main.dart';

class RedisService {
  RedisConnection? _connection;
  Command? _command;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    try {
      await _connect();
      if (_initialized) {
        print("✅ Kết nối Redis thành công!");
      }
    } catch (e) {
      throw Exception("Không thể kết nối Redis: $e");
    }
  }

  Future<void> _connect() async {
    final String redisHost = "localhost";
    final int redisPort = 6379;
    final String? redisPassword = null;

    _connection = RedisConnection();
    _command = await _connection!.connect(redisHost, redisPort);

    if (redisPassword != null && redisPassword.isNotEmpty) {
      await _command!.send_object(['AUTH', redisPassword]);
    }
  }

  Future<void> _checkConnection() async {
    if (!_initialized || _command == null) {
      await init();
    }
  }

  Future<void> setValue(String key, String value,
      {int expirySeconds = 180}) async {
    await _checkConnection();
    await _command!.send_object(['SET', key, value, 'EX', expirySeconds]);
  }

  Future<String?> getValue(String key) async {
    await _checkConnection();
    final result = await _command!.send_object(['GET', key]);
    return result?.toString();
  }

  Future<void> deleteValue(String key) async {
    await _checkConnection();
    await _command!.send_object(['DEL', key]);
  }

  Future<void> close() async {
    if (_initialized && _connection != null) {
      await _connection!.close();
      _initialized = false;
      _connection = null;
      _command = null;
    }
  }
}
