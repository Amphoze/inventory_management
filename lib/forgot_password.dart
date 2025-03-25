import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/reset_password.dart';
import 'Api/auth_provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  bool _isSendingOtp = false;
  bool _isEmailValid = false;
  bool _isEmailEmpty = true;
  bool _canResendOtp = false;
  int _remainingSeconds = 60;
  Timer? _timer;
  bool _isLoading = false;

  final AuthProvider _authProvider = AuthProvider();

  void _showSnackbar(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isSuccess ? Colors.black : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _validateEmail(String email) {
    setState(() {
      _isEmailEmpty = email.isEmpty;
      _isEmailValid = RegExp(r'\S+@\S+\.\S+').hasMatch(email);
    });
  }

  void _startResendTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _canResendOtp = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      _showSnackbar('Please enter the OTP', isSuccess: false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _authProvider.verifyOtp(_emailController.text, _otpController.text);

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      setState(() {
        _isOtpVerified = true;
      });
      _showSnackbar('OTP verified successfully!');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordPage(
              email: _emailController.text.trim()),
        ),
      );
    } else {
      _showSnackbar('Incorrect OTP. Please try again.', isSuccess: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: Stack(
        children: [
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 600;
              final isLargeScreen = constraints.maxWidth >= 600;

              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 62.0, vertical: 16.0),
                child: isSmallScreen
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: Image.asset('assets/forgotPass.png',
                                fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Please enter your email',
                            style: TextStyle(color: AppColors.white),
                          ),
                          const SizedBox(height: 20),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  child: TextFormField(
                                    controller: _emailController,
                                    style:
                                        const TextStyle(color: AppColors.white),
                                    cursorColor: AppColors.white,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      labelStyle: const TextStyle(
                                          color: AppColors.white),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: AppColors.white),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: AppColors.white),
                                      ),
                                      suffixIcon:
                                          _emailController.text.isNotEmpty
                                              ? Icon(
                                                  _isEmailValid
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color: _isEmailValid
                                                      ? Colors.green
                                                      : Colors.red,
                                                )
                                              : null,
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!RegExp(r'\S+@\S+\.\S+')
                                          .hasMatch(value)) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      _validateEmail(value);
                                    },
                                    enabled: !_isOtpVerified,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _otpController,
                                          enabled:
                                              _isOtpSent && !_isOtpVerified,
                                          style: const TextStyle(
                                              color: AppColors.white),
                                          cursorColor: AppColors.white,
                                          decoration: const InputDecoration(
                                            labelText: 'OTP',
                                            labelStyle: TextStyle(
                                                color: AppColors.white),
                                            enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: AppColors.white),
                                            ),
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: AppColors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        onPressed: (!_isEmailValid ||
                                                    _isEmailEmpty) ||
                                                (_isOtpSent && !_canResendOtp)
                                            ? null
                                            : () async {
                                                setState(() {
                                                  _isSendingOtp = true;
                                                  _canResendOtp = false;
                                                  _remainingSeconds = 60;
                                                });

                                                final result =
                                                    await _authProvider
                                                        .forgotPassword(
                                                            _emailController
                                                                .text);

                                                _showSnackbar(result['message'],
                                                    isSuccess:
                                                        result['success']);

                                                if (result['success']) {
                                                  setState(() {
                                                    _isOtpSent = true;
                                                  });
                                                  _startResendTimer();
                                                }
                                                setState(() {
                                                  _isSendingOtp = false;
                                                });
                                              },
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor:
                                              AppColors.primaryBlue,
                                          backgroundColor: AppColors.white,
                                        ),
                                        child: _isSendingOtp
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.0,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          AppColors
                                                              .primaryBlue),
                                                ),
                                              )
                                            : Text(_isOtpSent
                                                ? _canResendOtp
                                                    ? "Resend OTP"
                                                    : "Resend in ${_remainingSeconds}s"
                                                : "Send OTP"),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _isOtpSent && !_isOtpVerified && !_isLoading
                                      ? () async {
                                          if (_formKey.currentState?.validate() ?? false) {
                                            await _verifyOtp();
                                          }
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: AppColors.primaryBlue,
                                    backgroundColor: AppColors.white,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                                          ),
                                        )
                                      : const Text('Reset Password'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: isLargeScreen ? 60 : 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Please enter your email',
                                  style: TextStyle(
                                    fontSize: isLargeScreen ? 20 : 16,
                                    color: AppColors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.28,
                                        child: TextFormField(
                                          controller: _emailController,
                                          style: const TextStyle(
                                              color: AppColors.white),
                                          cursorColor: AppColors.white,
                                          decoration: InputDecoration(
                                            labelText: 'Email',
                                            labelStyle: const TextStyle(
                                                color: AppColors.white),
                                            enabledBorder:
                                                const UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: AppColors.white),
                                            ),
                                            focusedBorder:
                                                const UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: AppColors.white),
                                            ),
                                            suffixIcon:
                                                _emailController.text.isNotEmpty
                                                    ? Icon(
                                                        _isEmailValid
                                                            ? Icons.check_circle
                                                            : Icons.cancel,
                                                        color: _isEmailValid
                                                            ? Colors.green
                                                            : Colors.red,
                                                      )
                                                    : null,
                                          ),
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your email';
                                            }
                                            if (!RegExp(r'\S+@\S+\.\S+')
                                                .hasMatch(value)) {
                                              return 'Please enter a valid email';
                                            }
                                            return null;
                                          },
                                          onChanged: (value) {
                                            _validateEmail(value);
                                          },
                                          enabled: !_isOtpVerified,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.28,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: _otpController,
                                                enabled: _isOtpSent &&
                                                    !_isOtpVerified,
                                                style: const TextStyle(
                                                    color: AppColors.white),
                                                cursorColor: AppColors.white,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'OTP',
                                                  labelStyle: TextStyle(
                                                      color: AppColors.white),
                                                  enabledBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: AppColors.white),
                                                  ),
                                                  focusedBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: AppColors.white),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            ElevatedButton(
                                              onPressed: (!_isEmailValid ||
                                                          _isEmailEmpty) ||
                                                      (_isOtpSent &&
                                                          !_canResendOtp)
                                                  ? null
                                                  : () async {
                                                      setState(() {
                                                        _isSendingOtp = true;
                                                        _canResendOtp = false;
                                                        _remainingSeconds = 60;
                                                      });

                                                      final result =
                                                          await _authProvider
                                                              .forgotPassword(
                                                                  _emailController
                                                                      .text);

                                                      _showSnackbar(
                                                          result['message'],
                                                          isSuccess: result[
                                                              'success']);

                                                      if (result['success']) {
                                                        setState(() {
                                                          _isOtpSent = true;
                                                        });
                                                        _startResendTimer();
                                                      }
                                                      setState(() {
                                                        _isSendingOtp = false;
                                                      });
                                                    },
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.primaryBlue,
                                                backgroundColor:
                                                    AppColors.white,
                                              ),
                                              child: _isSendingOtp
                                                  ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                                    Color>(
                                                                AppColors
                                                                    .primaryBlue),
                                                      ),
                                                    )
                                                  : Text(_isOtpSent
                                                      ? _canResendOtp
                                                          ? "Resend OTP"
                                                          : "Resend in ${_remainingSeconds}s"
                                                      : "Send OTP"),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: _isOtpSent && !_isOtpVerified && !_isLoading
                                            ? () async {
                                                if (_formKey.currentState?.validate() ?? false) {
                                                  await _verifyOtp();
                                                }
                                              }
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor:
                                              AppColors.primaryBlue,
                                          backgroundColor: AppColors.white,
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                                                ),
                                              )
                                            : const Text('Reset Password'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              width: 400,
                              height: 400,
                              child: Image.asset('assets/forgotPass.png',
                                  fit: BoxFit.contain),
                            ),
                          ),
                        ],
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }
}
