import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';

/// Two-step registration wizard. Layout (progress bar, dashed-border
/// photo/document upload boxes, rounded outlined fields, pill submit
/// button) matches the reference "Delivery Man Registration" mockups —
/// just in the app's existing red/maroon theme instead of orange, and
/// keeping every field the backend's register() actually requires
/// (the mockups show a simplified subset).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _step = 0; // 0 = details, 1 = vehicle & documents
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _controllers = <String, TextEditingController>{
    for (final key in [
      'email', 'password', 'phone', 'dob', 'city', 'district', 'pincode',
      'aadhaar_number', 'license_number', 'vehicle_number', 'rc_number',
      'bank_account_number', 'bank_ifsc', 'bank_account_holder',
    ])
      key: TextEditingController(),
  };
  final _otpController = TextEditingController();
  String _vehicleType = 'bike';
  File? _photo;
  File? _idProof;
  File? _rcDocument;
  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  bool _loading = false;
  String? _error;
  String? _success;

  // Phone OTP verification, inline in step 1.
  bool _otpSent = false;
  bool _phoneVerified = false;
  bool _otpLoading = false;
  String? _otpError;
  Timer? _cooldownTimer;
  int _cooldown = 0;

  // Live password-strength checklist.
  String _password = '';

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    _otpController.dispose();
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

  Future<void> _sendPhoneOtp() async {
    final phone = _controllers['phone']!.text.trim();
    if (phone.length < 10) {
      setState(() => _otpError = 'Enter a valid mobile number first');
      return;
    }
    setState(() { _otpLoading = true; _otpError = null; });
    try {
      await AuthService.sendOtp(phone: phone, purpose: 'register');
      setState(() => _otpSent = true);
      _startCooldown();
    } catch (e) {
      setState(() => _otpError = e.toString());
    } finally {
      if (mounted) setState(() => _otpLoading = false);
    }
  }

  Future<void> _confirmPhoneOtp() async {
    if (_otpController.text.trim().length != 6) {
      setState(() => _otpError = 'Enter the 6-digit code');
      return;
    }
    setState(() { _otpLoading = true; _otpError = null; });
    try {
      await AuthService.verifyRegisterOtp(phone: _controllers['phone']!.text.trim(), otp: _otpController.text.trim());
      setState(() => _phoneVerified = true);
    } catch (e) {
      setState(() => _otpError = e.toString());
    } finally {
      if (mounted) setState(() => _otpLoading = false);
    }
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1960),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null) {
      _controllers['dob']!.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _pickDocument(void Function(File) onPicked) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf']);
    if (result != null && result.files.single.path != null) {
      onPicked(File(result.files.single.path!));
    }
  }

  void _goToStep2() {
    if (!_phoneVerified) {
      setState(() => _otpError = 'Please verify your mobile number first');
      return;
    }
    if (!_step1Key.currentState!.validate()) return;
    setState(() => _step = 1);
  }

  Future<void> _submit() async {
    if (!_step2Key.currentState!.validate()) return;
    if (!_agreedToTerms) {
      setState(() => _error = 'Please agree to the Terms & Conditions to continue.');
      return;
    }
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      final fields = _controllers.map((k, c) => MapEntry(k, c.text.trim()));
      fields['name'] = '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim();
      fields['vehicle_type'] = _vehicleType;
      final message = await AuthService.register(
        fields: fields,
        photo: _photo,
        idProofDocument: _idProof,
        rcDocument: _rcDocument,
      );
      if (!mounted) return;
      setState(() => _success = message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_success != null) return _SuccessView(message: _success!);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Delivery Man Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Complete registration process to serve as a delivery partner on this platform', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              const SizedBox(height: 16),
              _ProgressBar(step: _step),
              const SizedBox(height: 24),
              if (_step == 0) _buildStep1() else _buildStep2(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _PhotoUpload(photo: _photo, onPick: _pickPhoto, onRemove: () => setState(() => _photo = null))),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstName,
                  decoration: const InputDecoration(labelText: 'First Name', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastName,
                  decoration: const InputDecoration(labelText: 'Last Name', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PhoneVerificationField(
            controller: _controllers['phone']!,
            otpController: _otpController,
            otpSent: _otpSent,
            phoneVerified: _phoneVerified,
            loading: _otpLoading,
            cooldown: _cooldown,
            error: _otpError,
            onSendOtp: _sendPhoneOtp,
            onConfirmOtp: _confirmPhoneOtp,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _controllers['email'],
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _controllers['dob'],
            readOnly: true,
            onTap: _pickDob,
            decoration: const InputDecoration(labelText: 'Date of Birth', prefixIcon: Icon(Icons.calendar_today_outlined)),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _controllers['password'],
            obscureText: _obscurePassword,
            onChanged: (v) => setState(() => _password = v),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) => _passwordChecks(v ?? '').every((c) => c.$2) ? null : 'Password does not meet all requirements',
          ),
          const SizedBox(height: 8),
          _PasswordChecklist(checks: _passwordChecks(_password)),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goToStep2,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }

  List<(String, bool)> _passwordChecks(String v) => [
        ('8 or more characters', v.length >= 8),
        ('1 number', RegExp(r'[0-9]').hasMatch(v)),
        ('1 upper case', RegExp(r'[A-Z]').hasMatch(v)),
        ('1 lower case', RegExp(r'[a-z]').hasMatch(v)),
        ('1 special character', RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\[\]/\\+=~`;]').hasMatch(v)),
      ];

  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controllers['city'],
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _controllers['district'],
                  decoration: const InputDecoration(labelText: 'District'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _controllers['pincode'],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Pincode'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _vehicleType,
            decoration: const InputDecoration(labelText: 'Vehicle Type'),
            items: const [
              DropdownMenuItem(value: 'bike', child: Text('Bike')),
              DropdownMenuItem(value: 'scooter', child: Text('Scooter')),
              DropdownMenuItem(value: 'bicycle', child: Text('Bicycle')),
            ],
            onChanged: (v) => setState(() => _vehicleType = v ?? 'bike'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _controllers['vehicle_number'],
            decoration: const InputDecoration(labelText: 'Vehicle Number'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _controllers['rc_number'],
            decoration: const InputDecoration(labelText: 'RC Number'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _controllers['license_number'],
            decoration: const InputDecoration(labelText: 'Driving License Number', hintText: 'L-XXX-XXX-XXX-XXX'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _controllers['aadhaar_number'],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Aadhaar Number (12 digits)'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 20),
          _DocumentUpload(label: 'Upload ID Proof Document', file: _idProof, onPick: () => _pickDocument((f) => setState(() => _idProof = f)), onRemove: () => setState(() => _idProof = null)),
          const SizedBox(height: 14),
          _DocumentUpload(label: 'Upload RC Document', file: _rcDocument, onPick: () => _pickDocument((f) => setState(() => _rcDocument = f)), onRemove: () => setState(() => _rcDocument = null)),
          const SizedBox(height: 22),
          Text('Bank details (optional — add before your first payout)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextFormField(controller: _controllers['bank_account_holder'], decoration: const InputDecoration(labelText: 'Account Holder Name')),
          const SizedBox(height: 14),
          TextFormField(controller: _controllers['bank_account_number'], decoration: const InputDecoration(labelText: 'Account Number')),
          const SizedBox(height: 14),
          TextFormField(controller: _controllers['bank_ifsc'], decoration: const InputDecoration(labelText: 'IFSC Code')),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: _agreedToTerms, activeColor: AppTheme.primary, onChanged: (v) => setState(() => _agreedToTerms = v ?? false)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey.shade800, fontSize: 13.5),
                      children: [
                        const TextSpan(text: 'By registering I agree with all the '),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Terms & Conditions'),
                                content: const Text('Full terms & conditions for delivery partners will be published here.'),
                                actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                              ),
                            ),
                            child: const Text('Terms & Conditions', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int step; // 0 or 1
  const _ProgressBar({required this.step});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(width: 4),
        Expanded(child: Container(height: 4, decoration: BoxDecoration(color: step == 1 ? AppTheme.primary : Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
      ],
    );
  }
}

class _PhotoUpload extends StatelessWidget {
  final File? photo;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  const _PhotoUpload({required this.photo, required this.onPick, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Stack(
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary, width: 1.4, style: photo == null ? BorderStyle.solid : BorderStyle.none),
              color: const Color(0xFFFFF3EC),
              image: photo != null ? DecorationImage(image: FileImage(photo!), fit: BoxFit.cover) : null,
            ),
            child: photo == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt_outlined, color: AppTheme.primary, size: 30),
                      const SizedBox(height: 8),
                      Text('Upload Photo', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
                    ],
                  )
                : null,
          ),
          if (photo != null)
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: const CircleAvatar(radius: 15, backgroundColor: AppTheme.primary, child: Icon(Icons.remove, color: Colors.white, size: 18)),
              ),
            ),
        ],
      ),
    );
  }
}

class _DocumentUpload extends StatelessWidget {
  final String label;
  final File? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  const _DocumentUpload({required this.label, required this.file, required this.onPick, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primary, width: 1.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: file == null
            ? Column(
                children: [
                  const Icon(Icons.camera_alt_outlined, color: AppTheme.primary, size: 30),
                  const SizedBox(height: 8),
                  Text(label, style: TextStyle(color: Colors.grey.shade600)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Flexible(child: Text(file!.path.split('/').last, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  GestureDetector(onTap: onRemove, child: const Icon(Icons.close, size: 18, color: Colors.grey)),
                ],
              ),
      ),
    );
  }
}

class _PasswordChecklist extends StatelessWidget {
  final List<(String, bool)> checks;
  const _PasswordChecklist({required this.checks});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: checks
          .map((c) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(c.$2 ? Icons.check : Icons.close, size: 14, color: c.$2 ? Colors.green : Colors.red),
                  const SizedBox(width: 3),
                  Text(c.$1, style: TextStyle(fontSize: 11.5, color: c.$2 ? Colors.green.shade700 : Colors.red.shade700)),
                ],
              ))
          .toList(),
    );
  }
}

class _PhoneVerificationField extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController otpController;
  final bool otpSent;
  final bool phoneVerified;
  final bool loading;
  final int cooldown;
  final String? error;
  final VoidCallback onSendOtp;
  final VoidCallback onConfirmOtp;

  const _PhoneVerificationField({
    required this.controller,
    required this.otpController,
    required this.otpSent,
    required this.phoneVerified,
    required this.loading,
    required this.cooldown,
    required this.error,
    required this.onSendOtp,
    required this.onConfirmOtp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled: !otpSent && !phoneVerified,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Text('🇮🇳 +91', style: TextStyle(fontSize: 14)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0),
                  suffixIcon: phoneVerified ? const Icon(Icons.check_circle, color: Colors.green) : null,
                ),
                validator: (v) => (v == null || v.trim().length < 10) ? 'Enter a valid mobile number' : null,
              ),
            ),
            if (!phoneVerified) ...[
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: loading || (otpSent && cooldown > 0) ? null : onSendOtp,
                child: Text(otpSent ? (cooldown > 0 ? '${cooldown}s' : 'Resend') : 'Send OTP'),
              ),
            ],
          ],
        ),
        if (otpSent && !phoneVerified) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: '6-digit code', counterText: ''),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: loading ? null : onConfirmOtp,
                child: loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm'),
              ),
            ],
          ),
        ],
        if (phoneVerified)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Mobile number verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12.5)),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
          ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String message;
  const _SuccessView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration Submitted')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to Login')),
          ],
        ),
      ),
    );
  }
}
