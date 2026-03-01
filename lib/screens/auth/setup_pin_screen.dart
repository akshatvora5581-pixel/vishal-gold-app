import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';

class SetupPinScreen extends StatefulWidget {
  final String password;
  final VoidCallback onSetupComplete;

  const SetupPinScreen({
    super.key,
    required this.password,
    required this.onSetupComplete,
  });

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _isLoading = false;
  String _errorMessage = '';

  void _onNumberPress(String number) {
    setState(() {
      _errorMessage = '';
      if (!_isConfirming) {
        if (_pin.length < 4) _pin += number;
        if (_pin.length == 4) {
          _isConfirming = true;
        }
      } else {
        if (_confirmPin.length < 4) _confirmPin += number;
        if (_confirmPin.length == 4) {
          _verifyAndSavePin();
        }
      }
    });
  }

  void _onBackspace() {
    setState(() {
      _errorMessage = '';
      if (!_isConfirming && _pin.isNotEmpty) {
        _pin = _pin.substring(0, _pin.length - 1);
      } else if (_isConfirming && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      } else if (_isConfirming && _confirmPin.isEmpty) {
        _isConfirming = false;
      }
    });
  }

  Future<void> _verifyAndSavePin() async {
    if (_pin != _confirmPin) {
      setState(() {
        _errorMessage = 'PINs do not match. Try again.';
        _confirmPin = '';
        _isConfirming = false;
        _pin = '';
      });
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.setupPin(_pin, widget.password);
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN setup successfully!')));
      widget.onSetupComplete();
    } else if (mounted) {
      setState(() {
        _errorMessage = 'Failed to save PIN. Try again later.';
        _confirmPin = '';
        _pin = '';
        _isConfirming = false;
      });
    }
  }

  Widget _buildPinDots(String currentPin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        bool isFilled = index < currentPin.length;
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
            const SizedBox(width: 80, height: 80), // Placeholder
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Setup PIN',
          style: TextStyle(color: AppColors.softGold),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.softGold),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Text(
              _isConfirming
                  ? 'Confirm your 4-digit PIN'
                  : 'Enter a 4-digit PIN',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),
            _buildPinDots(_isConfirming ? _confirmPin : _pin),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: AppColors.errorRed),
              )
            else
              const SizedBox(height: 20), // Placeholder for error text height
            const SizedBox(height: 40),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.softGold),
                ),
              )
            else
              Expanded(child: _buildNumPad()),
          ],
        ),
      ),
    );
  }
}
