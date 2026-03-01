import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/constants/app_colors.dart';

class FlashSaleCreatorScreen extends StatefulWidget {
  const FlashSaleCreatorScreen({super.key});

  @override
  State<FlashSaleCreatorScreen> createState() => _FlashSaleCreatorScreenState();
}

class _FlashSaleCreatorScreenState extends State<FlashSaleCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  DateTime? _endDate;
  double _discount = 0.0;
  bool _isSaving = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _saveFlashSale() async {
    if (!_formKey.currentState!.validate() || _endDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields and select an end date'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Logic to save promotional banner/alert to Firestore
      await FirebaseFirestore.instance.collection('promotions').add({
        'title': _title,
        'description': _description,
        'discount': _discount,
        'endDate': Timestamp.fromDate(_endDate!),
        'type': 'flash_sale',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flash Sale Created Successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error creating flash sale: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          'Flash Sale Creator',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Sale Details'),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'Campaign Title',
                hint: 'e.g. Diwali Dhamaka Sale',
                onChanged: (v) => _title = v,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                label: 'Description',
                hint: 'e.g. Flat 10% off on all Bangles!',
                maxLines: 3,
                onChanged: (v) => _description = v,
              ),
              const SizedBox(height: 15),
              _buildDiscountSlider(),
              const SizedBox(height: 25),
              _buildDatePicker(),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveFlashSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          'Launch Campaign',
                          style: GoogleFonts.outfit(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        color: AppColors.gold,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    int maxLines = 1,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: onChanged,
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildDiscountSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Discount Percentage',
              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
            ),
            Text(
              '${_discount.toInt()}%',
              style: GoogleFonts.outfit(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _discount,
          min: 0,
          max: 50,
          divisions: 10,
          activeColor: AppColors.gold,
          inactiveColor: Colors.white10,
          onChanged: (v) => setState(() => _discount = v),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _endDate == null
                ? Colors.transparent
                : AppColors.gold.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campaign End Date',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _endDate == null
                      ? 'Select Date'
                      : _endDate!.toString().split(' ')[0],
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(Icons.calendar_today_rounded, color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}
