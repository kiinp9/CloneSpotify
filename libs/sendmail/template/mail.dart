String generateOtpEmailTemplate(String otp) {
  return '''
  <!DOCTYPE html>
  <html>
  <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Mã OTP của bạn</title>
      <style>
          body {
              font-family: Arial, sans-serif;
              background-color: #f4f4f4;
              margin: 0;
              padding: 0;
          }
          .container {
              max-width: 600px;
              margin: 20px auto;
              background: #ffffff;
              padding: 20px;
              border-radius: 10px;
              box-shadow: 0px 0px 10px rgba(0, 0, 0, 0.1);
          }
          .header {
              text-align: center;
              padding: 10px 0;
              border-bottom: 2px solid #eeeeee;
          }
          .header h2 {
              color: #333;
              margin: 0;
          }
          .content {
              padding: 20px;
              text-align: center;
          }
          .otp {
              font-size: 28px;
              font-weight: bold;
              color: #007bff;
              background: #f4f4f4;
              display: inline-block;
              padding: 10px 20px;
              border-radius: 5px;
              margin: 20px 0;
          }
          .footer {
              text-align: center;
              padding-top: 20px;
              font-size: 14px;
              color: #888;
          }
          .footer a {
              color: #007bff;
              text-decoration: none;
          }
      </style>
  </head>
  <body>
      <div class="container">
          <div class="header">
              <h2>🔐 Xác Thực OTP</h2>
          </div>
          <div class="content">
              <p>Xin chào,</p>
              <p>Bạn vừa yêu cầu mã OTP để đặt lại mật khẩu.</p>
              <div class="otp">$otp</div>
              <p>Mã này sẽ hết hạn sau <strong>3 phút</strong>.</p>
              <p>Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email này.</p>
          </div>
          <div class="footer">
              <p>Trân trọng,</p>
              <p><strong>Đội ngũ hỗ trợ</strong></p>
              <p>Nếu cần hỗ trợ, vui lòng liên hệ <a href="mailto:vietcuong23122002@gmail.com">vietcuong23122002@gmail.com</a></p>
          </div>
      </div>
  </body>
  </html>
  ''';
}
