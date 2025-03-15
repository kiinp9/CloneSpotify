#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Tạo ENUM cho giới tính
    DO $$ BEGIN
        CREATE TYPE gender_enum AS ENUM ('female', 'male', 'nonBinary', 'other', 'preferNotToSay');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END $$;

    -- Tạo bảng roles
    CREATE TABLE IF NOT EXISTS roles (
        id SERIAL PRIMARY KEY,
        name VARCHAR(50) UNIQUE NOT NULL,
        description TEXT,
        createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    );

    -- Thêm role mặc định: admin và member
    INSERT INTO roles (name, description)
    VALUES 
        ('admin', 'Quản trị viên hệ thống'),
        ('member', 'Thành viên bình thường')
    ON CONFLICT (name) DO NOTHING;

    -- Tạo bảng users
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        fullName VARCHAR(255),
        userName VARCHAR(255) UNIQUE NOT NULL,
        email VARCHAR(255) NOT NULL UNIQUE,
        password TEXT NOT NULL,
        gender gender_enum DEFAULT 'preferNotToSay',
        birthday DATE,
        status INT DEFAULT 1,
        roleId INT REFERENCES roles(id) ON DELETE SET NULL,
        createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    );
EOSQL
