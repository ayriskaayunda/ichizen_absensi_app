import 'package:flutter/material.dart';
import 'package:ichizen/models/app_models.dart';
import 'package:ichizen/routes/app_routes.dart';
import 'package:ichizen/services/api_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService(); // Api service

  bool _isPasswordVisible = false;
  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    // Check if a token exists in ApiService (which means a user is logged in)
    final isLoggedIn = ApiService.getToken() != null;
    if (isLoggedIn) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.main);
      }
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Set loading to true
      });

      final String email = _emailController.text.trim();
      final String password = _passwordController.text.trim();

      // Call the login method from ApiService
      final ApiResponse<AuthData> response = await _apiService.login(
        email: email,
        password: password,
      );

      setState(() {
        _isLoading = false; // Set loading to false
      });

      if (response.statusCode == 200 && response.data != null) {
        // Login successful
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(response.message)));
          Navigator.pushReplacementNamed(context, AppRoutes.main);
        }
      } else {
        // Login failed, show error message
        String errorMessage = response.message;
        if (response.errors != null) {
          response.errors!.forEach((key, value) {
            errorMessage += '\n$key: ${(value as List).join(', ')}';
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Hapus appBar jika tidak dibutuhkan, atau sesuaikan dengan AppBar transparan
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Color(0xFF624F82))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true, // Untuk membuat body di belakang app bar

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,

            colors: [Color(0xFFE0BBE4), Color(0xFFADD8E6), Color(0xFF957DAD)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Ganti icon disini kalau ingin di tambahkan
                  const Text(
                    'Selamat Datang di Ichizen !',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF624F82),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- Email Input ---
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Masukkan email Anda',
                      fillColor: Colors.white.withOpacity(0.9),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.email,
                        color: Color(0xFF957DAD),
                      ),
                      labelStyle: const TextStyle(color: Color(0xFF624F82)),
                      hintStyle: TextStyle(
                        color: const Color(0xFF624F82).withOpacity(0.7),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email tidak boleh kosong';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Masukkan email yang valid';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // --- Password Input ---
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Masukkan password Anda',
                      fillColor: Colors.white.withOpacity(0.9),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Color(0xFF957DAD),
                      ),
                      labelStyle: const TextStyle(color: Color(0xFF624F82)),
                      hintStyle: TextStyle(
                        color: const Color(0xFF624F82).withOpacity(0.7),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(0xFF957DAD),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      if (value.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  // --- Login Button ---
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF624F82),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF624F82),
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  const SizedBox(height: 20),

                  // --- Forgot Password Button ---
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.forgotPassword);
                    },
                    child: const Text(
                      'Lupa Password?',
                      style: TextStyle(
                        color: Color(0xFF624F82),
                      ), // Warna teks lupa password
                    ),
                  ),

                  // const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Belum punya akun?',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.register),
                        child: const Text(
                          'Daftar Sekarang',
                          style: TextStyle(
                            color: Color(0xFF624F82),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
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
        ),
      ),
    );
  }
}
