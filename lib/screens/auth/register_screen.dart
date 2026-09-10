import 'dart:async';
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
  int _step = 0;

  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  final _controllers = <String, TextEditingController>{
    for (final key in [
      'email',
      'password',
      'phone',
      'dob',
      'city',
      'district',
      'pincode',
      'aadhaar_number',
      'license_number',
      'vehicle_number',
      'rc_number',
      'bank_account_number',
      'bank_ifsc',
      'bank_account_holder',
    ])
      key: TextEditingController(),
  };

  final _otpController = TextEditingController();

  final FocusNode _otpFocusNode = FocusNode();

  String _vehicleType = 'bike';

  File? _photo;
  File? _idProof;
  File? _rcDocument;

  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  bool _loading = false;

  String? _error;
  String? _success;

  bool _otpSent = false;
  bool _phoneVerified = false;
  bool _otpLoading = false;

  String? _otpError;

  Timer? _cooldownTimer;
  int _cooldown = 0;

  String _password = '';

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();

    for (final controller in _controllers.values) {
      controller.dispose();
    }

    _otpController.dispose();
    _otpFocusNode.dispose();
    _cooldownTimer?.cancel();

    super.dispose();
  }

  // ─────────────────────────────────────────────
  // OTP
  // ─────────────────────────────────────────────

  void _startCooldown() {
    setState(() {
      _cooldown = 30;
    });

    _cooldownTimer?.cancel();

    _cooldownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_cooldown <= 1) {
          timer.cancel();

          setState(() {
            _cooldown = 0;
          });
        } else {
          setState(() {
            _cooldown--;
          });
        }
      },
    );
  }

  Future<void> _sendPhoneOtp() async {
    final phone = _controllers['phone']!.text.trim();

    if (phone.length < 10) {
      setState(() {
        _otpError = 'Enter a valid mobile number first';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _otpLoading = true;
      _otpError = null;
    });

    try {
      await AuthService.sendOtp(
        phone: phone,
        purpose: 'register',
      );

      if (!mounted) return;

      setState(() {
        _otpSent = true;
      });

      _startCooldown();

      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          _otpFocusNode.requestFocus();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _otpError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _otpLoading = false;
        });
      }
    }
  }

  Future<void> _confirmPhoneOtp() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() {
        _otpError = 'Enter the 6-digit code';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _otpLoading = true;
      _otpError = null;
    });

    try {
      await AuthService.verifyRegisterOtp(
        phone: _controllers['phone']!.text.trim(),
        otp: otp,
      );

      if (!mounted) return;

      setState(() {
        _phoneVerified = true;
        _otpError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _otpError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _otpLoading = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────
  // DATE
  // ─────────────────────────────────────────────

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1960),
      lastDate: DateTime.now().subtract(
        const Duration(days: 365 * 18),
      ),
    );

    if (picked == null) return;

    _controllers['dob']!.text =
        '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';

    setState(() {});
  }

  // ─────────────────────────────────────────────
  // FILES
  // ─────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked != null) {
      setState(() {
        _photo = File(picked.path);
      });
    }
  }

  Future<void> _pickDocument(
    void Function(File) onPicked,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'pdf',
      ],
    );

    if (result != null &&
        result.files.single.path != null) {
      onPicked(
        File(result.files.single.path!),
      );
    }
  }

  // ─────────────────────────────────────────────
  // STEP NAVIGATION
  // ─────────────────────────────────────────────

  void _goToStep2() {
    if (!_phoneVerified) {
      setState(() {
        _otpError =
            'Please verify your mobile number first';
      });
      return;
    }

    if (!_step1Key.currentState!.validate()) {
      return;
    }

    setState(() {
      _step = 1;
      _error = null;
    });
  }

  void _goBack() {
    if (_step == 1) {
      setState(() {
        _step = 0;
        _error = null;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  // ─────────────────────────────────────────────
  // SUBMIT
  // ─────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_step2Key.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      setState(() {
        _error =
            'Please agree to the Terms & Conditions to continue.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      final fields = _controllers.map(
        (key, controller) =>
            MapEntry(key, controller.text.trim()),
      );

      fields['name'] =
          '${_firstName.text.trim()} ${_lastName.text.trim()}'
              .trim();

      fields['vehicle_type'] = _vehicleType;

      // Backend still expects rc_number.
      fields['rc_number'] =
          fields['vehicle_number'] ?? '';

      final message = await AuthService.register(
        fields: fields,
        photo: _photo,
        idProofDocument: _idProof,
        rcDocument: _rcDocument,
      );

      if (!mounted) return;

      setState(() {
        _success = message;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_success != null) {
      return _SuccessView(
        message: _success!,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
        ),
        title: const Text(
          'Partner Registration',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            18,
            8,
            18,
            35,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 20),

              _ProgressHeader(
                step: _step,
              ),

              const SizedBox(height: 20),

              if (_step == 0)
                _buildStep1()
              else
                _buildStep2(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE53935),
            Color(0xFFD81B27),
            Color(0xFFB71C1C),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.primary.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Become a Partner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Complete your registration to get started.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STEP 1
  // ─────────────────────────────────────────────

  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: _FormCard(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.person_outline_rounded,
              title: 'Personal Details',
              subtitle:
                  'Tell us a little about yourself',
            ),

            const SizedBox(height: 24),

            Center(
              child: _PhotoUpload(
                photo: _photo,
                onPick: _pickPhoto,
                onRemove: () {
                  setState(() {
                    _photo = null;
                  });
                },
              ),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: _firstName,
                    label: 'First Name',
                    hint: 'First name',
                    icon: Icons.person_outline_rounded,
                    validator: (v) {
                      return v == null ||
                              v.trim().isEmpty
                          ? 'Required'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    controller: _lastName,
                    label: 'Last Name',
                    hint: 'Last name',
                    icon: Icons.person_outline_rounded,
                    validator: (v) {
                      return v == null ||
                              v.trim().isEmpty
                          ? 'Required'
                          : null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _PhoneVerificationField(
              controller: _controllers['phone']!,
              otpController: _otpController,
              otpFocusNode: _otpFocusNode,
              otpSent: _otpSent,
              phoneVerified: _phoneVerified,
              loading: _otpLoading,
              cooldown: _cooldown,
              error: _otpError,
              onSendOtp: _sendPhoneOtp,
              onConfirmOtp: _confirmPhoneOtp,
            ),

            const SizedBox(height: 18),

            _textField(
              controller: _controllers['email']!,
              label: 'Email Address',
              hint: 'example@email.com',
              icon: Icons.mail_outline_rounded,
              keyboardType:
                  TextInputType.emailAddress,
              validator: (v) {
                if (v == null ||
                    v.trim().isEmpty) {
                  return 'Required';
                }

                if (!v.contains('@')) {
                  return 'Enter a valid email';
                }

                return null;
              },
            ),

            const SizedBox(height: 18),

            _textField(
              controller: _controllers['dob']!,
              label: 'Date of Birth',
              hint: 'Select your date of birth',
              icon: Icons.calendar_month_rounded,
              readOnly: true,
              onTap: _pickDob,
              validator: (v) {
                return v == null || v.isEmpty
                    ? 'Required'
                    : null;
              },
            ),

            const SizedBox(height: 18),

            _textField(
              controller: _controllers['password']!,
              label: 'Password',
              hint: 'Create a strong password',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              onChanged: (value) {
                setState(() {
                  _password = value;
                });
              },
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword =
                        !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade500,
                ),
              ),
              validator: (v) {
                return _passwordChecks(v ?? '')
                        .every((item) => item.$2)
                    ? null
                    : 'Password does not meet all requirements';
              },
            ),

            const SizedBox(height: 12),

            _PasswordChecklist(
              checks: _passwordChecks(_password),
            ),

            const SizedBox(height: 28),

            _PrimaryButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              onPressed: _goToStep2,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STEP 2
  // ─────────────────────────────────────────────

  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: _FormCard(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.two_wheeler_rounded,
              title: 'Vehicle & Documents',
              subtitle:
                  'Add your vehicle and verification details',
            ),

            const SizedBox(height: 24),

            _SectionLabel(
              icon: Icons.location_on_outlined,
              text: 'Location',
            ),

            const SizedBox(height: 13),

            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller:
                        _controllers['city']!,
                    label: 'City',
                    hint: 'City',
                    icon:
                        Icons.location_city_outlined,
                    validator: (v) {
                      return v == null ||
                              v.trim().isEmpty
                          ? 'Required'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    controller:
                        _controllers['district']!,
                    label: 'District',
                    hint: 'District',
                    icon: Icons.map_outlined,
                    validator: (v) {
                      return v == null ||
                              v.trim().isEmpty
                          ? 'Required'
                          : null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _textField(
              controller: _controllers['pincode']!,
              label: 'Pincode',
              hint: '6-digit pincode',
              icon: Icons.pin_drop_outlined,
              keyboardType: TextInputType.number,
              validator: (v) {
                return v == null ||
                        v.trim().length != 6
                    ? 'Enter valid pincode'
                    : null;
              },
            ),

            const SizedBox(height: 26),

            _SectionLabel(
              icon: Icons.two_wheeler_outlined,
              text: 'Vehicle Information',
            ),

            const SizedBox(height: 13),

            DropdownButtonFormField<String>(
              initialValue: _vehicleType,
              decoration: _inputDecoration(
                label: 'Vehicle Type',
                hint: 'Select vehicle',
                icon:
                    Icons.directions_bike_outlined,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'bike',
                  child: Text('Bike'),
                ),
                DropdownMenuItem(
                  value: 'scooter',
                  child: Text('Scooter'),
                ),
                DropdownMenuItem(
                  value: 'bicycle',
                  child: Text('Bicycle'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _vehicleType =
                      value ?? 'bike';
                });
              },
            ),

            const SizedBox(height: 18),

            _textField(
              controller:
                  _controllers['vehicle_number']!,
              label: 'Vehicle Number',
              hint: 'TN XX XX XXXX',
              icon: Icons.pin_outlined,
              textCapitalization:
                  TextCapitalization.characters,
              validator: (v) {
                return v == null ||
                        v.trim().isEmpty
                    ? 'Required'
                    : null;
              },
            ),

            const SizedBox(height: 18),

            _textField(
              controller:
                  _controllers['license_number']!,
              label: 'Driving License Number',
              hint: 'Enter license number',
              icon: Icons.credit_card_outlined,
              textCapitalization:
                  TextCapitalization.characters,
              validator: (v) {
                return v == null ||
                        v.trim().isEmpty
                    ? 'Required'
                    : null;
              },
            ),

            const SizedBox(height: 18),

            _textField(
              controller:
                  _controllers['aadhaar_number']!,
              label: 'Aadhaar Number',
              hint: '12-digit Aadhaar number',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              validator: (v) {
                return v == null ||
                        v.trim().length != 12
                    ? 'Enter 12-digit Aadhaar number'
                    : null;
              },
            ),

            const SizedBox(height: 26),

            _SectionLabel(
              icon: Icons.upload_file_rounded,
              text: 'Verification Documents',
            ),

            const SizedBox(height: 13),

            _DocumentUpload(
              label: 'Upload ID Proof',
              subtitle:
                  'Aadhaar / valid identity document',
              file: _idProof,
              onPick: () => _pickDocument(
                (file) {
                  setState(() {
                    _idProof = file;
                  });
                },
              ),
              onRemove: () {
                setState(() {
                  _idProof = null;
                });
              },
            ),

            const SizedBox(height: 14),

            _DocumentUpload(
              label: 'Upload RC Document',
              subtitle:
                  'Vehicle registration certificate',
              file: _rcDocument,
              onPick: () => _pickDocument(
                (file) {
                  setState(() {
                    _rcDocument = file;
                  });
                },
              ),
              onRemove: () {
                setState(() {
                  _rcDocument = null;
                });
              },
            ),

            const SizedBox(height: 8),

            Text(
              'Accepted: PDF, JPG, JPEG and PNG',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11.5,
              ),
            ),

            const SizedBox(height: 27),

            _SectionLabel(
              icon: Icons.account_balance_outlined,
              text: 'Bank Details',
            ),

            const SizedBox(height: 5),

            Text(
              'Optional — you can add these before your first payout.',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11.5,
              ),
            ),

            const SizedBox(height: 15),

            _textField(
              controller: _controllers[
                  'bank_account_holder']!,
              label: 'Account Holder Name',
              hint: 'Name as per bank account',
              icon: Icons.person_outline_rounded,
            ),

            const SizedBox(height: 18),

            _textField(
              controller:
                  _controllers['bank_account_number']!,
              label: 'Account Number',
              hint: 'Enter bank account number',
              icon: Icons.account_balance_outlined,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 18),

            _textField(
              controller:
                  _controllers['bank_ifsc']!,
              label: 'IFSC Code',
              hint: 'Enter IFSC code',
              icon: Icons.code_rounded,
              textCapitalization:
                  TextCapitalization.characters,
            ),

            const SizedBox(height: 23),

            // Terms
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FB),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    activeColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(5),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _agreedToTerms =
                            value ?? false;
                        _error = null;
                      });
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.only(top: 11),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color:
                                Colors.grey.shade700,
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                          children: [
                            const TextSpan(
                              text:
                                  'I agree to the ',
                            ),
                            WidgetSpan(
                              alignment:
                                  PlaceholderAlignment
                                      .middle,
                              child: GestureDetector(
                                onTap:
                                    _showTerms,
                                child:
                                    const Text(
                                  'Terms & Conditions',
                                  style: TextStyle(
                                    color:
                                        AppTheme.primary,
                                    fontWeight:
                                        FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(
                              text:
                                  ' and partner policies.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              _ErrorBox(
                message: _error!,
              ),
            ],

            const SizedBox(height: 20),

            _PrimaryButton(
              label: 'Submit Registration',
              icon: Icons.check_circle_outline_rounded,
              loading: _loading,
              onPressed:
                  _loading ? null : _submit,
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed:
                    _loading ? null : () {
                  setState(() {
                    _step = 0;
                    _error = null;
                  });
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Back to Personal Details',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      AppTheme.primary,
                  side: BorderSide(
                    color: AppTheme.primary
                        .withOpacity(0.25),
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TERMS
  // ─────────────────────────────────────────────

  void _showTerms() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Terms & Conditions',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Full terms and conditions for delivery partners will be published here.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // COMMON FIELD
  // ─────────────────────────────────────────────

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool readOnly = false,
    Widget? suffixIcon,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    TextCapitalization textCapitalization =
        TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        icon: icon,
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 12.5,
      ),
      labelStyle: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: Colors.grey.shade500,
        size: 20,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppTheme.primary,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.3,
        ),
      ),
    );
  }

  List<(String, bool)> _passwordChecks(
    String value,
  ) {
    return [
      (
        '8+ characters',
        value.length >= 8,
      ),
      (
        '1 number',
        RegExp(r'[0-9]').hasMatch(value),
      ),
      (
        '1 uppercase',
        RegExp(r'[A-Z]').hasMatch(value),
      ),
      (
        '1 lowercase',
        RegExp(r'[a-z]').hasMatch(value),
      ),
      (
        '1 special',
        RegExp(
          r'''[!@#$%^&*(),.?":{}|<>_\-\[\]/\\+=~`;]''',
        ).hasMatch(value),
      ),
    ];
  }
}

// ═══════════════════════════════════════════════
// FORM CARD
// ═══════════════════════════════════════════════

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.045),
            blurRadius: 25,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════
// SECTION TITLE
// ═══════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color:
                AppTheme.primary.withOpacity(0.08),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: AppTheme.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// SECTION LABEL
// ═══════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SectionLabel({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: AppTheme.primary,
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// PROGRESS
// ═══════════════════════════════════════════════

class _ProgressHeader extends StatelessWidget {
  final int step;

  const _ProgressHeader({
    required this.step,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          _StepItem(
            number: '1',
            title: 'Personal',
            active: step >= 0,
            completed: step > 0,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin:
                  const EdgeInsets.symmetric(
                horizontal: 8,
              ),
              color: step > 0
                  ? AppTheme.primary
                  : Colors.grey.shade200,
            ),
          ),
          _StepItem(
            number: '2',
            title: 'Documents',
            active: step == 1,
            completed: false,
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String title;
  final bool active;
  final bool completed;

  const _StepItem({
    required this.number,
    required this.title,
    required this.active,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration:
              const Duration(milliseconds: 250),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? AppTheme.primary
                : Colors.grey.shade100,
          ),
          child: Icon(
            completed
                ? Icons.check_rounded
                : Icons.circle,
            color: active
                ? Colors.white
                : Colors.grey.shade400,
            size: completed ? 18 : 8,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: active
                ? AppTheme.primary
                : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// PHOTO
// ═══════════════════════════════════════════════

class _PhotoUpload extends StatelessWidget {
  final File? photo;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _PhotoUpload({
    required this.photo,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Stack(
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  AppTheme.primary.withOpacity(0.06),
              border: Border.all(
                color: AppTheme.primary
                    .withOpacity(0.35),
                width: 1.5,
              ),
              image: photo != null
                  ? DecorationImage(
                      image: FileImage(photo!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: photo == null
                ? Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration:
                            const BoxDecoration(
                          color:
                              AppTheme.primary,
                          shape:
                              BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          if (photo != null)
            Positioned(
              right: 0,
              bottom: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration:
                      const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// DOCUMENT
// ═══════════════════════════════════════════════

class _DocumentUpload extends StatelessWidget {
  final String label;
  final String subtitle;
  final File? file;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _DocumentUpload({
    required this.label,
    required this.subtitle,
    required this.file,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;

    return GestureDetector(
      onTap: hasFile ? null : onPick,
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFile
              ? Colors.green.withOpacity(0.045)
              : AppTheme.primary.withOpacity(0.025),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile
                ? Colors.green.withOpacity(0.35)
                : AppTheme.primary
                    .withOpacity(0.25),
          ),
        ),
        child: hasFile
            ? Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 25,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Document uploaded',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          file!.path
                              .split('/')
                              .last,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.grey,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: AppTheme.primary
                          .withOpacity(0.08),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.upload_file_rounded,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color:
                                Colors.grey.shade500,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey,
                  ),
                ],
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// PASSWORD
// ═══════════════════════════════════════════════

class _PasswordChecklist
    extends StatelessWidget {
  final List<(String, bool)> checks;

  const _PasswordChecklist({
    required this.checks,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 7,
      children: checks.map((item) {
        final valid = item.$2;

        return Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: valid
                ? Colors.green.withOpacity(0.07)
                : Colors.grey.withOpacity(0.07),
            borderRadius:
                BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                valid
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 13,
                color: valid
                    ? Colors.green
                    : Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                item.$1,
                style: TextStyle(
                  fontSize: 10.5,
                  color: valid
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════
// PHONE OTP
// ═══════════════════════════════════════════════

class _PhoneVerificationField
    extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController otpController;
  final FocusNode otpFocusNode;

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
    required this.otpFocusNode,
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
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled:
                    !otpSent && !phoneVerified,
                keyboardType:
                    TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: '10-digit mobile number',
                  prefixIcon: const Padding(
                    padding:
                        EdgeInsets.only(left: 13),
                    child: Icon(
                      Icons.phone_android_rounded,
                      size: 20,
                    ),
                  ),
                  suffixIcon: phoneVerified
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                        )
                      : null,
                  filled: true,
                  fillColor:
                      const Color(0xFFF8F9FB),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color:
                          Colors.grey.shade200,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(
                      color: AppTheme.primary,
                      width: 1.4,
                    ),
                  ),
                ),
                validator: (v) {
                  return v == null ||
                          v.trim().length < 10
                      ? 'Enter a valid mobile number'
                      : null;
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed:
                    loading ||
                            (otpSent &&
                                cooldown > 0)
                        ? null
                        : onSendOtp,
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      AppTheme.primary,
                  side: BorderSide(
                    color: AppTheme.primary
                        .withOpacity(0.3),
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                ),
                child: Text(
                  otpSent
                      ? (cooldown > 0
                          ? '${cooldown}s'
                          : 'Resend')
                      : 'Send OTP',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),

        if (otpSent && !phoneVerified) ...[
          const SizedBox(height: 11),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: otpController,
                  focusNode: otpFocusNode,
                  keyboardType:
                      TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight:
                        FontWeight.w800,
                    letterSpacing: 7,
                  ),
                  decoration:
                      InputDecoration(
                    labelText:
                        '6-digit OTP',
                    hintText: '••••••',
                    counterText: '',
                    filled: true,
                    fillColor:
                        const Color(0xFFFFF8F7),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                              14),
                      borderSide:
                          BorderSide.none,
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                              14),
                      borderSide:
                          const BorderSide(
                        color:
                            AppTheme.primary,
                        width: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : onConfirmOtp,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppTheme.primary,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                              13),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],

        if (phoneVerified)
          Container(
            margin:
                const EdgeInsets.only(top: 8),
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color:
                  Colors.green.withOpacity(0.07),
              borderRadius:
                  BorderRadius.circular(9),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  color: Colors.green,
                  size: 15,
                ),
                SizedBox(width: 5),
                Text(
                  'Mobile number verified',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11.5,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

        if (error != null)
          Padding(
            padding:
                const EdgeInsets.only(top: 7),
            child: Text(
              error!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 11.5,
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// PRIMARY BUTTON
// ═══════════════════════════════════════════════

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AppTheme.primary.withOpacity(0.55),
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    icon,
                    size: 19,
                  ),
                ],
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// ERROR
// ═══════════════════════════════════════════════

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.055),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: Colors.red.withOpacity(0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// SUCCESS
// ═══════════════════════════════════════════════

class _SuccessView extends StatelessWidget {
  final String message;

  const _SuccessView({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.05),
                    blurRadius: 25,
                    offset:
                        const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  Container(
                    width: 82,
                    height: 82,
                    decoration:
                        BoxDecoration(
                      color: Colors.green
                          .withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 55,
                    ),
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Registration Submitted!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 25),

                  _PrimaryButton(
                    label: 'Back to Login',
                    icon:
                        Icons.arrow_forward_rounded,
                    onPressed: () =>
                        Navigator.of(context)
                            .pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}