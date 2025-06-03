class HistoryAlbum {
  HistoryAlbum({
    required this.userId, required this.albumId, required this.musicId, this.id,
    this.createdAt,
  });
  int? id;
  int userId;
  int albumId;
  int musicId;

  DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'albumId': albumId,
        'musicId': musicId,
        'createdAt': createdAt?.toIso8601String(),
      };

  @override
  String toString() {
    return '''
{id = $id,userId = $userId,albumId = $albumId,musicId= $musicId,createdAt = $createdAt}
''';
  }
}
