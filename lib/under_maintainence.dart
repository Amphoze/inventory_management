import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class UnderMaintainence extends StatefulWidget {
  const UnderMaintainence({super.key});

  @override
  State<UnderMaintainence> createState() => _UnderMaintainenceState();
}

class _UnderMaintainenceState extends State<UnderMaintainence> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/under.json',
              // width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.7,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20), // Spacing between animation and text
            Text(
              'UNDER MAINTENANCE',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.05,
                // fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
