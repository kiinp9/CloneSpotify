class Category {
  Category({
    this.id,
    this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.imageUrl,
  });

  int? id;
  String? name;
  String? description;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? imageUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'imageUrl': imageUrl
      };

  @override
  String toString() {
    return '''
{id= $id, name= $name, description = $description, createdAt = $createdAt, updatedAt = $updatedAt,imageUrl: $imageUrl}
''';
  }
}
