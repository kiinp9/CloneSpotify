class ErrorMessageSQL {
  static const String SQL_QUERY_ERROR = 'Lỗi thực hiện truy vấn SQL!';
  static const String SAVE_USER_FAILED = 'Lỗi khi lưu người dùng';
}

class ErrorMessageRoute {
  static const String PARAMETER_QUERY_ROUTER_NOT_NULL =
      'Lỗi parameter query không được rỗng';
  static const String ROUTER_ERROR = 'Lỗi router';
}

class ErrorMessage {
  static const String EMAIL_INVALID = 'Định dạng email không hợp lệ!';
  static const String PASSWORD_REQUIRED = 'Yêu cầu nhập mật khẩu!';
  static const String PASSWORD_IS_NOT_LONG_ENOUGH =
      'Độ dài mật khẩu không đủ. Độ dài mật khẩu tối thiểu là 8.';
  static const String PASSWORD_INCORRECT = 'Mật khẩu không khớp!';
  static const String TOKEN_INVALID = 'Định dạng token không hợp lệ!';
  static const String USER_NOT_FOUND = 'User không tồn tại!';
  static const String FULL_NAME_REQUIRED = 'Yêu cầu nhập đầy đủ họ tên';
  static const String MSG_METHOD_NOT_ALLOW = 'Method not allowed';
  static const String EMAIL_ALREADY_EXISTS = 'Email đã tồn tại!';
  static const String EMAIL_OR_USERNAME_REQUIRED =
      'Yêu cầu nhập email hoặc tên người dùng!';
  static const String PASSWORD_INVALID =
      'Mật khẩu cần có đầy đủ chữ hoa, chữ thường ,số ,kí tự đặc biệt.';
  static const String EMAIL_REQUIRED = 'Yêu cầu nhập email người dùng';
  static const String EMAIL_NOT_FOUND = 'Email không tồn tại';
  static const String INVALID_OTP_REQUEST = 'Không nhận được OTP từ request';
  static const String OTP_INVALID_OR_EXPIRED =
      'Không nhận được OTP hoặc OTP đã hết hạn';
  static const String REQUIRED = 'Yêu cầu nhập đủ thông tin';
  static const String PASSWORDS_DO_NOT_MATCH =
      'Mật khẩu mới và xác nhận mật khẩu không khớp nhau';
  static const String OLD_PASSWORD_INCORRECT = 'Mật khẩu cũ không khớp';
  static const String PASSWORD_CANNOT_BE_THE_SAME =
      'Mật khẩu mới và mật khẩu hiện tại phải khác nhau';
  static const String ID_TOKEN_INVALID = 'Id token không hợp lệ';
  static const String MISSING_ID_TOKEN = 'Thiếu idToken từ Google';
  static const String FILE_PATH_REQUIRED = 'File path không được bỏ trống';
  static const String MUSIC_UPLOAD_FAILED = 'upload nhạc không thành công';
  static const String UNABLE_TO_GET_SONG_DURATION =
      'Xảy ra lỗi trong khi tính toán thời lượng của bài hát';
  static const String INVALID_MUSIC_OR_IMAGE_FILE =
      'File nhạc hoặc ảnh không hợp lệ';
  static const String FILE_NOT_EXIST = 'File không tồn tại';
  static const String UPLOAD_FAIL = 'upload file thất bại';
  static const String EMPTY_TITLE = "Tiêu đề bài nhạc không được để trống";
  static const String EMPTY_DESCRIPTION = "Mô tả bài nhạc không được để trống";
  static const String EMPTY_AUTHOR_NAME = "Tên tác giả không được để trống";
  static const String EMPTY_AUTHOR_DESC = "Mô tả tác giả không được để trống";
  static const String EMPTY_AUTHOR_AVATAR =
      "Ảnh đại diện của tác giả không được để trống";
  static const String INVALID_MUSIC_PATH = "Đường dẫn tệp nhạc không hợp lệ";
  static const String INVALID_IMAGE_PATH =
      "Đường dẫn tệp hình ảnh không hợp lệ";
  static const String EMPTY_CATEGORY_DESCRIPTION =
      "Nội dung thể loại không được để trống";
  static const String EMPTY_CATEGORY_NAME = "Tên thể loại không được để trống";
  static const String SAVED_DB_FAIL = 'Xảy ra lỗi khi lưu vào database';
  static const String FORBIDDEN = 'Bạn không quyền thực hiện thao tác này';
  static const String EMPTY_ALBUM_TITLE = 'Title album không được để trống';
  static const String INVALID_ALBUM_FOLDER =
      'Đường dẫn đến thư mục album không hợp lệ';
  static const String INVALID_AUTHOR_IMAGE_FOLDER =
      'Đường dẫn đến thư mục chứa ảnh tác giả không hợp lệ';
  static const String MUSIC_NOT_FOUND = 'Không tìm thấy bài hát theo yêu cầu';
  static const String AUTHOR_NOT_FOUND = 'Không tìm thầy nhạc sĩ theo yêu cầu';
  static const String ALBUM_NOT_FOUND = 'Không tìm thấy album theo yêu cầu';
}
