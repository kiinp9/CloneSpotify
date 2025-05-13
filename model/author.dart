import 'album.dart';
import 'music.dart';

class Author {
  Author({
    this.id,
    this.name,
    this.description,
    this.avatarUrl,
    this.followingCount = 0,
    this.createdAt,
    this.updatedAt,
    this.musics = const [],
    this.albums = const [],
  });
  int? id;
  String? name;
  String? description;
  String? avatarUrl;
  int followingCount;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<Music> musics;
  List<Album> albums;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'avatarUrl': avatarUrl,
        'followingCount': followingCount,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'musics': musics.map((m) => m.toJson()).toList(),
        'albums': albums.map((al) => al.toJson()).toList(),
      };

  @override
  String toString() {
    return '''
{id =$id, name= $name, description= $description, avatarUrl= $avatarUrl,followingCount = $followingCount,createdAt= $createdAt, updatedAt= $updatedAt,musics: ${musics.map((m) => m.title).toList()}, albums : ${albums.map((al) => al.id).toList()}}
''';
  }
}
