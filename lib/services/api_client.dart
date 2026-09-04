import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../navigation.dart';
import '../state/app_state.dart';

/// Thin wrapper around http that:
/// - attaches "Authorization: Bearer <token>" automatically
/// - always decodes the backend's {success, message, ...} JSON shape
/// - throws [ApiException] on failure so callers can just try/catch
/// - on a 401 (token invalid/expired), signs the app out and bounces to
///   the login screen automatically — see _handleUnauthorized below
class ApiException implements Exception {
  final String message;
  final int statusCode;
  bool get isAuthError => statusCode == 401;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}

class ApiClient {
  static const _tokenKey = 'api_token';

  // Guards against every in-flight request that gets a 401 at once
  // (dashboard poll + location ping + whatever else) each trying to
  // clear the token and navigate — only the first one should act.
  static bool _handlingAuthError = false;

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

  /// A 401 means the backend rejected api_token — expired, revoked, or
  /// just never set. Signing out and bouncing to the login screen here
  /// (rather than leaving each screen to show the raw "Invalid or
  /// expired token" message) is what actually satisfies "log out
  /// automatically instead of showing that error".
  static Future<void> _handleUnauthorized() async {
    if (_handlingAuthError) return;
    _handlingAuthError = true;
    try {
      await setToken(null);
      final context = navigatorKey.currentContext;
      if (context != null) {
        // ignore: use_build_context_synchronously
        Provider.of<AppState>(context, listen: false).clear();
      }
      final nav = navigatorKey.currentState;
      if (nav != null) {
        await nav.pushNamedAndRemoveUntil('/login', (route) => false, arguments: 'session_expired');
      }
    } finally {
      _handlingAuthError = false;
    }
  }

  static Map<String, dynamic> _decode(http.Response res, {required bool hadToken}) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Server returned an unexpected response.', res.statusCode);
    }

    if (res.statusCode >= 200 && res.statusCode < 300 && body['success'] == true) {
      return body;
    }

    // Only treat a 401 as "your session expired" when this request
    // actually carried a token that got rejected. A 401 from login()
    // itself (wrong phone/password, no token attached yet) is just a
    // normal credentials error the login screen should show inline —
    // auto-logging out *of* the login screen would be a confusing loop.
    if (res.statusCode == 401 && hadToken) {
      // Fire-and-forget — don't make every failed call wait on
      // navigation before the exception can propagate to its caller.
      _handleUnauthorized();
    }

    throw ApiException(body['message']?.toString() ?? 'Something went wrong.', res.statusCode);
  }

  static Future<Map<String, dynamic>> get(String url) async {
    final headers = await _headers();
    final res = await http.get(Uri.parse(url), headers: headers);
    return _decode(res, hadToken: headers.containsKey('Authorization'));
  }

  static Future<Map<String, dynamic>> post(String url, [Map<String, dynamic>? fields]) async {
    final body = <String, String>{};
    fields?.forEach((k, v) {
      if (v != null) body[k] = v.toString();
    });

    final headers = await _headers();
    final res = await http.post(Uri.parse(url), headers: headers, body: body);
    return _decode(res, hadToken: headers.containsKey('Authorization'));
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
    final headers = await _headers();
    request.headers.addAll(headers);

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
    return _decode(res, hadToken: headers.containsKey('Authorization'));
  }
}
