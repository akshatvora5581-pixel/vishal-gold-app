import 'package:flutter/material.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/screens/info/user_info_screen.dart';
import 'package:vishal_gold/services/local_storage_service.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/screens/auth/phone_auth_screen.dart';
import 'package:vishal_gold/screens/home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      await LocalStorageService.init();

      final bool infoProvided = await LocalStorageService.isUserInfoProvided();

      if (!infoProvided) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UserInfoScreen()),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!authProvider.isAuthenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PhoneAuthScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 300,
              height: 300,
              padding: const EdgeInsets.all(20),
              child: Image.asset('assets/logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.black),
            ),
          ],
        ),
      ),
    );
  }
}
