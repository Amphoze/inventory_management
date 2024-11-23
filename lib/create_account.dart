import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:provider/provider.dart';
import 'Api/auth_provider.dart';

class CreateAccountPage extends StatelessWidget {
  const CreateAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Stack(
                    children: [
                      Container(
                        color: AppColors.primaryBlue,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "Welcome Back!",
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "To keep connected with us please login with your personal info",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppColors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 40),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: AppColors.primaryBlue,
                                    backgroundColor: AppColors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20.0, horizontal: 20.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: const Text("SIGN IN"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 40,
                        left: 20,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: AppColors.white),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    color: AppColors.white,
                    padding: const EdgeInsets.all(40.0),
                    child: const Center(
                      child: CreateAccountForm(),
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 300,
                        color: AppColors.primaryBlue,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "Welcome Back!",
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "To keep connected with us please login with your personal info",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppColors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 40),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: AppColors.primaryBlue,
                                    backgroundColor: AppColors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20.0, horizontal: 20.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  child: const Text("SIGN IN"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CreateAccountForm(),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 20,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class CreateAccountForm extends StatefulWidget {
  const CreateAccountForm({super.key});

  @override
  CreateAccountFormState createState() => CreateAccountFormState();
}

class CreateAccountFormState extends State<CreateAccountForm> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isOtpEnabled = false;
  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  bool _isLoading = false;
  final bool _isSendingOtp = false;
  final bool _isVerifyingOtp = false;

  String? _username;
  String? _email;
  String? _password;
  String? _confirmPassword;

  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _checkIfOtpCanBeEnabled() {
    setState(() {
      _isOtpEnabled = _username != null &&
          _username!.isNotEmpty &&
          _email != null &&
          _email!.isNotEmpty &&
          _password != null &&
          _password!.isNotEmpty &&
          _confirmPassword != null &&
          _password == _confirmPassword &&
          _isValidEmail(_email!);
    });
  }

  bool _isValidEmail(String email) {
    final RegExp emailRegExp = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    return emailRegExp.hasMatch(email);
  }

  // String? _username;
  // String? _email;
  // String? _password;
  // String? _confirmPassword;
  // bool _isOtpEnabled = false;
  // bool _isOtpSent = false;
  // bool _isOtpVerified = false;

  // final TextEditingController _otpController = TextEditingController();

  // @override
  // void dispose() {
  //   _otpController.dispose();
  //   super.dispose();
  // }

  // void _checkIfOtpCanBeEnabled() {
  //   setState(() {
  //     _isOtpEnabled = _username != null &&
  //         _username!.isNotEmpty &&
  //         _email != null &&
  //         _email!.isNotEmpty &&
  //         _password != null &&
  //         _password!.isNotEmpty &&
  //         _password == _confirmPassword;
  //   });
  // }

  Future<void> _sendOtp() async {
    if (!_isOtpEnabled) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.register(_email!, _password!);
      setState(() {
        _isOtpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent successfully!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $error')),
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      // Call the OTP verification method and await the result
      final result = await authProvider.registerOtp(
          _email!, _otpController.text, _password!);

      // Check if the response indicates success
      if (result['success'] == true) {
        setState(() {
          _isOtpVerified = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP verified successfully!')),
        );
      } else {
        // Handle the case where OTP verification fails
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect OTP. Please try again.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to verify OTP: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(50.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(FontAwesomeIcons.facebook,
                        color: AppColors.facebookColor),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(FontAwesomeIcons.google,
                        color: AppColors.googleColor),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(FontAwesomeIcons.linkedin,
                        color: AppColors.linkedinColor),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text("or use your email for registration:"),
              const SizedBox(height: 20),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person),
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
                onChanged: (value) {
                  _username = value;
                  _checkIfOtpCanBeEnabled();
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.mail),
                  labelText: "Email",
                  border: const OutlineInputBorder(),
                  suffixIcon: _email != null && _email!.isNotEmpty
                      ? Icon(
                          _isValidEmail(_email!)
                              ? Icons.check_circle
                              : Icons.cancel,
                          color: _isValidEmail(_email!)
                              ? Colors.green
                              : Colors.red,
                        )
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!_isValidEmail(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                onChanged: (value) {
                  _email = value;
                  _checkIfOtpCanBeEnabled();
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                onChanged: (value) {
                  _password = value;
                  _checkIfOtpCanBeEnabled();
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock),
                  labelText: "Confirm Password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: AppColors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _password) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                onChanged: (value) {
                  _confirmPassword = value;
                  _checkIfOtpCanBeEnabled();
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _otpController,
                      enabled: _isOtpEnabled,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.sms),
                        labelText: "OTP",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_isOtpEnabled && (value == null || value.isEmpty)) {
                          return 'Please enter the OTP';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isOtpEnabled
                        ? (_isOtpSent ? _verifyOtp : _sendOtp)
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 20.0, horizontal: 20.0),
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: _isSendingOtp
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white),
                            ),
                          )
                        : Text(_isOtpSent ? "Verify" : "Send OTP"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isOtpVerified && !_isVerifyingOtp
                    ? () {
                        if (_formKey.currentState!.validate()) {
                          _register();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 40.0),
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _isVerifyingOtp
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white),
                            ),
                          )
                        : const Text("Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _register() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_email != null && _password != null && _username != null) {
      setState(() {
        _isLoading = true;
      });
      final response = await authProvider.register(_email!, _password!);
      setState(() {
        _isLoading = false;
      });

      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );
        Navigator.pushNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'])),
        );
      }
    }
  }
}
