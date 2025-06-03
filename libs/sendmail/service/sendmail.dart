import 'package:dotenv/dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../template/mail.dart';

class EmailService {
  EmailService() {
    final env = DotEnv()..load();

    sourceEmail = env['SOURCE_EMAIL'] ?? '';
    final username = env['GMAIL_USER'] ?? '';
    final password = env['GMAIL_PASSWORD'] ?? '';

    smtpServer = SmtpServer(
      'smtp.gmail.com',
      username: username,
      password: password,
      ignoreBadCertificate: true,
      allowInsecure: true,
    );
  }
  late final SmtpServer smtpServer;
  late final String sourceEmail;

  Future<void> sendOtpEmail(String recipient, String otp) async {
    final message = Message()
      ..from = Address(sourceEmail, 'Hỗ trợ OTP')
      ..recipients.add(recipient)
      ..subject = '🔐 Mã OTP xác thực của bạn'
      ..html = generateOtpEmailTemplate(otp);

    try {
      await send(message, smtpServer);
    } catch (e) {}
  }
}
