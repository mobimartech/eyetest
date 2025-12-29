import 'dart:convert';

import 'package:eyetest/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({Key? key}) : super(key: key);

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _countryCode = '+966'; // Default Saudi Arabia
  String _phoneNumber = '';
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String disc = '';
  @override
  void initState() {
    super.initState();
    getdiscforvas();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final fullPhoneNumber = _countryCode + _phoneNumber;
        print('Login attempt with: $fullPhoneNumber');
        // Prepare form data
        final formData = {'phnumb': fullPhoneNumber};

        // Make POST request to your API
        final response = await http
            .post(
          Uri.parse(
            'https://eyeshealthtest.com/he/sa/android/numcheckactive.php',
          ),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: formData, // This will be sent as form data
        )
            .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Request timeout');
          },
        );

        print('Response status: ${response.statusCode}');
        // print('Response body: ${response.body}');

        setState(() => _isLoading = false);

        if (response.statusCode == 200) {
          // Parse the response
          try {
            // final responseData = json.decode(response.body);
            print('Response body: ${response.body.toString().trim()}');
            // Check if the response indicates success
            // Adjust this based on your actual API response structure
            if (response.body.toString().trim() == 'already subscribed') {
              if (mounted) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', true);
                // Show success message
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('phone_login.successfully'.tr()),
                    backgroundColor: const Color(0xFF00E676),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );

                // Navigate to OTP verification page or next screen
                // TODO: Navigate to your OTP/verification page
              }
            } else {
              // Handle API error response
              // String errorMessage =
              //     responseData['message'] ??
              //     responseData['error'] ??
              //     'phone_login.error_failed'.tr();
              // _showErrorSnackBar(errorMessage);
            }
          } catch (e) {
            _showErrorSnackBar("Login failed. Please check your number.");
          }
        } else if (response.statusCode == 400) {
          _showErrorSnackBar('phone_login.error_invalid_number'.tr());
        } else if (response.statusCode == 404) {
          _showErrorSnackBar('phone_login.error_not_found'.tr());
        } else if (response.statusCode >= 500) {
          _showErrorSnackBar('phone_login.error_server'.tr());
        } else {
          _showErrorSnackBar('phone_login.error_unknown'.tr());
        }
      } on http.ClientException catch (e) {
        setState(() => _isLoading = false);
        print('ClientException: $e');
        _showErrorSnackBar('phone_login.error_network'.tr());
      } on FormatException catch (e) {
        setState(() => _isLoading = false);
        print('FormatException: $e');
        _showErrorSnackBar('phone_login.error_invalid_response'.tr());
      } on Exception catch (e) {
        setState(() => _isLoading = false);
        print('Exception: $e');

        if (e.toString().contains('timeout')) {
          _showErrorSnackBar('phone_login.error_timeout'.tr());
        } else {
          _showErrorSnackBar('phone_login.error_general'.tr());
        }
      }
    }
  }

  // Helper method to show error messages
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF4081),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Helper method for success flow
  void _showSuccessAndNavigate(String phoneNumber) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'phone_login.verification_sent'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF00E676),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // TODO: Navigate to next page
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => OTPVerificationPage(phoneNumber: phoneNumber),
      //   ),
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _buildLogo(),
                        const SizedBox(height: 60),
                        _buildWelcomeText(),
                        const SizedBox(height: 40),
                        _buildPhoneInputField(),
                        const SizedBox(height: 32),
                        _buildLoginButton(),
                        const SizedBox(height: 24),
                        _buildDisclaimer(),
                      ],
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

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Container(
              width: 120,
              height: 120,
              child: Center(
                child: Image.asset(
                  'assets/img/Logo.png', // Replace with your logo
                  width: 120,
                  height: 120,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('👁️', style: TextStyle(fontSize: 50));
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'app_title'.tr(),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Text(
            'phone_login.welcome'.tr(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'phone_login.subtitle'.tr(),
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF888888),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInputField() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF333333), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: IntlPhoneField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'phone_login.phone_number'.tr(),
              labelStyle: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              hintText: '512 345 678',
              hintStyle: const TextStyle(color: Color(0xFF555555)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00E5FF).withOpacity(0.2),
                      const Color(0xFF049281).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  color: Color(0xFF00E5FF),
                  size: 20,
                ),
              ),
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            dropdownTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            initialCountryCode: 'SA',
            dropdownIcon: const Icon(
              Icons.arrow_drop_down_rounded,
              color: Color(0xFF00E5FF),
            ),
            flagsButtonPadding: const EdgeInsets.only(left: 20),
            dropdownDecoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            searchText: 'phone_login.search_country'.tr(),
            onChanged: (phone) {
              setState(() {
                _countryCode = phone.countryCode;
                _phoneNumber = phone.number;
              });
            },
            onCountryChanged: (country) {
              setState(() {
                _countryCode = '+${country.dialCode}';
              });
            },
            validator: (phone) {
              if (phone == null || phone.number.isEmpty) {
                return 'phone_login.error_empty'.tr();
              }
              if (phone.number.length < 8) {
                return 'phone_login.error_invalid'.tr();
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  getdiscforvas() async {
    print("getdiscforvas called");
    final response = await http.get(
      Uri.parse('https://eyeshealthtest.com/he/sa/android/getdisc.php'),
      headers: {'Content-Type': 'application/json'},
    );

    print("getdiscforvas called11");

    if (response.statusCode == 200) {
      // String disc = response.body;
      var typesof = jsonDecode(response.body);
      print("Discriminator: ${typesof['type']}");
      print("Discriminator: ${typesof['disclaimer']}");
      if (typesof['disclaimer'].toString().trim() != "") {
        setState(() {
          disc = typesof['disclaimer'].toString().trim();
        });
      }
    } else {
      print(response.statusCode);
    }
  } // Dummy async function for subscription check

  Widget _buildLoginButton() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _isLoading ? null : _handleLogin,
        // onTap: getdiscforvas,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF049281)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'phone_login.login_button'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border(
            top: BorderSide(color: const Color(0xFF333333).withOpacity(0.5)),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF00E5FF),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'phone_login.disclaimer_title'.tr(),
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              disc,
              style: const TextStyle(
                color: Color(0xFF888888),
                fontSize: 12,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'phone_login.terms_prefix'.tr(),
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    // TODO: Open Terms & Conditions
                  },
                  child: Text(
                    'phone_login.terms_link'.tr(),
                    style: const TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
