import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import '../widgets/root_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    await Future.delayed(const Duration(milliseconds: 1100));
    final loggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => loggedIn ? const RootShell() : const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), shape: BoxShape.circle),
              child: const Icon(Icons.delivery_dining, color: Colors.white, size: 76),
            ),
            const SizedBox(height: 28),
            const Text('JEEVI', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const Text('FOODIE', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w300, letterSpacing: 6)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
              decoration: BoxDecoration(color: AppTheme.gold, borderRadius: BorderRadius.circular(20)),
              child: const Text('PARTNER', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 12)),
            ),
            const Spacer(flex: 3),
            const Text('Deliver Happiness', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const Text('Earn More!', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 28),
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
