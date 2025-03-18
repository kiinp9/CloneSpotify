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
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tạo trigger cập nhật updatedAt khi có thay đổi
CREATE FUNCTION update_roles_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updatedAt = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_roles_timestamp
BEFORE UPDATE ON roles
FOR EACH ROW
EXECUTE FUNCTION update_roles_timestamp();

-- Thêm role mặc định: admin và member
INSERT INTO roles (name, description)
VALUES 
    ('admin', 'Quản trị viên hệ thống'),
    ('member', 'Thành viên bình thường')
ON CONFLICT (name) DO NOTHING;


-- 1. Tạo bảng users (không dùng ENUM gender nữa)
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    fullName VARCHAR(255),
    userName VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password TEXT NOT NULL,
    gender VARCHAR(20) DEFAULT 'preferNotToSay', -- Đổi ENUM thành VARCHAR
    birthday DATE,
    status INT DEFAULT 1,
    roleId INT REFERENCES roles(id) ON DELETE SET NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Tạo trigger để cập nhật updatedAt tự động
CREATE OR REPLACE FUNCTION update_timestamp() 
RETURNS TRIGGER AS $$
BEGIN
    NEW.updatedAt = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_timestamp ON users;

CREATE TRIGGER trigger_update_timestamp
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_timestamp()

EOSQL
