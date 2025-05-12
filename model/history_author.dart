class HistoryAuthor {
  HistoryAuthor({
    this.id,
    required this.userId,
    required this.authorId,
    this.createdAt,
  });
  int? id;
  int userId;
  int authorId;

  DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'authorId': authorId,
        'createdAt': createdAt?.toIso8601String(),
      };

  @override
  String toString() {
    return '''
{id = $id,userId = $userId,authorId = $authorId,createdAt = $createdAt}
''';
  }
}
