class TokenResponse {
  TokenResponse(
      {required this.accessToken,
      required this.refreshToken,
      required this.expiresIn,});
  String accessToken;
  String refreshToken;
  String expiresIn;

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresIn': expiresIn,
      };
}
