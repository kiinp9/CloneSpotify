class TagHelper {
  static String extractTag(String path) {
    final segments = path
        .split('/')
        .where((s) => s.isNotEmpty && !s.startsWith('{'))
        .toList();

    if (segments.isEmpty) return 'Default';

    // Xác định tag dựa trên path patterns - chính xác theo yêu cầu
    if (path.contains('/auth')) return 'Auth';
    if (path.contains('/user')) return 'User';
    if (path.contains('/music')) return 'Music';
    if (path.contains('/playlist')) return 'Playlist';
    if (path.contains('/album')) return 'Album';
    if (path.contains('/author')) return 'Author';
    if (path.contains('/category')) return 'Category';
    if (path.contains('/history')) return 'History';
    if (path.contains('/search')) return 'Search';
    if (path.contains('/follow')) return 'Follow';
    if (path.contains('/like')) return 'Like';
    if (path.contains('/home')) return 'Home';

    // Đối với admin và app, sử dụng segment thứ 2
    if (segments.length >= 2) {
      final secondSegment = segments[1].toLowerCase();
      if (segments[0] == 'admin' || segments[0] == 'app') {
        switch (secondSegment) {
          case 'auth':
            return 'Auth';
          case 'user':
            return 'User';
          case 'music':
            return 'Music';
          case 'playlist':
            return 'Playlist';
          case 'album':
            return 'Album';
          case 'author':
            return 'Author';
          case 'category':
            return 'Category';
          case 'history':
            return 'History';
          case 'search':
            return 'Search';
          case 'follow-up':
            return 'Follow';
          case 'like-music':
            return 'Like';
          case 'home':
            return 'Home';
        }
      }
    }

    // Sử dụng segment đầu tiên có ý nghĩa
    final firstSegment = segments.first.toLowerCase();
    return firstSegment[0].toUpperCase() + firstSegment.substring(1);
  }

  static String getTagDescription(String tag) {
    final descriptions = {
      'Auth': 'Xác thực và phân quyền',
      'User': 'Quản lý người dùng',
      'Music': 'Quản lý và phát nhạc',
      'Playlist': 'Quản lý playlist',
      'Album': 'Quản lý album',
      'Author': 'Quản lý nghệ sĩ/tác giả',
      'Category': 'Quản lý danh mục',
      'History': 'Lịch sử nghe nhạc',
      'Search': 'Tìm kiếm',
      'Follow': 'Theo dõi nghệ sĩ',
      'Like': 'Yêu thích bài hát',
      'Home': 'Trang chủ và nội dung',
      'Default': 'Các endpoint mặc định',
    };
    return descriptions[tag] ?? 'APIs liên quan đến ${tag.toLowerCase()}';
  }
}
