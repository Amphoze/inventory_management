import 'package:flutter/material.dart';
import 'package:inventory_management/Api/auth_provider.dart';
import 'package:inventory_management/Custom-Files/colors.dart';
import 'package:inventory_management/dashboard.dart';
import 'package:inventory_management/forgot_password.dart';
import 'package:provider/provider.dart';
// import 'Api/auth_provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [
                          Color.fromARGB(255, 0, 53, 96),
                          Color.fromARGB(255, 8, 76, 131),
                          Color.fromARGB(255, 18, 95, 157),
                          Colors.white,
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        const Align(
                          alignment: Alignment.center,
                          child: Image(
                            image: AssetImage('assets/background.png'),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(60.0),
                          child: Center(
                            child: Material(
                              color: Colors.white,
                              elevation: 5,
                              borderRadius: BorderRadius.circular(20),
                              child: const SizedBox(
                                width: 400,
                                child: LoginForm(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Image(
                    height: MediaQuery.sizeOf(context).height * .7,
                    width: MediaQuery.sizeOf(context).width * .7,
                    // fit: BoxFit.cover,
                    image: const AssetImage('assets/logo.jpg'),
                  ),
                ),
              ],
            );
          } else {
            return SingleChildScrollView(
              child: Container(
                color: AppColors.white,
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: LoginForm(),
                    ),
                    Container(
                      width: double.infinity,
                      height: 300,
                      color: AppColors.primaryBlue,
                      child: const Center(
                        child: Text(
                          "Katyayani",
                          style: TextStyle(
                            fontSize: 40,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login(BuildContext context) async {
    if (_isLoading) return; // Prevent multiple submissions

    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.login(email, password);

    setState(() {
      _isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login successful"),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      _emailController.clear();
      _passwordController.clear();
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardPage(inventoryId: ''),
          ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? "Login failed"),
          backgroundColor: Colors.red,
        ),
      );
      _emailController.clear();
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width <= 800;
    double textSize = isSmallScreen ? 30.0 : 32.0;

    final userRole = context.read<AuthProvider>().assignedRole;

    return Padding(
      padding: const EdgeInsets.all(31.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text(
            "Log in to your Account",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.mail),
              labelText: "Email",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock),
              labelText: "Password",
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            onSubmitted: (value) {
              _login(context);
            },
          ),
          const SizedBox(height: 10),
          if (isSmallScreen) ...[
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (bool? value) {
                        setState(() {
                          _rememberMe = value!;
                        });
                      },
                      activeColor: AppColors.primaryBlue,
                    ),
                    const Text("Remember me"),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (bool? value) {
                        setState(() {
                          _rememberMe = value!;
                        });
                      },
                      activeColor: AppColors.primaryBlue,
                    ),
                    const Text("Remember me"),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordPage(),
                      ),
                    );
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    _login(context);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 100.0, vertical: 20.0),
              elevation: _isLoading ? 0 : 5,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : const Text("Log in"),
          ),
          // if (userRole == 'superAdmin' || userRole == 'admin') ...[
          //   const SizedBox(height: 15),
          //   Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       const Text("Don't have an account?"),
          //       TextButton(
          //         onPressed: () {
          //           // Navigator.pushNamed(context, '/createAccount');
                    // Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //         builder: (context) => const CreateAccountPage()));
          //         },
          //         child: const Text(
          //           "Create Account",
          //           style: TextStyle(
          //             color: AppColors.primaryBlue,
          //             fontWeight: FontWeight.bold,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ],
          // const SizedBox(height: 20),
        ],
      ),
    );
  }
}
