#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL

-- Tạo ENUM cho gender, chỉ tạo nếu chưa tồn tại
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'gender_enum') THEN
        CREATE TYPE gender_enum AS ENUM ('female', 'male', 'nonBinary', 'other', 'preferNotToSay');
    END IF;
END
$$;

-- Function update_roles_timestamp
CREATE OR REPLACE FUNCTION update_roles_timestamp()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updatedAt = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- Function update_timestamp
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updatedAt = (CURRENT_TIMESTAMP AT TIME ZONE 'UTC' + INTERVAL '7 hours');
    RETURN NEW;
END;
$$;


-- Bảng roles
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    createdAt TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO roles (name, description)
VALUES 
    ('admin', 'Quản trị viên hệ thống'),
    ('member', 'Thành viên bình thường')
ON CONFLICT (name) DO NOTHING;

-- Bảng users
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    fullName VARCHAR(255),
    userName VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password TEXT,
    gender VARCHAR(20) DEFAULT 'preferNotToSay',
    birthday DATE,
    status INTEGER DEFAULT 1,
    roleId INTEGER REFERENCES roles(id) ON DELETE SET NULL,
    createdAt TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    googleStatus INTEGER DEFAULT 1 CHECK (googleStatus = ANY (ARRAY[1, 2])),
    avatarUserUrl TEXT
);

-- Bảng author
CREATE TABLE author (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    avatarUrl TEXT NOT NULL,
    createdAt TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updatedAt TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    followingCount INTEGER DEFAULT 0
);

-- Bảng category
CREATE TABLE category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    createdAt TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updatedAt TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    imageUrl TEXT
);

-- Bảng album
CREATE TABLE album (
    id SERIAL PRIMARY KEY,
    description TEXT,
    linkUrlImageAlbum TEXT NOT NULL,
    createdAt TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updatedAt TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    albumTitle VARCHAR(255) NOT NULL,
    nation TEXT,
    listenCountAlbum INTEGER DEFAULT 0
);

-- Bảng music
CREATE TABLE music (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    broadcastTime INTEGER,
    linkUrlMusic TEXT NOT NULL,
    createdAt TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updatedAt TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    imageUrl TEXT NOT NULL,
    albumId INTEGER REFERENCES album(id) ON DELETE CASCADE,
    listenCount INTEGER DEFAULT 0,
    nation TEXT
);

-- Bảng playlist
CREATE TABLE playlist (
    id SERIAL PRIMARY KEY,
    userId INTEGER NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    isPublic BOOLEAN,
    imageUrl TEXT,
    createdAt TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updatedAt TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

-- Bảng playlistItem
CREATE TABLE playlistItem (
    id SERIAL PRIMARY KEY,
    playlistId INTEGER NOT NULL REFERENCES playlist(id) ON DELETE CASCADE,
    createdAt TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    musicId INTEGER REFERENCES music(id) ON DELETE CASCADE,
    CONSTRAINT unique_playlist_music UNIQUE (playlistId, musicId)
);

-- Bảng album_author (many-to-many)
CREATE TABLE album_author (
    albumId INTEGER NOT NULL REFERENCES album(id),
    authorId INTEGER NOT NULL REFERENCES author(id),
    PRIMARY KEY (albumId, authorId)
);

-- Bảng album_category (many-to-many)
CREATE TABLE album_category (
    albumId INTEGER NOT NULL REFERENCES album(id),
    categoryId INTEGER NOT NULL REFERENCES category(id),
    PRIMARY KEY (albumId, categoryId)
);

-- Bảng music_author (many-to-many)
CREATE TABLE music_author (
    musicId INTEGER NOT NULL REFERENCES music(id) ON DELETE CASCADE,
    authorId INTEGER NOT NULL REFERENCES author(id),
    PRIMARY KEY (musicId, authorId)
);

-- Bảng music_category (many-to-many)
CREATE TABLE music_category (
    musicId INTEGER NOT NULL REFERENCES music(id) ON DELETE CASCADE,
    categoryId INTEGER NOT NULL REFERENCES category(id),
    PRIMARY KEY (musicId, categoryId)
);

-- Bảng followAuthor
CREATE TABLE followAuthor (
    id SERIAL PRIMARY KEY,
    userId INTEGER,
    authorId INTEGER,
    createdAt TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_author_follow UNIQUE (userId, authorId)
);

-- Bảng history
CREATE TABLE history (
    id SERIAL PRIMARY KEY,
    userId INTEGER,
    musicId INTEGER,
    createdAt TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_music UNIQUE (userId, musicId)
);

-- Bảng history_album
CREATE TABLE history_album (
    id SERIAL PRIMARY KEY,
    userId INTEGER,
    albumId INTEGER,
    musicId INTEGER,
    createdAt TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_album_music UNIQUE (userId, albumId, musicId)
);

-- Bảng history_author
CREATE TABLE history_author (
    id SERIAL PRIMARY KEY,
    userId INTEGER,
    authorId INTEGER,
    createdAt TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_author_history UNIQUE (userId, authorId)
);

-- Bảng likeMusic
CREATE TABLE likeMusic (
    id SERIAL PRIMARY KEY,
    userId INTEGER,
    musicId INTEGER,
    createdAt TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_music_like UNIQUE (userId, musicId)
);

-- Triggers
CREATE TRIGGER trigger_update_roles_timestamp 
    BEFORE UPDATE ON roles 
    FOR EACH ROW EXECUTE FUNCTION update_roles_timestamp();

CREATE TRIGGER trigger_update_timestamp 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_timestamp();

EOSQL
