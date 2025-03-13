class JwtConfig {
  static const String secretKey =
      "ded485eb5d74090cc81fa158716bb11e56d4844182c39a752f95f6c3f6b1f38d";
  static const int accessTokenExpiry = 6000000;
  static const int refreshTokenExpiry = 360000000;
}
