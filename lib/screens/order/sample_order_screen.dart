import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:vishal_jewelers/providers/auth_provider.dart';
import 'package:vishal_jewelers/services/firebase_service.dart';
import 'package:vishal_jewelers/widgets/common/custom_app_bar.dart';
import 'package:vishal_jewelers/models/sample_order.dart';
import 'package:vishal_jewelers/services/local_storage_service.dart';
import 'package:vishal_jewelers/services/whatsapp_service.dart';

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
  List<String> _groups = [];
  bool _rodium = false;
  bool _huid = false;
  final List<File> _imageFiles = [];
  bool _isLoading = false;
  bool _isLoadingCategories = true;
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, String> _userDetails = {};

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      // Fetch active categories
      final snapshot =
          await _firebaseService.getCategories(onlyActive: true).first;

      final categories =
          snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['name'] as String? ?? 'Unknown';
          }).toList();

      // Ensure duplicates are removed and list is sorted
      final uniqueCategories = categories.toSet().toList()..sort();

      if (mounted) {
        setState(() {
          _groups = uniqueCategories;
          _isLoadingCategories = false;
          // Pre-select first if available
          if (_groups.isNotEmpty) {
            _selectedGroup = _groups.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
          // Fallback if needed, but better to show error or empty
        });
      }
    }
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
    final List<XFile> pickedFiles = await ImagePicker().pickMultiImage(
      imageQuality: 30,
    );

    if (pickedFiles.isNotEmpty) {
      if (_imageFiles.length + pickedFiles.length > 4) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 4 images allowed')),
          );
        }
        // Add only up to 4
        final remainingSlots = 4 - _imageFiles.length;
        setState(() {
          _imageFiles.addAll(
            pickedFiles.take(remainingSlots).map((xFile) => File(xFile.path)),
          );
        });
      } else {
        setState(() {
          _imageFiles.addAll(pickedFiles.map((xFile) => File(xFile.path)));
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  Future<void> _submitOrder() async {
    // 1. Explicit Validation
    if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a design image first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return; // Form will show its own validation errors
    }

    if (_selectedGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication required. Please log in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Visual Loading State
    setState(() => _isLoading = true);

    try {
      // 3. Safe Upload Logic (Try-Catch)
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

      final result = await _firebaseService.placeSampleOrder(
        sampleOrder.toJson(),
        _imageFiles,
        category: _selectedGroup!,
      );

      // Automated WhatsApp Notification
      if (mounted) {
        final List<String> imageUrls = (result['imageUrls'] ?? '')
            .split(',')
            .where((url) => url.isNotEmpty)
            .toList();
            
        await WhatsAppService.notifyAdmin(
          context: context,
          customerName: _userDetails['name'] ?? 'Customer',
          customerPhone: _userDetails['phone'] ?? 'No Phone',
          category: _selectedGroup ?? 'N/A',
          itemName: _itemNameController.text.trim(),
          qty: _qtyController.text.trim(),
          size: _sizeController.text.trim(),
          weight: _weightController.text.trim(),
          totalWeight: _totalController.text.trim(),
          rodium: _rodium,
          huid: _huid,
          remarks: _remarksController.text.trim().isEmpty
              ? 'N/A'
              : _remarksController.text.trim(),
          imageUrls: imageUrls,
        );
      }

      if (mounted) {
        // Success Handling
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sample Order Submitted!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Clear Form
        _formKey.currentState!.reset();
        _itemNameController.clear();
        _qtyController.clear();
        _sizeController.clear();
        _weightController.clear();
        _totalController.clear();
        _remarksController.clear();
        
        setState(() {
          _imageFiles.clear();
          _selectedGroup = null;
          _rodium = false;
          _huid = false;
          _isLoading = false;
        });

        // Optional: Close screen after success
        // Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
                    ).colorScheme.primary.withValues(alpha: 0.3),
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
              _isLoadingCategories
                  ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                  : _groups.isEmpty
                  ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'No categories found. Please try again later.',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  )
                  : DropdownButtonFormField<String>(
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
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
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
                          ).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
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
                    items:
                        _groups.map((group) {
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
                    onChanged:
                        (value) => setState(() => _selectedGroup = value),
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

              // Image Picker Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REFERENCE IMAGES (MAX 4)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: _imageFiles.isEmpty
                        ? GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(context).colorScheme.surface,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.add_a_photo_outlined,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.5),
                                  size: 30,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                _imageFiles.length +
                                (_imageFiles.length < 4 ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _imageFiles.length) {
                                return GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.5),
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.surface,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.add_a_photo_outlined,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.5),
                                        size: 30,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 12),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.5),
                                          width: 1.5,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface,
                                        image: DecorationImage(
                                          image: FileImage(_imageFiles[index]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.7,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
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
                  ).colorScheme.primary.withValues(alpha: 0.4),
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
                        'UPLOAD DESIGNS',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
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
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
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
