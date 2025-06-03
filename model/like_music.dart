class LikeMusic {
  LikeMusic({
    required this.userId, required this.musicId, this.id,
    this.createdAt,
    this.updatedAt,
  });

  int? id;
  int userId;
  int musicId;
  DateTime? createdAt;
  DateTime? updatedAt;
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'musicId': musicId,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  @override
  String toString() {
    return '''
{id = $id,userId = $userId,musicId = $musicId,createdAt = $createdAt,updatedAt = $updatedAt}
''';
  }
}
