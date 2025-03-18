class ErrorMessageSQL {
  static const String SQL_QUERY_ERROR = 'Lỗi thực hiện truy vấn SQL!';
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
}
