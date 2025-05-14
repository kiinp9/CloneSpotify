import '../repository/search_repository.dart';

class SearchController {
  SearchController(this._searchRepository);
  final SearchRepository _searchRepository;

  Future<Map<String, dynamic>> search(String query) async {
    final result = await _searchRepository.search(query);
    return result;
  }
}
