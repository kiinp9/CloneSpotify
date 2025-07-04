class History {
  History({
    required this.userId, required this.musicId, this.id,
    this.createdAt,
  });

  int? id;
  int userId;
  int musicId;

  DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'musicId': musicId,
        'createdAt': createdAt?.toIso8601String(),
      };

  @override
  String toString() {
    return '''
{id = $id,userId = $userId,musicId = $musicId,createdAt = $createdAt}
''';
  }
}
