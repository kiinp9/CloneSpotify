import 'dart:async';
import 'package:redis/redis.dart';

import 'iredis.dart';

class RedisService implements IRedisService {
  RedisConnection? _connection;
  Command? _command;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    try {
      await _connect();
      _initialized = true;
      print("✅ Kết nối Redis thành công!");
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

    _initialized = true;
  }

  Future<void> _checkConnection() async {
    if (_command == null) {
      await _connect();
      return;
    }

    try {
      await _command!.send_object(['PING']);
    } catch (e) {
      print("⚠️ Mất kết nối Redis, đang thử kết nối lại...");
      await _connect();
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

  Future<void> setTokenVersion(int userId, int version) async {
    await _checkConnection();
    await _command!
        .send_object(['SET', 'tokenVersion:$userId', version.toString()]);
  }

  Future<int?> getTokenVersion(int userId) async {
    await _checkConnection();
    final result = await _command!.send_object(['GET', 'tokenVersion:$userId']);
    return result != null ? int.tryParse(result.toString()) : null;
  }

  Future<void> invalidateToken(int userId) async {
    await _checkConnection();
    final currentVersion = await getTokenVersion(userId) ?? 0;
    await setTokenVersion(userId, currentVersion + 1);
  }

  Future<void> close() async {
    if (_command != null) {
      await _command!.send_object(['QUIT']);
    }

    if (_connection != null) {
      await _connection!.close();
    }

    _initialized = false;
    _connection = null;
    _command = null;
  }
}
