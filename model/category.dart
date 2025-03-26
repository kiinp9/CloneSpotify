class Category {
  Category({
    this.id,
    this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  int? id;
  String? name;
  String? description;
  DateTime? createdAt;
  DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String()
      };

  @override
  String toString() {
    return '''
{id= $id, name= $name, description = $description, createdAt = $createdAt, updatedAt = $updatedAt}
''';
  }
}
