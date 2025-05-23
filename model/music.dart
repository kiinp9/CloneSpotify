import 'author.dart';
import 'category.dart';

class Music {
  Music({
    this.id,
    this.title,
    this.description,
    this.broadcastTime,
    this.linkUrlMusic,
    this.authors = const [],
    this.categories = const [],
    this.createdAt,
    this.updatedAt,
    this.imageUrl,
    this.albumId,
    this.listenCount = 0,
    this.nation,
  });

  int? id;
  String? title;
  String? description;
  int? broadcastTime;
  String? linkUrlMusic;
  List<Author> authors;
  List<Category> categories;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? imageUrl;
  int? albumId;
  int listenCount;
  String? nation;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'broadcastTime': broadcastTime,
        'linkUrlMusic': linkUrlMusic,
        'authors': authors.map((a) => a.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'imageUrl': imageUrl,
        'albumId': albumId,
        'listenCount': listenCount,
        'nation': nation,
      };

  @override
  String toString() {
    return '''
{id= $id, title= $title, description= $description, broadcastTime= $broadcastTime, linkUrlMusic= $linkUrlMusic, 
authors: ${authors.map((a) => a.name).toList()},
categories: ${categories.map((c) => c.name).toList()},
createdAt = $createdAt, updatedAt= $updatedAt, imageUrl: $imageUrl, albumId: $albumId, listenCount: $listenCount, nation: $nation}
''';
  }
}
