import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/screens/home/home_screen.dart';
import 'package:vishal_gold/screens/auth/phone_auth_screen.dart';
import 'package:vishal_gold/screens/auth/pin_unlock_screen.dart';
import 'package:vishal_gold/screens/admin/admin_dashboard_screen.dart';
import 'package:vishal_gold/screens/splash_screen.dart';
import 'package:vishal_gold/screens/info/user_info_screen.dart';
import 'package:vishal_gold/services/local_storage_service.dart';
import 'package:vishal_gold/models/admin.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: LocalStorageService.hasSeenUserInfo(),
      builder: (context, infoSnapshot) {
        if (infoSnapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final hasSeenInfo = infoSnapshot.data ?? false;

        if (!hasSeenInfo) {
          return const UserInfoScreen();
        }

        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            final user = snapshot.data;
            if (user == null) {
              return const PhoneAuthScreen();
            }

            return Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                if (authProvider.isLoading) {
                  return const SplashScreen();
                }

                if (authProvider.isAdmin) {
                  if (authProvider.isPinSet || authProvider.isBiometricEnabled) {
                    return const PinUnlockScreen();
                  }

                  final profile = authProvider.userProfile;
                  if (profile != null) {
                    final admin = Admin.fromJson(profile, user.uid);
                    return AdminDashboardScreen(admin: admin);
                  }
                  
                  return const SplashScreen();
                }

                return const HomeScreen();
              },
            );
          },
        );
      },
    );
  }
}
