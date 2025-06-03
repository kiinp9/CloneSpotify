import 'dart:math';
import '../database/redis.dart';

class OtpService {

  OtpService(this.redisService);
  final RedisService redisService;

  String generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> saveOtp(String email) async {
    final otp = generateOtp();
    await redisService.setValue('OTP:$email', otp);
  }

  Future<String?> getOtp(String email) async {
    return redisService.getValue('OTP:$email');
  }

  Future<void> deleteOtp(String email) async {
    await redisService.deleteValue('OTP:$email');
  }
}
