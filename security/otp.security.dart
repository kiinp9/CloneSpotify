import 'dart:math';
import '../database/redis.dart';

class OtpService {
  final RedisService redisService;

  OtpService(this.redisService);

  String generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> saveOtp(String email) async {
    final otp = generateOtp();
    await redisService.setValue('OTP:$email', otp, expirySeconds: 180);
  }

  Future<String?> getOtp(String email) async {
    return await redisService.getValue('OTP:$email');
  }

  Future<void> deleteOtp(String email) async {
    await redisService.deleteValue('OTP:$email');
  }
}
