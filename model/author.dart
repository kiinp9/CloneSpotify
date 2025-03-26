class Author {
  Author({
    this.id,
    this.name,
    this.description,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });
  int? id;
  String? name;
  String? description;
  String? avatarUrl;
  DateTime? createdAt;
  DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'avatarUrl': avatarUrl,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  @override
  String toString() {
    return '''
{id =$id, name= $name, description= $description, avatarUrl= $avatarUrl,createdAt= $createdAt, updatedAt= $updatedAt}
''';
  }
}
