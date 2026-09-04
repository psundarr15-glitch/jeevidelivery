import 'dart:io';
import '../config/api_config.dart';
import 'api_client.dart';

class AuthService {
  static Future<Map<String, dynamic>> login({required String phone, required String password}) async {
    final res = await ApiClient.post(ApiConfig.login, {'phone': phone, 'password': password});
    await ApiClient.setToken(res['token']?.toString());
    return res['partner'] as Map<String, dynamic>;
  }

  /// purpose is 'login' or 'register' — see DeliveryOtpModel on the backend.
  static Future<void> sendOtp({required String phone, required String purpose}) async {
    await ApiClient.post(ApiConfig.otpSend, {'phone': phone, 'purpose': purpose});
  }

  static Future<Map<String, dynamic>> loginWithOtp({required String phone, required String otp}) async {
    final res = await ApiClient.post(ApiConfig.otpLogin, {'phone': phone, 'otp': otp});
    await ApiClient.setToken(res['token']?.toString());
    return res['partner'] as Map<String, dynamic>;
  }

  /// Verifies the phone-ownership OTP shown during registration. The
  /// backend remembers this for a few minutes so the register() call
  /// right after doesn't need to carry any extra proof-of-verification
  /// token around — it just re-checks the same phone number.
  static Future<void> verifyRegisterOtp({required String phone, required String otp}) async {
    await ApiClient.post(ApiConfig.otpVerifyRegister, {'phone': phone, 'otp': otp});
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
