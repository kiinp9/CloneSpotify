class PlaylistItem {
  PlaylistItem({
    required this.playlistId, required this.musicId, this.id,
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
