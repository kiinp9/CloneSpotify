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
CREATE OR REPLACE FUNCTION update_timestamp() 
RETURNS TRIGGER AS $$  
BEGIN  
    NEW.updatedAt = (CURRENT_TIMESTAMP AT TIME ZONE 'UTC' + INTERVAL '7 hours');  
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

-- Bắt đầu transaction để đảm bảo dữ liệu chỉ lưu khi không có lỗi
BEGIN;

-- 1. Tạo bảng users với GoogleStatus mặc định là 1
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,  -- ID tự động tăng
    fullName VARCHAR(255),
    userName VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password TEXT ,
    gender VARCHAR(20) DEFAULT 'preferNotToSay', 
    birthday DATE,
    status INT DEFAULT 1,
    roleId INT REFERENCES roles(id) ON DELETE SET NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    GoogleStatus INT DEFAULT 1 CHECK (GoogleStatus IN (1, 2)) -- Chỉ cho phép 1 hoặc 2
);

-- 2. Tạo function để cập nhật updatedAt tự động
CREATE OR REPLACE FUNCTION update_timestamp() 
RETURNS TRIGGER AS $$  
BEGIN  
    NEW.updatedAt = (CURRENT_TIMESTAMP AT TIME ZONE 'UTC' + INTERVAL '7 hours');  
    RETURN NEW;  
END;  
$$ LANGUAGE plpgsql;

-- 3. Xóa trigger cũ nếu có
DROP TRIGGER IF EXISTS trigger_update_timestamp ON users;

-- 4. Tạo trigger tự động cập nhật updatedAt
CREATE TRIGGER trigger_update_timestamp
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- Nếu mọi thứ thành công, commit transaction
COMMIT;



-- Tạo bảng music 
	CREATE TABLE music (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    broadcastTime INT,
    linkUrlMusic TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    imageLink TEXT NOT NULL
);

-- Tạo bảng author 
Create table author (
id SERIAL PRIMARY KEY,
name Varchar(255) NOT NULL,
description TEXT,
avatarUrl TEXT NOT NULL,
createdAt TIMESTAMP DEFAULT NOW(),
updatedAt TIMESTAMP DEFAULT NOW()

);

-- Tạo bảng category

Create table category(
id SERIAL PRIMARY KEY,
name varchar(255) NOT NULL,
description TEXT,
createdAt TIMESTAMP DEFAULT NOW(),
updatedAt TIMESTAMP DEFAULT NOW()
);


-- Tạo bảng music_author(n-n)

CREATE TABLE music_author (
    musicId INT NOT NULL,
    authorId INT NOT NULL,
    PRIMARY KEY (musicId, authorId),
    FOREIGN KEY (musicId) REFERENCES music(id) ,
    FOREIGN KEY (authorId) REFERENCES author(id) 
);

-- Tạo bảng music_category(n-n)
CREATE TABLE music_category (
    musicId INT NOT NULL,
    categoryId INT NOT NULL,
    PRIMARY KEY (musicId, categoryId),
    FOREIGN KEY (musicId) REFERENCES music(id) ,
    FOREIGN KEY (categoryId) REFERENCES category(id) 
);
EOSQL
