import 'music.dart';

class Author {
  Author({
    this.id,
    this.name,
    this.description,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
    this.musics = const [],
  });
  int? id;
  String? name;
  String? description;
  String? avatarUrl;
  DateTime? createdAt;
  DateTime? updatedAt;
  List<Music> musics;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'avatarUrl': avatarUrl,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'music': musics.map((m) => m.toJson()).toList(),
      };

  @override
  String toString() {
    return '''
{id =$id, name= $name, description= $description, avatarUrl= $avatarUrl,createdAt= $createdAt, updatedAt= $updatedAt,music: ${musics.map((m) => m.title).toList()}
''';
  }
}
