class PlaylistItem {
  PlaylistItem({
    this.id,
    required this.playlistId,
    required this.musicId,
    this.createdAt,
  });

  int? id;
  int playlistId;
  int musicId;
  DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'playlistId': playlistId,
        'musicId': musicId,
        'createdAt': createdAt?.toIso8601String(),
      };

  @override
  String toString() {
    return '''
{id =$id,playlistId = $playlistId, musicId = $musicId, createdAt = $createdAt}
''';
  }
}
