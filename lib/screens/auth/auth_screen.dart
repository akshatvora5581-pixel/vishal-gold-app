import 'package:flutter/material.dart';
// Sahi path: 'info' folder wala use karein
import 'package:vishal_gold/screens/info/user_info_screen.dart'; 

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ab ye bina kisi error ke UserInfoScreen ko recognize kar lega
    return const UserInfoScreen(); 
  }
}