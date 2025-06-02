#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Tạo ENUM cho giới tính
    DO $$ BEGIN
        CREATE TYPE gender_enum AS ENUM ('female', 'male', 'nonBinary', 'other', 'preferNotToSay');
    EXCEPTION
        WHEN duplicate_object THEN null;
    END $$;

  


-- Tạo ENUM type cho gender
CREATE TYPE public.gender_enum AS ENUM (
    'female',
    'male',
    'nonBinary',
    'other',
    'preferNotToSay'
);

-- Tạo các functions
CREATE FUNCTION public.update_roles_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updatedAt = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE FUNCTION public.update_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$  
BEGIN  
    NEW.updatedAt = (CURRENT_TIMESTAMP AT TIME ZONE 'UTC' + INTERVAL '7 hours');  
    RETURN NEW;  
END;  
$$;

-- Bảng roles
CREATE TABLE public.roles (
    id SERIAL PRIMARY KEY,
    name CHARACTER VARYING(50) UNIQUE NOT NULL,
    description TEXT,
    createdat TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updatedat TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
-- Thêm role mặc định: admin và member
INSERT INTO roles (name, description)
VALUES 
    ('admin', 'Quản trị viên hệ thống'),
    ('member', 'Thành viên bình thường')
ON CONFLICT (name) DO NOTHING;

-- Bảng users
CREATE TABLE public.users (
    id SERIAL PRIMARY KEY,
    fullname CHARACTER VARYING(255),
    username CHARACTER VARYING(255) UNIQUE NOT NULL,
    email CHARACTER VARYING(255) UNIQUE NOT NULL,
    password TEXT,
    gender CHARACTER VARYING(20) DEFAULT 'preferNotToSay',
    birthday DATE,
    status INTEGER DEFAULT 1,
    roleid INTEGER REFERENCES public.roles(id) ON DELETE SET NULL,
    createdat TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updatedat TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    googlestatus INTEGER DEFAULT 1 CHECK (googlestatus = ANY (ARRAY[1, 2]))
);

-- Bảng author
CREATE TABLE public.author (
    id SERIAL PRIMARY KEY,
    name CHARACTER VARYING(255) NOT NULL,
    description TEXT,
    avatarurl TEXT NOT NULL,
    createdat TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updatedat TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    followingcount INTEGER DEFAULT 0
);

-- Bảng category
CREATE TABLE public.category (
    id SERIAL PRIMARY KEY,
    name CHARACTER VARYING(255) NOT NULL,
    description TEXT,
    createdat TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updatedat TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    imageurl TEXT
);

-- Bảng album
CREATE TABLE public.album (
    id SERIAL PRIMARY KEY,
    description TEXT,
    linkurlimagealbum TEXT NOT NULL,
    createdat TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updatedat TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    albumtitle CHARACTER VARYING(255) NOT NULL,
    nation TEXT,
    listencountalbum INTEGER DEFAULT 0
);

-- Bảng music
CREATE TABLE public.music (
    id SERIAL PRIMARY KEY,
    title CHARACTER VARYING(255) UNIQUE NOT NULL,
    description TEXT,
    broadcasttime INTEGER,
    linkurlmusic TEXT NOT NULL,
    createdat TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updatedat TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    imageurl TEXT NOT NULL,
    albumid INTEGER REFERENCES public.album(id) ON DELETE CASCADE,
    listencount INTEGER DEFAULT 0,
    nation TEXT
);

-- Bảng playlist
CREATE TABLE public.playlist (
    id SERIAL PRIMARY KEY,
    userid INTEGER NOT NULL,
    name CHARACTER VARYING(255) NOT NULL,
    description TEXT,
    ispublic BOOLEAN,
    imageurl TEXT,
    createdat TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updatedat TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

-- Bảng playlistitem
CREATE TABLE public.playlistitem (
    id SERIAL PRIMARY KEY,
    playlistid INTEGER NOT NULL REFERENCES public.playlist(id) ON DELETE CASCADE,
    createdat TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    musicid INTEGER REFERENCES public.music(id) ON DELETE CASCADE,
    CONSTRAINT unique_playlist_musicid UNIQUE (playlistid, musicid)
);

-- Bảng album_author (many-to-many)
CREATE TABLE public.album_author (
    albumid INTEGER NOT NULL REFERENCES public.album(id),
    authorid INTEGER NOT NULL REFERENCES public.author(id),
    PRIMARY KEY (albumid, authorid)
);

-- Bảng album_category (many-to-many)
CREATE TABLE public.album_category (
    albumid INTEGER NOT NULL REFERENCES public.album(id),
    categoryid INTEGER NOT NULL REFERENCES public.category(id),
    PRIMARY KEY (albumid, categoryid)
);

-- Bảng music_author (many-to-many)
CREATE TABLE public.music_author (
    musicid INTEGER NOT NULL REFERENCES public.music(id) ON DELETE CASCADE,
    authorid INTEGER NOT NULL REFERENCES public.author(id),
    PRIMARY KEY (musicid, authorid)
);

-- Bảng music_category (many-to-many)
CREATE TABLE public.music_category (
    musicid INTEGER NOT NULL REFERENCES public.music(id) ON DELETE CASCADE,
    categoryid INTEGER NOT NULL REFERENCES public.category(id),
    PRIMARY KEY (musicid, categoryid)
);

-- Bảng followauthor
CREATE TABLE public.followauthor (
    id SERIAL PRIMARY KEY,
    userid INTEGER,
    authorid INTEGER,
    createdat TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updatedat TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_authorid UNIQUE (userid, authorid)
);

-- Bảng history
CREATE TABLE public.history (
    id SERIAL PRIMARY KEY,
    userid INTEGER,
    musicid INTEGER,
    createdat TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_music UNIQUE (userid, musicid)
);

-- Bảng history_album
CREATE TABLE public.history_album (
    id SERIAL PRIMARY KEY,
    userid INTEGER,
    albumid INTEGER,
    musicid INTEGER,
    createdat TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_album_musicid UNIQUE (userid, albumid, musicid)
);

-- Bảng history_author
CREATE TABLE public.history_author (
    id SERIAL PRIMARY KEY,
    userid INTEGER,
    authorid INTEGER,
    createdat TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_author UNIQUE (userid, authorid)
);

-- Bảng likemusic
CREATE TABLE public.likemusic (
    id SERIAL PRIMARY KEY,
    userid INTEGER,
    musicid INTEGER,
    createdat TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updatedat TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_musicid UNIQUE (userid, musicid)
);

-- Tạo triggers
CREATE TRIGGER trigger_update_roles_timestamp 
    BEFORE UPDATE ON public.roles 
    FOR EACH ROW EXECUTE FUNCTION public.update_roles_timestamp();

CREATE TRIGGER trigger_update_timestamp 
    BEFORE UPDATE ON public.users 
    FOR EACH ROW EXECUTE FUNCTION public.update_timestamp();
EOSQL
