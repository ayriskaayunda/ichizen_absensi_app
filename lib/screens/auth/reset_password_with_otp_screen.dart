import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ichizen/constants/app_colors.dart';
import 'package:ichizen/constants/app_text_styles.dart';
import 'package:ichizen/routes/app_routes.dart';
import 'package:ichizen/services/api_services.dart';
import 'package:ichizen/widgets/custom_input_field.dart';
import 'package:ichizen/widgets/primary_button.dart';

class ResetPasswordWithOtpScreen extends StatefulWidget {
  final String email; // Email passed from ForgotPasswordScreen

  const ResetPasswordWithOtpScreen({super.key, required this.email});

  @override
  State<ResetPasswordWithOtpScreen> createState() =>
      _ResetPasswordWithOtpScreenState();
}

class _ResetPasswordWithOtpScreenState
    extends State<ResetPasswordWithOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Timer related variables
  Timer? _otpTimer;
  int _remainingSeconds = 600; // 10 minutes in seconds

  @override
  void initState() {
    super.initState();
    _startOtpTimer();
  }

  @override
  void dispose() {
    _otpTimer?.cancel(); // Cancel the timer when the widget is disposed
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    _remainingSeconds = 600; // Reset to 10 minutes
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _otpTimer?.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  Future<void> _requestNewOtp() async {
    setState(() {
      _isLoading = true;
    });

    final response = await _apiService.forgotPassword(email: widget.email);

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      _showSnackBar(response.message);
      _startOtpTimer(); // Restart the timer
    } else {
      String errorMessage = response.message;
      if (response.errors != null) {
        response.errors!.forEach((key, value) {
          errorMessage += '\n$key: ${(value as List).join(', ')}';
        });
      }
      _showSnackBar(errorMessage);
    }
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      if (_remainingSeconds == 0) {
        _showSnackBar('OTP has expired. Please request a new one.');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final String otp = _otpController.text.trim();
      final String newPassword = _newPasswordController.text.trim();
      final String confirmPassword = _confirmPasswordController.text.trim();

      final response = await _apiService.resetPassword(
        email: widget.email,
        otp: otp,
        newPassword: newPassword,
        newPasswordConfirmation: confirmPassword,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        _showSnackBar(response.message);
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } else {
        String errorMessage = response.message;
        if (response.errors != null) {
          response.errors!.forEach((key, value) {
            errorMessage += '\n$key: ${(value as List).join(', ')}';
          });
        }
        _showSnackBar(errorMessage);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bool otpExpired = _remainingSeconds == 0;

    return Scaffold(
      backgroundColor: Colors.transparent,

      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Reset Password',
          style: TextStyle(
            color: Color(0xFF624F82),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE0BBE4), Color(0xFFF0E6EF), Color(0xFFAFDCEB)],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24.0,
            MediaQuery.of(context).padding.top + kToolbarHeight + 24.0,
            24.0,
            24.0,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Enter OTP and New Password",
                  style: AppTextStyles.heading,
                ),
                const SizedBox(height: 10),
                Text(
                  "An OTP has been sent to ${widget.email}. Please enter it below along with your new password.",
                  style: AppTextStyles.normal,
                ),
                const SizedBox(height: 30),
                CustomInputField(
                  controller: TextEditingController(text: widget.email),
                  hintText: 'Email',
                  labelText: 'Email Address',
                  icon: Icons.email_outlined,
                  readOnly: true,
                ),
                const SizedBox(height: 20),
                CustomInputField(
                  controller: _otpController,
                  hintText: 'OTP',
                  labelText: 'One-Time Password (OTP)',
                  icon: Icons.vpn_key_outlined,
                  keyboardType: TextInputType.number,
                  customValidator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'OTP cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    otpExpired
                        ? 'OTP Expired'
                        : 'OTP expires in ${_formatTime(_remainingSeconds)}',
                    style: TextStyle(
                      color: otpExpired ? AppColors.error : AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CustomInputField(
                  controller: _newPasswordController,
                  hintText: 'New Password',
                  labelText: 'New Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: !_isNewPasswordVisible,
                  toggleVisibility: () {
                    setState(() {
                      _isNewPasswordVisible = !_isNewPasswordVisible;
                    });
                  },
                  customValidator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'New password cannot be empty';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                CustomInputField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm New Password',
                  labelText: 'Confirm New Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: !_isConfirmPasswordVisible,
                  toggleVisibility: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                  customValidator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirm password cannot be empty';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF624F82),
                        ),
                      )
                    : PrimaryButton(
                        label: 'Reset Password',
                        onPressed: otpExpired
                            ? () {} // Disabled if OTP expired
                            : () => _resetPassword(),
                      ),
                if (otpExpired)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Center(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null // Disabled if loading
                            : () => _requestNewOtp(),
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: Color(0xFF624F82),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
