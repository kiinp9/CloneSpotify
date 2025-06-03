class Playlist {
  Playlist({
    required this.userId, required this.name, this.id,
    this.description,
    this.isPublic = false,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  int? id;
  int userId;
  String name;
  String? description;
  bool isPublic;
  String? imageUrl;
  DateTime? createdAt;
  DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'description': description,
        'isPublic': isPublic,
        'imageUrl': imageUrl,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  @override
  String toString() {
    return '''
{id =$id, userId= $userId,name =$name,description = $description,isPublic = $isPublic,imageUrl =$imageUrl,createdAt= $createdAt,updateAt = $updatedAt}
''';
  }
}
