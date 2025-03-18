import 'package:dotenv/dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../template/mail.dart';

class EmailService {
  late final SmtpServer smtpServer;
  late final String sourceEmail;

  EmailService() {
    final env = DotEnv()..load();

    sourceEmail = env['SOURCE_EMAIL'] ?? 'vietcuong23122002@gmail.com';
    final username = env['GMAIL_USER'] ?? 'vietcuong23122002@gmail.com';
    final password = env['GMAIL_PASSWORD'] ?? 'kewl azoq wqkt qgry';

    smtpServer = SmtpServer(
      'smtp.gmail.com',
      port: 587,
      username: username,
      password: password,
      ignoreBadCertificate: true,
      allowInsecure: true,
    );
  }

  Future<void> sendOtpEmail(String recipient, String otp) async {
    final message = Message()
      ..from = Address(sourceEmail, 'Hỗ trợ OTP')
      ..recipients.add(recipient)
      ..subject = '🔐 Mã OTP xác thực của bạn'
      ..html = generateOtpEmailTemplate(otp);

    try {
      final sendReport = await send(message, smtpServer);
    } catch (e) {}
  }
}
