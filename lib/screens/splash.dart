import 'package:flutter/material.dart';
import 'role_selection.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelection()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC54141),
      body: Center(
        child: Image.asset(
          'assets/logo/logo1.png',
          width: 180,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
