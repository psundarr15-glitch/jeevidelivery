import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/root_shell.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});
  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _error;
  Timer? _cooldownTimer;
  int _cooldown = 0;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 1) {
        t.cancel();
        setState(() => _cooldown = 0);
      } else {
        setState(() => _cooldown--);
      }
    });
  }

  Future<void> _sendOtp() async {
    if (_phone.text.trim().length < 10) {
      setState(() => _error = 'Enter a valid mobile number');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.sendOtp(phone: _phone.text.trim(), purpose: 'login');
      setState(() => _otpSent = true);
      _startCooldown();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    if (_otp.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.loginWithOtp(phone: _phone.text.trim(), otp: _otp.text.trim());
      NotificationService.registerCurrentToken().catchError((_) {});
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const RootShell()), (r) => false);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login with OTP')),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _otpSent ? 'Enter the code sent to ${_phone.text}' : "We'll text you a one-time code",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _phone,
                enabled: !_otpSent,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone_android_outlined)),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _otp,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: '6-digit code', prefixIcon: Icon(Icons.sms_outlined), counterText: ''),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : (_otpSent ? _verify : _sendOtp),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_otpSent ? 'Verify & Login' : 'Send OTP'),
                ),
              ),
              if (_otpSent) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _cooldown > 0 || _loading ? null : _sendOtp,
                    child: Text(_cooldown > 0 ? 'Resend code in ${_cooldown}s' : 'Resend code', style: const TextStyle(color: AppTheme.primary)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
