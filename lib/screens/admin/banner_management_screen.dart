import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/app_banner.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/services/firebase_service.dart';

class BannerManagementScreen extends StatefulWidget {
  const BannerManagementScreen({super.key});

  @override
  State<BannerManagementScreen> createState() => _BannerManagementScreenState();
}

class _BannerManagementScreenState extends State<BannerManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          'Banner Management',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.gold),
            onPressed: () => _openAddEditBanner(context),
          ),
        ],
      ),
      body: StreamBuilder<List<AppBanner>>(
        stream: _firebaseService.getAllBanners(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          final banners = snapshot.data ?? [];
          if (banners.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No banners found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return _buildBannerCard(banner);
            },
          );
        },
      ),
    );
  }

  Widget _buildBannerCard(AppBanner banner) {
    final auth = context.read<AuthProvider>();
    final performerId = auth.currentUser?.uid ?? 'unknown';

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                banner.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.background,
                  child: const Icon(
                    Icons.broken_image,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          ListTile(
            title: Text(
              banner.title ?? 'No Title',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Action: ${banner.actionType} (${banner.actionValue ?? 'No Value'})',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: Switch(
              value: banner.isActive,
              activeColor: AppColors.gold,
              onChanged: (val) {
                _firebaseService.updateBanner(
                  banner.copyWith(isActive: val),
                  performerId,
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                onPressed: () => _openAddEditBanner(context, banner: banner),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(banner),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(AppBanner banner) {
    final auth = context.read<AuthProvider>();
    final performerId = auth.currentUser?.uid ?? 'unknown';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Banner',
          style: TextStyle(color: AppColors.gold),
        ),
        content: const Text(
          'Are you sure you want to delete this banner?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              _firebaseService.deleteBanner(banner.id, performerId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openAddEditBanner(BuildContext context, {AppBanner? banner}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddEditBannerSheet(banner: banner),
      ),
    );
  }
}

class _AddEditBannerSheet extends StatefulWidget {
  final AppBanner? banner;
  const _AddEditBannerSheet({this.banner});

  @override
  State<_AddEditBannerSheet> createState() => _AddEditBannerSheetState();
}

class _AddEditBannerSheetState extends State<_AddEditBannerSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _imageUrlController;
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _actionValueController;
  late String _actionType;
  late bool _isActive;
  late int _order;
  bool _loading = false;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _imageUrlController = TextEditingController(
      text: widget.banner?.imageUrl ?? '',
    );
    _titleController = TextEditingController(text: widget.banner?.title ?? '');
    _subtitleController = TextEditingController(
      text: widget.banner?.subtitle ?? '',
    );
    _actionValueController = TextEditingController(
      text: widget.banner?.actionValue ?? '',
    );
    _actionType = widget.banner?.actionType ?? 'category';
    _isActive = widget.banner?.isActive ?? true;
    _order = widget.banner?.order ?? 0;
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _actionValueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final auth = context.read<AuthProvider>();
      final performerId = auth.currentUser?.uid ?? 'unknown';

      final banner = AppBanner(
        id: widget.banner?.id ?? '',
        imageUrl: _imageUrlController.text.trim(),
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        subtitle: _subtitleController.text.trim().isEmpty
            ? null
            : _subtitleController.text.trim(),
        actionType: _actionType,
        actionValue: _actionValueController.text.trim().isEmpty
            ? null
            : _actionValueController.text.trim(),
        isActive: _isActive,
        order: _order,
        createdAt: widget.banner?.createdAt ?? DateTime.now(),
      );

      if (widget.banner == null) {
        await _firebaseService.addBanner(banner, performerId);
      } else {
        await _firebaseService.updateBanner(banner, performerId);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.banner == null ? 'Add New Banner' : 'Edit Banner',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(labelText: 'Banner Image URL'),
              style: const TextStyle(color: AppColors.textPrimary),
              validator: (v) => v!.isEmpty ? 'Enter image URL' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title (Optional)'),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subtitleController,
              decoration: const InputDecoration(
                labelText: 'Subtitle (Optional)',
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _actionType,
              dropdownColor: AppColors.surface,
              decoration: const InputDecoration(labelText: 'Action Type'),
              items: ['category', 'subcategory', 'product', 'external']
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(
                        t,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _actionType = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _actionValueController,
              decoration: const InputDecoration(
                labelText: 'Action Value (ID or URL)',
              ),
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Active',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                const Spacer(),
                Switch(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeColor: AppColors.gold,
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: AppColors.black)
                  : Text(
                      widget.banner == null ? 'Add Banner' : 'Update Banner',
                      style: const TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
