class FollowAuthor {
  FollowAuthor({
    required this.userId, required this.authorId, this.id,
    this.createdAt,
    this.updatedAt,
  });
  int? id;
  int userId;
  int authorId;
  DateTime? createdAt;
  DateTime? updatedAt;
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'authorId': authorId,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  @override
  String toString() {
    return '''
{id = $id,userId = $userId,authorId = $authorId,createdAt = $createdAt},updatedAt = $updatedAt
''';
  }
}
