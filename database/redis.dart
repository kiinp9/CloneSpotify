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
    final String? redisPassword = "";

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

  Future<void> setPlayMusicHistory(int userId, String musicId) async {
    await _checkConnection();
    final key = 'user:$userId:music';

    await _command!.send_object(['LPUSH', key, musicId]);
    await _command!.send_object(['EXPIRE', key, 7200]);
  }

  Future<List<String>> getPlayMusicHistory(int userId) async {
    await _checkConnection();
    final key = 'user:$userId:music';

    final result = await _command!.send_object(['LRANGE', key, 0, -1]);

    return (result as List).map((e) => e.toString()).toList();
  }

  Future<void> playNextMusic(int userId, String nextMusicId) async {
    await setPlayMusicHistory(userId, nextMusicId);
  }

  Future<String?> rewindMusic(int userId, int currentMusicId) async {
    await _checkConnection();
    final key = 'user:$userId:music';

    final result = await _command!.send_object(['LRANGE', key, 0, -1]);

    final List<String> history =
        (result as List).map((e) => e.toString()).toList();

    final currentIndex = history.indexOf(currentMusicId.toString());

    if (currentIndex == -1) {
      return null;
    }

    if (currentIndex + 1 < history.length) {
      return history[currentIndex + 1];
    }

    return null;
  }

  Future<void> deleteHistory(int userId) async {
    await _checkConnection();
    final key = 'user:$userId:music';

    await _command!.send_object(['DEL', key]);
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
