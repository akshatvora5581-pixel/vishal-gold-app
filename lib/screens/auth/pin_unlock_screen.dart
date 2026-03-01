import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/screens/admin/admin_dashboard_screen.dart';
import 'package:vishal_gold/screens/auth/admin_login_screen.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:vishal_gold/models/admin.dart';

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  String _pin = '';
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBiometrics();
    });
  }

  Future<void> _checkBiometrics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isBiometricEnabled) {
      final success = await authProvider.authenticateWithBiometric();
      if (success && mounted) {
        _onUnlockSuccess();
      }
    }
  }

  Future<void> _onUnlockSuccess() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      if (authProvider.currentUser == null) {
        // Attempt background login with stored credentials
        debugPrint('Attempting background login for admin...');
        final loginSuccess = await authProvider.signInWithStoredCredentials();
        if (!loginSuccess) {
          debugPrint('Background login failed. Redirecting to password login.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Quick login session expired. Please use your password.',
                ),
                backgroundColor: AppColors.errorRed,
              ),
            );
            _onLoginWithPassword();
          }
          return;
        }
        debugPrint(
          'Background login successful: ${authProvider.currentUser?.uid}',
        );
      }
      final adminData = await FirebaseService().getAdminProfile(
        authProvider.currentUser!.uid,
        email: authProvider.currentUser!.email,
      );
      if (adminData != null && mounted) {
        final adminId =
            adminData['id'] as String? ?? authProvider.currentUser!.uid;
        final admin = Admin.fromJson(adminData, adminId);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboardScreen(admin: admin)),
          (route) => false,
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Admin not found';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load admin profile';
        });
      }
    }
  }

  void _onNumberPress(String number) {
    if (_pin.length < 4) {
      setState(() {
        _errorMessage = '';
        _pin += number;
        if (_pin.length == 4) {
          _verifyPin();
        }
      });
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _errorMessage = '';
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.authenticateWithPin(_pin);
    setState(() => _isLoading = false);

    if (success) {
      _onUnlockSuccess();
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN. Please try again.';
        _pin = '';
      });
    }
  }

  void _onLoginWithPassword() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminLoginScreen(returnFromQuickLogin: true),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool isFilled = index < _pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.softGold : Colors.transparent,
            border: Border.all(color: AppColors.softGold, width: 2),
          ),
        );
      }),
    );
  }

  Widget _buildNumPad() {
    return Column(
      children: [
        for (int i = 0; i < 3; i++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int j = 1; j <= 3; j++)
                _buildNumButton((i * 3 + j).toString()),
            ],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBiometricButton(),
            _buildNumButton('0'),
            _buildBackspaceButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildNumButton(String number) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: InkWell(
        onTap: () => _onNumberPress(number),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.softGold.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: InkWell(
        onTap: _onBackspace,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          child: const Icon(
            Icons.backspace_outlined,
            color: AppColors.textPrimary,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isBiometricEnabled) {
          return const SizedBox(width: 100, height: 100);
        }
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: InkWell(
            onTap: _checkBiometrics,
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 80,
              height: 80,
              alignment: Alignment.center,
              child: const Icon(
                Icons.fingerprint,
                color: AppColors.softGold,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Enter Admin PIN',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildPinDots(),
                  const SizedBox(height: 20),
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: AppColors.errorRed),
                    )
                  else
                    const SizedBox(height: 20),
                  const SizedBox(height: 30),
                  if (_isLoading)
                    const SizedBox(
                      height: 400,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.softGold,
                        ),
                      ),
                    )
                  else
                    _buildNumPad(),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _onLoginWithPassword,
                    child: const Text(
                      'Login with Password Instead',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
