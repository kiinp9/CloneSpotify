# Stage 1: Build application
FROM dart:stable AS build

WORKDIR /app

# Copy pubspec và cài đặt dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy toàn bộ source code
COPY . .

# Cài Dart Frog CLI và build
RUN dart pub global activate dart_frog_cli
RUN dart pub global run dart_frog_cli:dart_frog build

# Compile server file
RUN dart compile exe build/bin/server.dart -o build/bin/server

# Stage 2: Runtime
FROM debian:bullseye-slim  

WORKDIR /app/bin


COPY --from=build /app/build/bin/server /app/build/bin/server


# Expose cổng chạy server
EXPOSE 8080

# Run server
CMD ["/app/build/bin/server"]
