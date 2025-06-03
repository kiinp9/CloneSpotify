import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleSecurity {
  static Future<Map<String, String>?> verifyGoogleToken(String idToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://oauth2.googleapis.com/tokeninfo?id_token=$idToken'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final email = data['email']?.toString() ?? '';
        var name = data['name']?.toString().trim() ?? '';

        if (name.isEmpty) {
          final givenName = data['given_name']?.toString().trim() ?? '';
          final familyName = data['family_name']?.toString().trim() ?? '';
          name = '$givenName $familyName'.trim();
        }

        return {
          'email': email,
          'name': name,
        };
      } else {
        throw Exception('Lỗi xác thực Google Sign-In: ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi xác thực Google Sign-In: $e');
    }
  }
}
