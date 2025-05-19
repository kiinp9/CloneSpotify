# 🎵 CloneSpotify

[![Dart](https://img.shields.io/badge/dart-3.0+-blue.svg?style=flat-square)](https://dart.dev)
[![Dart Frog](https://img.shields.io/badge/dart_frog-backend-green.svg?style=flat-square)](https://dartfrog.vgv.dev)
[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg?style=flat-square)](./LICENSE)

## 📖 Tổng quan dự án

**CloneSpotify** là backend service cho ứng dụng nghe nhạc trực tuyến tương tự Spotify, được phát triển hoàn toàn bằng **Dart** sử dụng framework **Dart Frog**.

Dự án cung cấp RESTful API hỗ trợ đầy đủ tính năng quản lý người dùng, xác thực bảo mật, quản lý nhạc và playlist, tương tác xã hội (thích, theo dõi), đồng thời tích hợp các công nghệ hiện đại như PostgreSQL, Redis, Cloudinary và JWT.

## 🚀 Tính năng chính

### 🔐 Authentication & Authorization
- Đăng ký và đăng nhập với email/password
- Xác thực bằng mã OTP gửi qua email (đăng ký, reset mật khẩu)
- Đăng nhập Google OAuth
- Xác thực trạng thái bằng JWT (token access & refresh)

### 📱 OTP Verification
- Mã OTP ngẫu nhiên lưu trong Redis
- Gửi email OTP qua Gmail SMTP

### 🎧 Music & Album Management
- CRUD bài hát và album với upload media lên Cloudinary
- Truy vấn chi tiết bài hát, album

### 🏷️ Category / Genre Management
- Quản lý danh mục thể loại nhạc

### 📋 Playlist
- Tạo, sửa, xóa playlist
- Quản lý bài hát trong playlist

### 👥 Social Features
- Thích / bỏ thích bài hát
- Lịch sử nghe
- Theo dõi / bỏ theo dõi nghệ sĩ

### 🔍 Search
- Tìm kiếm theo tên bài hát, album, nghệ sĩ

### 🐳 Dockerized
- Hỗ trợ chạy cùng PostgreSQL, Redis trong Docker Compose

## 🛠️ Công nghệ sử dụng

| Thành phần          | Công nghệ / Thư viện                 |
|---------------------|-------------------------------------|
| Ngôn ngữ            | Dart 3.x                            |
| Backend Framework   | [Dart Frog](https://dartfrog.vgv.dev) |
| Cơ sở dữ liệu       | PostgreSQL                          |
| Cache / OTP Storage | Redis                               |
| Media Hosting       | [Cloudinary](https://cloudinary.com) |
| Xác thực            | JWT ([dart_jsonwebtoken](https://pub.dev/packages/dart_jsonwebtoken)) |
| Dịch vụ Email       | Gmail SMTP                          |
| Container           | Docker & Docker Compose             |

## 📁 Cấu trúc dự án

```
clone_spotify/
├── config/           # Cấu hình môi trường, JWT, biến env
├── controllers/      # Xử lý logic nghiệp vụ
├── database/         # Kết nối & truy vấn PostgreSQL, Redis
├── exception/        # Các lớp exception tùy chỉnh
├── libs/             # Các dịch vụ dùng chung (email, cloudinary, v.v)
├── model/            # Mô hình dữ liệu, DTOs
├── repository/       # Tầng truy cập dữ liệu
├── routes/           # Định tuyến API với Dart Frog
├── security/         # Xử lý bảo mật (OTP, middleware)
├── utils/            # Hàm tiện ích
├── constant/         # Hằng số hệ thống
├── log/              # Cấu hình logging
├── doc/              # Tài liệu thêm
├── test/             # Unit & integration tests
└── makefile
```

## ⚙️ Cấu hình môi trường

Tạo file `.env` ở thư mục gốc với các biến sau (không commit giá trị thật):

```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=clone_spotify
DB_USER=your_db_user
DB_PASSWORD=your_db_password

# JWT
JWT_SECRET=your_jwt_secret_key
ACCESS_TOKEN_EXPIRY=3600000         # TTL access token (ms)
REFRESH_TOKEN_EXPIRY=86400000       # TTL refresh token (ms)

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password  # nếu có

# Email
SOURCE_EMAIL=your_email@example.com
GMAIL_USER=your_gmail_username
GMAIL_PASSWORD=your_gmail_app_password

# Cloudinary
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_UPLOAD_PRESET=your_upload_preset

# Server
PORT=8080
```

## 🏁 Bắt đầu sử dụng

### Yêu cầu hệ thống
- Dart SDK 3.0 trở lên
- Docker & Docker Compose (tùy chọn)
- PostgreSQL và Redis (local hoặc container)

### Cài đặt & chạy local (không dùng Docker)

```bash
# Clone repository
git clone https://github.com/kiinp9/CloneSpotify.git
cd CloneSpotify

# Cài đặt dependencies
dart pub get

# Khởi tạo database schema
bash init_db.sh

# Chạy server dev với hot reload
dart_frog dev
```

API mặc định chạy trên: http://localhost:8080

### Chạy với Docker Compose

```bash
docker-compose up --build
```

Chạy đầy đủ backend, PostgreSQL và Redis trong containers.

## 📜 API Endpoints

| Method | Endpoint                          | Mô tả                              |
|--------|-----------------------------------|-----------------------------------|
| GET    | /app/home/category                | Lấy danh sách thể loại nhạc       |
| POST   | /app/auth/register                | Đăng ký người dùng                |
| POST   | /app/auth/login                   | Đăng nhập, nhận JWT               |
| POST   | /app/auth/forgot-password         | Gửi email reset mật khẩu (OTP)    |
| POST   | /app/auth/check-otp               | Xác nhận OTP                      |
| GET    | /app/music/{id}                   | Lấy chi tiết bài hát theo ID      |
| POST   | /admin/music/upload-music         | Upload bài hát mới (admin)        |
| POST   | /app/playlist/create-playlist     | Tạo playlist mới                  |
| POST   | /app/playlist/add-music-to-playlist | Thêm bài hát vào playlist      |
| GET    | /app/search/title?query=...       | Tìm kiếm bài hát theo tên         |

## 💻 Lệnh phát triển

```bash
# Cài dependencies
dart pub get

# Chạy server dev (hot reload)
dart_frog dev

# Chạy test
dart test

# Build production binary
dart pub global activate dart_frog_cli
dart pub global run dart_frog_cli:dart_frog build

# Build & chạy Docker Compose
docker-compose up --build
```

## 🤝 Đóng góp

Mở issue báo lỗi hoặc đề xuất tính năng.

Khi gửi Pull Request, đảm bảo:
- Tuân thủ chuẩn code
- Có test phù hợp
- Mô tả chi tiết, rõ ràng

## 📫 Liên hệ

Nếu bạn có câu hỏi hoặc góp ý, vui lòng liên hệ:

✉️ Email: vietcuong23122k2@gmail.com  
🌐 GitHub: [kiinp9](https://github.com/kiinp9)

## 📄 Giấy phép

Dự án này được phân phối theo giấy phép MIT — xem chi tiết trong [LICENSE](./LICENSE).

---

Build your own modern music streaming backend with CloneSpotify! 🎶