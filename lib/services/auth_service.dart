import 'dart:io';
import '../config/api_config.dart';
import 'api_client.dart';

class AuthService {
  static Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final res = await ApiClient.post(ApiConfig.login, {'email': email, 'password': password});
    await ApiClient.setToken(res['token']?.toString());
    return res['partner'] as Map<String, dynamic>;
  }

  /// Matches DeliveryAuthApiController::register — most fields required,
  /// bank details optional, plus three optional file uploads.
  static Future<String> register({
    required Map<String, String> fields,
    File? photo,
    File? idProofDocument,
    File? rcDocument,
  }) async {
    final res = await ApiClient.postMultipart(
      ApiConfig.register,
      fields,
      files: {
        if (photo != null) 'photo': photo,
        if (idProofDocument != null) 'id_proof_document': idProofDocument,
        if (rcDocument != null) 'rc_document': rcDocument,
      },
    );
    return res['message']?.toString() ?? 'Registration successful.';
  }

  static Future<void> logout() async {
    try {
      await ApiClient.post(ApiConfig.logout);
    } catch (_) {
      // ignore network errors on logout, still clear local token
    }
    await ApiClient.setToken(null);
  }

  static Future<bool> isLoggedIn() async => (await ApiClient.getToken()) != null;
}
