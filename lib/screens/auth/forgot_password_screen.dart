import 'package:flutter/material.dart';
import 'package:ichizen/constants/app_text_styles.dart';
import 'package:ichizen/routes/app_routes.dart';
import 'package:ichizen/services/api_services.dart';
import 'package:ichizen/widgets/custom_input_field.dart';
import 'package:ichizen/widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _requestOtp() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showSnackBar('Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text.trim();
    final response = await _apiService.forgotPassword(email: email);

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      _showSnackBar(response.message);
      if (mounted) {
        Navigator.pushNamed(
          context,
          AppRoutes.resetPasswordWithOtp,
          arguments: email,
        );
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            color: Color(0xFF624F82),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Reset Your Password", style: AppTextStyles.heading),
              const SizedBox(height: 10),
              const Text(
                "Enter your email address to receive a one-time password (OTP).",
                style: AppTextStyles.normal,
              ),
              const SizedBox(height: 30),
              CustomInputField(
                controller: _emailController,
                hintText: 'Email',
                labelText: 'Email Address',
                icon: Icons.email_outlined,

                keyboardType: TextInputType.emailAddress,
                customValidator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email cannot be empty';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email address';
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
                  : PrimaryButton(label: 'Request OTP', onPressed: _requestOtp),
              const Text(
                '© 2025 Mariska',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
