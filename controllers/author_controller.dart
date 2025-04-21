import '../model/author.dart';
import '../repository/author_repository.dart';

class AuthorController {
  AuthorController(this._authorRepository);
  final AuthorRepository _authorRepository;

  Future<Author?> findAuthorById(int id) async {
    final author = await _authorRepository.findAuthorById(id);
    return author;
  }

  Future<Author?> findAuthorByName(String name) async {
    final author = await _authorRepository.findAuthorByName(name);
    return author;
  }

  Future<List<Author>> showAuthorPaging({int offset = 0, int limit = 8}) async {
    final author =
        await _authorRepository.showAuthorPaging(offset: offset, limit: limit);
    return author;
  }
}
