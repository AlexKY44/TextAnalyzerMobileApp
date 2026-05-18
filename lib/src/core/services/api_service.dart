import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    } else {
      return 'http://10.0.2.2:8000/api/v1';
    }
  }

  // 🔥 ОСНОВНИЙ МЕТОД (AI)
  static Future<dynamic> processText(
      String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: {"Content-Type": "application/json; charset=UTF-8"},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      final decoded = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        final data = jsonDecode(decoded);

        if (endpoint == '/check') {
          final mistakes = data['result']['mistakes'] as List;

          return {
            "text": data['result']['corrected'] ?? '',
            "style": data['result']['style_improved'] ?? '',
            "mistakes": mistakes.length,
            "chars": data['char_count'],
            "words": data['word_count'],
          };
        }

        return data['processed_text'] ?? '';
      } else {
        try {
          final errorData = jsonDecode(decoded);
          return 'Помилка: ${errorData['detail']}';
        } catch (_) {
          return 'Помилка сервера: ${response.statusCode}';
        }
      }
    } catch (e) {
      return 'Немає з\'єднання з сервером';
    }
  }

  static Future<String> uploadFile(PlatformFile file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ),
      );

      final response = await request.send();

      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(resBody);

        return data['text'] ?? 'Файл оброблено, але текст порожній';
      } else {
        return 'Помилка upload: ${response.statusCode}';
      }
    } catch (e) {
      return 'Помилка зʼєднання при upload';
    }
  }
}