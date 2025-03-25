import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:provider/provider.dart';
import 'Api/auth_provider.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, required this.email});

  final String email;

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureTextNew = true;
  bool _obscureTextConfirm = true;
  bool _isLoading = false;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_updateButtonState);
    _confirmPasswordController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _passwordsMatch() {
    return _newPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _newPasswordController.text == _confirmPasswordController.text;
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled = _passwordsMatch() && !_isLoading;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
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
                            child: Image.asset('assets/resetPass.png',
                                fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Please enter your new password and confirm it',
                            style: TextStyle(color: AppColors.primaryBlue),
                          ),
                          const SizedBox(height: 20),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  child: TextFormField(
                                    controller: _newPasswordController,
                                    obscureText: _obscureTextNew,
                                    style: const TextStyle(
                                        color: AppColors.primaryBlue),
                                    cursorColor: AppColors.primaryBlue,
                                    decoration: InputDecoration(
                                      labelText: 'New Password',
                                      labelStyle: const TextStyle(
                                          color: AppColors.primaryBlue),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppColors.primaryBlue),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppColors.primaryBlue),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureTextNew
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: AppColors.primaryBlue,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureTextNew = !_obscureTextNew;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your new password';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.8,
                                  child: TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureTextConfirm,
                                    style: const TextStyle(
                                        color: AppColors.primaryBlue),
                                    cursorColor: AppColors.primaryBlue,
                                    decoration: InputDecoration(
                                      labelText: 'Confirm New Password',
                                      labelStyle: const TextStyle(
                                          color: AppColors.primaryBlue),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppColors.primaryBlue),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: AppColors.primaryBlue),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureTextConfirm
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: AppColors.primaryBlue,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureTextConfirm =
                                                !_obscureTextConfirm;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please confirm your new password';
                                      }
                                      if (value !=
                                          _newPasswordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _isLoading
                                    ? const Positioned.fill(
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : ElevatedButton(
                                        onPressed: _isButtonEnabled
                                            ? () async {
                                                if (_formKey.currentState
                                                        ?.validate() ??
                                                    false) {
                                                  setState(() {
                                                    _isLoading = true;
                                                  });

                                                  // Retrieve email from SharedPreferences
                                                  // final prefs =
                                                  //     await SharedPreferences
                                                  //         .getInstance();
                                                  final email = widget.email;

                                                  log('Email: $email');

                                                  if (email.isEmpty) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Email not found'),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                    setState(() {
                                                      _isLoading = false;
                                                    });
                                                    return;
                                                  }

                                                  final authProvider =
                                                      Provider.of<AuthProvider>(
                                                          context,
                                                          listen: false);
                                                  final result =
                                                      await authProvider
                                                          .resetPassword(
                                                    email,
                                                    _newPasswordController.text
                                                        .trim(),
                                                  );

                                                  setState(() {
                                                    _isLoading = false;
                                                  });

                                                  if (result['success']) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(result[
                                                                'message'] ??
                                                            'Password reset successfully'),
                                                        backgroundColor:
                                                            AppColors
                                                                .primaryGreen,
                                                      ),
                                                    );
                                                    Navigator
                                                        .pushReplacementNamed(
                                                            context, '/login');
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(result[
                                                                'message'] ??
                                                            'Password reset failed'),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                }
                                              }
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: AppColors.white,
                                          backgroundColor:
                                              AppColors.primaryBlue,
                                        ),
                                        child: const Text('Reset Password'),
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
                                  'Reset Password',
                                  style: TextStyle(
                                    fontSize: isLargeScreen ? 60 : 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Please enter your new password and confirm it',
                                  style: TextStyle(
                                    fontSize: isLargeScreen ? 20 : 16,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.28,
                                        child: TextFormField(
                                          controller: _newPasswordController,
                                          obscureText: _obscureTextNew,
                                          style: const TextStyle(
                                              color: AppColors.primaryBlue),
                                          cursorColor: AppColors.primaryBlue,
                                          decoration: InputDecoration(
                                            labelText: 'New Password',
                                            labelStyle: const TextStyle(
                                                color: AppColors.primaryBlue),
                                            enabledBorder:
                                                const UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: AppColors.primaryBlue),
                                            ),
                                            focusedBorder:
                                                const UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: AppColors.primaryBlue),
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureTextNew
                                                    ? Icons.visibility
                                                    : Icons.visibility_off,
                                                color: AppColors.primaryBlue,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscureTextNew =
                                                      !_obscureTextNew;
                                                });
                                              },
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your new password';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.28,
                                        child: TextFormField(
                                          controller:
                                              _confirmPasswordController,
                                          obscureText: _obscureTextConfirm,
                                          style: const TextStyle(
                                              color: AppColors.primaryBlue),
                                          cursorColor: AppColors.primaryBlue,
                                          decoration: InputDecoration(
                                            labelText: 'Confirm New Password',
                                            labelStyle: const TextStyle(
                                                color: AppColors.primaryBlue),
                                            enabledBorder:
                                                const UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: AppColors.primaryBlue),
                                            ),
                                            focusedBorder:
                                                const UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: AppColors.primaryBlue),
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _obscureTextConfirm
                                                    ? Icons.visibility
                                                    : Icons.visibility_off,
                                                color: AppColors.primaryBlue,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscureTextConfirm =
                                                      !_obscureTextConfirm;
                                                });
                                              },
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please confirm your new password';
                                            }
                                            if (value !=
                                                _newPasswordController.text) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      _isLoading
                                          ? const Positioned.fill(
                                              child: Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            )
                                          : ElevatedButton(
                                              onPressed: _isButtonEnabled
                                                  ? () async {
                                                      if (_formKey.currentState
                                                              ?.validate() ??
                                                          false) {
                                                        setState(() {
                                                          _isLoading = true;
                                                        });

                                                        // Retrieve email from SharedPreferences
                                                        // final prefs =
                                                        //     await SharedPreferences
                                                        //         .getInstance();
                                                        final email =
                                                            widget.email;

                                                        if (email.isEmpty) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                  'Email not found'),
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                          );
                                                          setState(() {
                                                            _isLoading = false;
                                                          });
                                                          return;
                                                        }

                                                        final authProvider =
                                                            Provider.of<
                                                                    AuthProvider>(
                                                                context,
                                                                listen: false);
                                                        final result =
                                                            await authProvider
                                                                .resetPassword(
                                                          email,
                                                          _newPasswordController
                                                              .text
                                                              .trim(),
                                                        );

                                                        setState(() {
                                                          _isLoading = false;
                                                        });

                                                        if (result['success']) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(result[
                                                                      'message'] ??
                                                                  'Password reset successfully'),
                                                              backgroundColor:
                                                                  AppColors
                                                                      .primaryGreen,
                                                            ),
                                                          );
                                                          Navigator
                                                              .pushReplacementNamed(
                                                                  context,
                                                                  '/login');
                                                        } else {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(result[
                                                                      'message'] ??
                                                                  'Password reset failed'),
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    }
                                                  : null,
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.white,
                                                backgroundColor:
                                                    AppColors.primaryBlue,
                                              ),
                                              child:
                                                  const Text('Reset Password'),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(flex: 1),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              width: 400,
                              height: 400,
                              child: Image.asset('assets/resetPass.png',
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
}
