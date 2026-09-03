import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{
    for (final key in [
      'name', 'email', 'password', 'phone', 'dob', 'city', 'district', 'pincode',
      'aadhaar_number', 'license_number', 'vehicle_number', 'rc_number',
      'bank_account_number', 'bank_ifsc', 'bank_account_holder',
    ])
      key: TextEditingController(),
  };
  String _vehicleType = 'bike';
  File? _photo;
  File? _idProof;
  File? _rcDocument;
  bool _loading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      final fields = _controllers.map((k, c) => MapEntry(k, c.text.trim()));
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

  InputDecoration _dec(String label) => InputDecoration(labelText: label);

  Widget _field(String key, String label, {TextInputType? type, bool required = true}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _controllers[key],
          keyboardType: type,
          decoration: _dec(label),
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
        ),
      );

  Widget _fileRow(String label, File? file, VoidCallback onPick) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(child: Text(file == null ? label : '$label: ${file.path.split('/').last}', overflow: TextOverflow.ellipsis)),
            OutlinedButton(onPressed: onPick, child: Text(file == null ? 'Upload' : 'Change')),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_success != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registration Submitted')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              Text(_success!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to Login')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Join as a Delivery Partner')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle('Basic details'),
                _field('name', 'Full name'),
                _field('email', 'Email', type: TextInputType.emailAddress),
                _field('password', 'Password'),
                _field('phone', 'Phone number', type: TextInputType.phone),
                TextFormField(
                  controller: _controllers['dob'],
                  readOnly: true,
                  onTap: _pickDob,
                  decoration: _dec('Date of birth').copyWith(suffixIcon: const Icon(Icons.calendar_today, size: 18)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                const _SectionTitle('Address'),
                _field('city', 'City'),
                _field('district', 'District'),
                _field('pincode', 'Pincode', type: TextInputType.number),

                const _SectionTitle('Vehicle & documents'),
                DropdownButtonFormField<String>(
                  initialValue: _vehicleType,
                  decoration: _dec('Vehicle type'),
                  items: const [
                    DropdownMenuItem(value: 'bike', child: Text('Bike')),
                    DropdownMenuItem(value: 'scooter', child: Text('Scooter')),
                    DropdownMenuItem(value: 'bicycle', child: Text('Bicycle')),
                  ],
                  onChanged: (v) => setState(() => _vehicleType = v ?? 'bike'),
                ),
                const SizedBox(height: 12),
                _field('vehicle_number', 'Vehicle number'),
                _field('rc_number', 'RC number'),
                _field('license_number', "Driving license number"),
                _field('aadhaar_number', 'Aadhaar number (12 digits)', type: TextInputType.number),
                _fileRow('Your photo', _photo, _pickPhoto),
                _fileRow('ID proof document', _idProof, () => _pickDocument((f) => setState(() => _idProof = f))),
                _fileRow('RC document', _rcDocument, () => _pickDocument((f) => setState(() => _rcDocument = f))),

                const _SectionTitle('Bank details (optional — add before your first payout)'),
                _field('bank_account_holder', 'Account holder name', required: false),
                _field('bank_account_number', 'Account number', required: false),
                _field('bank_ifsc', 'IFSC code', required: false),

                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Application'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 10),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary)),
      );
}
