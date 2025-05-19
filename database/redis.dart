import 'package:dotenv/dotenv.dart';
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
    final env = DotEnv()..load();
    final String redisHost = env['REDIS_HOST'] ?? 'localhost';
    final int redisPort = int.tryParse(env['REDIS_PORT'] ?? '') ?? 6379;
    final String? redisPassword = env['REDIS_PASSWORD'];


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
    final historyKey = 'user:$userId:music';
    final currentKey = 'user:$userId:music:current';

    final result = await _command!.send_object(['LRANGE', historyKey, 0, -1]);
    final history = (result as List).map((e) => e.toString()).toList();

    final current = await getValue(currentKey);

    if (current != null) {
      final currentIndex = history.indexOf(current);
      if (currentIndex != -1) {
        await _command!.send_object(['LTRIM', historyKey, 0, currentIndex]);
      }
    }

    await _command!.send_object(['RPUSH', historyKey, musicId]);
    await _command!.send_object(['SET', currentKey, musicId]);
    await _command!.send_object(['EXPIRE', historyKey, 7200]);
    await _command!.send_object(['EXPIRE', currentKey, 7200]);
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
    final historyKey = 'user:$userId:music';
    final currentKey = 'user:$userId:music:current';

    final result = await _command!.send_object(['LRANGE', historyKey, 0, -1]);
    final List<String> history =
        (result as List).map((e) => e.toString()).toList();

    final index = history.indexOf(currentMusicId.toString());

    if (index == -1 || index == 0) {
      return null;
    }

    final previousId = history[index - 1];
    await _command!.send_object(['SET', currentKey, previousId]);
    return previousId;
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
