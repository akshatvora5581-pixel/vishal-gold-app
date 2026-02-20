import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:vishal_gold/widgets/common/custom_app_bar.dart';
import 'package:vishal_gold/models/sample_order.dart';
import 'package:vishal_gold/services/local_storage_service.dart';

class SampleOrderScreen extends StatefulWidget {
  const SampleOrderScreen({super.key});

  @override
  State<SampleOrderScreen> createState() => _SampleOrderScreenState();
}

class _SampleOrderScreenState extends State<SampleOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _sizeController = TextEditingController();
  final _weightController = TextEditingController();
  final _totalController = TextEditingController();
  final _remarksController = TextEditingController();

  String? _selectedGroup;
  bool _rodium = false;
  bool _huid = false;
  File? _imageFile;
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, String> _userDetails = {};

  final List<String> _groups = ['84 MELTING', '92 MELTING', '92 MELTING CHAIN'];

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    await LocalStorageService.init(); // Ensure initialized
    final name = await LocalStorageService.getUserName();
    final city = await LocalStorageService.getUserCity();
    final state = await LocalStorageService.getUserState();
    final phone = await LocalStorageService.getUserPhone();

    if (mounted) {
      setState(() {
        _userDetails = {
          'name': (name?.isNotEmpty == true) ? name! : 'N/A',
          'city': (city?.isNotEmpty == true) ? city! : 'N/A',
          'state': (state?.isNotEmpty == true) ? state! : 'N/A',
          'phone': (phone?.isNotEmpty == true) ? phone! : 'N/A',
        };
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGroup == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a group')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final sampleOrder = SampleOrder(
        userId: authProvider.currentUser!.uid,
        group: _selectedGroup!,
        itemName: _itemNameController.text.trim(),
        qty: _qtyController.text.trim(),
        size: _sizeController.text.trim(),
        weight: _weightController.text.trim(),
        total: _totalController.text.trim(),
        rodium: _rodium,
        huid: _huid,
        imageUrls: [], // Will be filled by service
        remarks: _remarksController.text.trim(),
      );

      await _firebaseService.placeSampleOrder(sampleOrder.toJson(), _imageFile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _qtyController.dispose();
    _sizeController.dispose();
    _weightController.dispose();
    _totalController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'SAMPLE ORDER'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Details Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'USER DETAILS',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.person_outline,
                      _userDetails['name'] ?? '',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.phone_outlined,
                      _userDetails['phone'] ?? '',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      '${_userDetails['city']}, ${_userDetails['state']}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Group Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedGroup,
                decoration: InputDecoration(
                  labelText: 'Select Category',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                  hintText: 'Choose a category',
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  prefixIcon: Icon(
                    Icons.category_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: _groups.map((group) {
                  return DropdownMenuItem(
                    value: group,
                    child: Text(
                      group,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedGroup = value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Item Name
              _buildTextField(_itemNameController, 'Enter Item Name'),
              const SizedBox(height: 16),

              // Qty and Size Row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _qtyController,
                      'Enter Qty',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(_sizeController, 'Enter Size'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weight and Total Row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _weightController,
                      'Enter Wt/Qty',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      _totalController,
                      'Total',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Rodium and HUID Checkboxes
              Row(
                children: [
                  _buildCheckbox(
                    'Rodium',
                    _rodium,
                    (val) => setState(() => _rodium = val!),
                  ),
                  const SizedBox(width: 24),
                  _buildCheckbox(
                    'HUID',
                    _huid,
                    (val) => setState(() => _huid = val!),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 100,
                  width: 100,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.5),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.surface,
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imageFile == null
                        ? Center(
                            child: Icon(
                              Icons.add_a_photo_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.6),
                              size: 32,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Remarks
              _buildTextField(_remarksController, 'Remarks', maxLines: 3),
              const SizedBox(height: 32),

              // Place Order Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.4),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Text(
                        'PLACE ORDER',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text.isEmpty ? 'Loading...' : text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
