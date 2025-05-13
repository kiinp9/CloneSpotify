import '../model/follow_author.dart';
import '../repository/follow_author_repository.dart';

class FollowAuthorController {
  FollowAuthorController(this._followAuthorRepository);
  final FollowAuthorRepository _followAuthorRepository;
  Future<FollowAuthor?> followAuthor(int userId, int authorId) async {
    final result = await _followAuthorRepository.followAuthor(userId, authorId);
    return result;
  }

  Future<FollowAuthor> unFollowAuthor(int userId, int authorId) async {
    final result =
        await _followAuthorRepository.unFollowAuthor(userId, authorId);
    return result;
  }

  Future<List<Map<String, dynamic>>> getAuthorFromFollowAuthor(
    int userId, {
    int offset = 0,
    int limit = 5,
  }) async {
    final result = await _followAuthorRepository
        .getAuthorFromFollowAuthor(userId, offset: offset, limit: limit);
    return result;
  }
}
