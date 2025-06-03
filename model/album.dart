import 'author.dart';
import 'category.dart';
import 'music.dart';

class Album {
  Album({
    this.id,
    this.albumTitle,
    this.description,
    this.linkUrlImageAlbum,
    this.createdAt,
    this.updatedAt,
    this.musics = const [],
    this.authors = const [],
    this.categories = const [],
    this.nation,
    this.listenCountAlbum = 0,
  });

  int? id;
  String? albumTitle;
  String? description;
  String? linkUrlImageAlbum;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<Music> musics;
  List<Author> authors;
  List<Category> categories;
  String? nation;
  int listenCountAlbum;

  Map<String, dynamic> toJson() => {
        'id': id,
        'albumTitle': albumTitle,
        'description': description,
        'linkUrlImageAlbum': linkUrlImageAlbum,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'musics': musics.map((m) => m.toJson()).toList(),
        'authors': authors.map((a) => a.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'nation': nation,
        'listenCountAlbum': listenCountAlbum,
      };

  @override
  String toString() {
    return '''
{id = $id, albumTitle = $albumTitle,description = $description,linkUrlImageAlbum = $linkUrlImageAlbum,createdAt = $createdAt, updatedAt= $updatedAt,musics : ${musics.map((m) => m.title).toList()},authors: ${authors.map((a) => a.name).toList()}, categories: ${categories.map((c) => c.name).toList()},nation = $nation,listenCountAlbum = $listenCountAlbum
''';
  }
}
