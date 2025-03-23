abstract class IRedisService {
  Future<int?> getTokenVersion(int userId);
  Future<void> invalidateToken(int userId);
}
