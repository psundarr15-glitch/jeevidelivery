import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around http that:
/// - attaches "Authorization: Bearer <token>" automatically
/// - always decodes the backend's {success, message, ...} JSON shape
/// - throws [ApiException] on failure so callers can just try/catch
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}

class ApiClient {
  static const _tokenKey = 'api_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> setToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  static Future<Map<String, String>> _headers({bool isJsonBody = false}) async {
    final token = await getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  static Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Server returned an unexpected response.', res.statusCode);
    }

    if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
      return body;
    }

    throw ApiException(body['message']?.toString() ?? 'Something went wrong.', res.statusCode);
  }

  static Future<Map<String, dynamic>> get(String url) async {
    final res = await http.get(Uri.parse(url), headers: await _headers());
    return _decode(res);
  }

  static Future<Map<String, dynamic>> post(String url, [Map<String, dynamic>? fields]) async {
    final body = <String, String>{};
    fields?.forEach((k, v) {
      if (v != null) body[k] = v.toString();
    });

    final res = await http.post(Uri.parse(url), headers: await _headers(), body: body);
    return _decode(res);
  }

  /// For endpoints that take file uploads alongside regular fields (e.g.
  /// vendor/delivery-partner registration with certificates, ID proof,
  /// photos). [files] maps the form field name the backend expects
  /// (e.g. 'restaurant_banner') to the local file to send.
  static Future<Map<String, dynamic>> postMultipart(
    String url,
    Map<String, dynamic> fields, {
    Map<String, File>? files,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(await _headers());

    fields.forEach((k, v) {
      if (v != null) request.fields[k] = v.toString();
    });

    if (files != null) {
      for (final entry in files.entries) {
        if (await entry.value.exists()) {
          request.files.add(await http.MultipartFile.fromPath(entry.key, entry.value.path));
        }
      }
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }
}
