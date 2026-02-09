import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/constants/app_strings.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/screens/home/home_screen.dart';
import 'package:vishal_gold/utils/validators.dart';

class CompanyDetailsScreen extends StatefulWidget {
  const CompanyDetailsScreen({super.key});

  @override
  State<CompanyDetailsScreen> createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void dispose() {
    _companyNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.updateProfile({
        'company_name': _companyNameController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
      });

      if (!mounted) return;

      // Success - navigate to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save company details'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _skip() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text(AppStrings.companyDetails),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Company Name Field
                TextFormField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(
                    labelText: '${AppStrings.companyName} *',
                    hintText: 'ABC Jewelers Pvt Ltd',
                    prefixIcon: Icon(Icons.business),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      Validators.validateRequired(value, 'Company name'),
                ),
                const SizedBox(height: 16),

                // Address Field
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: '${AppStrings.address} *',
                    hintText: '123, Market Street, Zaveri Bazaar',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Address is required';
                    }
                    if (value.length < 5) {
                      return 'Address must be at least 5 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // City Field
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: '${AppStrings.city} *',
                    hintText: 'Mumbai',
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      Validators.validateRequired(value, 'City'),
                ),
                const SizedBox(height: 32),

                // Save Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _saveDetails,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '${AppStrings.save} & ${AppStrings.continueText}',
                            ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Skip Button
                TextButton(
                  onPressed: _skip,
                  child: Text(
                    AppStrings.skip,
                    style: TextStyle(color: AppColors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
