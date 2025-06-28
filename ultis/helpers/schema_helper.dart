class SchemaHelper {
  static Map<String, dynamic> getDefaultSchemas() {
    return {
      'User': {
        'type': 'object',
        'properties': {
          'id': {'type': 'string'},
          'email': {'type': 'string'},
          'fullName': {'type': 'string'},
          'userName': {'type': 'string'},
          'birthday': {'type': 'string', 'format': 'date'},
          'gender': {
            'type': 'string',
            'enum': ['male', 'female', 'nonBinary', 'other', 'preferNotToSay']
          }
        }
      },
      'SuccessResponse': {
        'type': 'object',
        'properties': {
          'status_code': {'type': 'integer'},
          'message': {'type': 'string'},
          'data': {'type': 'object'}
        }
      },
      'ErrorResponse': {
        'type': 'object',
        'properties': {
          'status_code': {'type': 'integer'},
          'message': {'type': 'string'},
          'error': {'type': 'string'}
        }
      },
      'PaginationQuery': {
        'type': 'object',
        'properties': {
          'offset': {'type': 'integer', 'default': 0},
          'limit': {'type': 'integer', 'default': 10}
        }
      },
      'AuthRegisterRequest': {
        'type': 'object',
        'required': ['email', 'password', 'fullName', 'userName'],
        'properties': {
          'email': {'type': 'string', 'example': 'user@example.com'},
          'password': {'type': 'string', 'example': 'mypassword'},
          'fullName': {'type': 'string', 'example': 'Nguyễn Việt Cường'},
          'userName': {'type': 'string', 'example': 'vietcuong123'},
          'birthday': {
            'type': 'string',
            'format': 'date',
            'example': '2002-12-23'
          },
          'gender': {
            'type': 'string',
            'enum': ['male', 'female', 'nonBinary', 'other', 'preferNotToSay'],
            'example': 'male'
          }
        }
      },
      'AuthLoginRequest': {
        'type': 'object',
        'required': ['identifier', 'password'],
        'properties': {
          'identifier': {
            'type': 'string',
            'description': 'Email, username hoặc identifier',
            'example': 'user@example.com'
          },
          'password': {
            'type': 'string',
            'description': 'Mật khẩu của người dùng',
            'example': 'mysecretpassword'
          }
        }
      },
      'CreatePlaylistRequest': {
        'type': 'object',
        'required': ['title'],
        'properties': {
          'title': {'type': 'string', 'example': 'My Favorite Songs'},
          'description': {
            'type': 'string',
            'example': 'Collection of my favorite songs'
          },
          'isPublic': {'type': 'boolean', 'example': true}
        }
      },
      'CreateMusicRequest': {
        'type': 'object',
        'required': ['title', 'authorId'],
        'properties': {
          'title': {'type': 'string', 'example': 'Song Title'},
          'description': {'type': 'string', 'example': 'Song description'},
          'authorId': {'type': 'string', 'example': 'author-id-123'},
          'albumId': {'type': 'string', 'example': 'album-id-123'},
          'categoryId': {'type': 'string', 'example': 'category-id-123'},
          'duration': {'type': 'integer', 'example': 240},
          'fileUrl': {
            'type': 'string',
            'example': 'https://example.com/song.mp3'
          },
          'imageUrl': {
            'type': 'string',
            'example': 'https://example.com/cover.jpg'
          }
        }
      },
      'CreateAlbumRequest': {
        'type': 'object',
        'required': ['title', 'authorId'],
        'properties': {
          'title': {'type': 'string', 'example': 'Album Title'},
          'description': {'type': 'string', 'example': 'Album description'},
          'authorId': {'type': 'string', 'example': 'author-id-123'},
          'imageUrl': {
            'type': 'string',
            'example': 'https://example.com/album-cover.jpg'
          },
          'releaseDate': {
            'type': 'string',
            'format': 'date',
            'example': '2024-01-01'
          }
        }
      }
    };
  }
}
