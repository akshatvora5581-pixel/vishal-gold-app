import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/admin.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/services/firebase_service.dart';

class SubAdminManagementScreen extends StatefulWidget {
  const SubAdminManagementScreen({super.key});

  @override
  State<SubAdminManagementScreen> createState() =>
      _SubAdminManagementScreenState();
}

class _SubAdminManagementScreenState extends State<SubAdminManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Admin Management',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.gold),
            onPressed: () => _showAddAdminSheet(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.getAdmins(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          final admins = snapshot.data!.docs
              .map(
                (doc) =>
                    Admin.fromJson(doc.data() as Map<String, dynamic>, doc.id),
              )
              .toList();

          if (admins.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sub-admins found',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: admins.length,
            itemBuilder: (context, index) {
              final admin = admins[index];
              return _buildAdminCard(context, admin);
            },
          );
        },
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, Admin admin) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(admin.role).withValues(alpha: 0.2),
          child: Text(
            admin.fullName[0].toUpperCase(),
            style: TextStyle(
              color: _getRoleColor(admin.role),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          admin.fullName,
          style: GoogleFonts.outfit(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              admin.email,
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(admin.role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                admin.role.toUpperCase(),
                style: TextStyle(
                  color: _getRoleColor(admin.role),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
          color: AppColors.surface,
          onSelected: (value) {
            if (value == 'edit') {
              _showEditRoleSheet(context, admin);
            } else if (value == 'delete') {
              _confirmDelete(context, admin);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text(
                'Change Role & Permissions',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Remove Admin', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super':
        return AppColors.gold;
      case 'admin':
        return Colors.green;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showAddAdminSheet(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedRole = 'admin';
    Map<String, bool> permissions = {
      'manage_products': false,
      'manage_users': false,
      'manage_orders': false,
      'manage_settings': false,
      'view_analytics': false,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Admin',
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.gold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('Full Name', Icons.person),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('Email Address', Icons.email),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Role',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ['admin', 'super'].map((role) {
                    bool isSelected = selectedRole == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(role.toUpperCase()),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setSheetState(() => selectedRole = role);
                        },
                        selectedColor: AppColors.gold.withValues(alpha: 0.2),
                        backgroundColor: AppColors.background,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.gold
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (selectedRole == 'admin') ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Permissions',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...permissions.keys.map((perm) {
                    return CheckboxListTile(
                      title: Text(
                        perm
                            .split('_')
                            .map((e) => e[0].toUpperCase() + e.substring(1))
                            .join(' '),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      value: permissions[perm],
                      onChanged: (val) {
                        setSheetState(() => permissions[perm] = val ?? false);
                      },
                      activeColor: AppColors.gold,
                      checkColor: AppColors.black,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty ||
                          emailController.text.isEmpty) {
                        return;
                      }
                      final performerId =
                          context.read<AuthProvider>().currentUser?.uid ??
                          'unknown';
                      await _firebaseService.addAdmin({
                        'full_name': nameController.text.trim(),
                        'email': emailController.text.trim(),
                        'role': selectedRole,
                        'permissions': selectedRole == 'admin'
                            ? permissions
                            : null,
                      }, performerId);
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add Admin',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditRoleSheet(BuildContext context, Admin admin) {
    String selectedRole = admin.role;
    Map<String, bool> permissions = Map.from(admin.permissions);

    // Ensure all keys exist
    for (String perm in [
      'manage_products',
      'manage_users',
      'manage_orders',
      'manage_settings',
      'view_analytics',
    ]) {
      permissions.putIfAbsent(perm, () => false);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Update Role for ${admin.fullName}',
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: ['admin', 'super'].map((role) {
                    bool isSelected = selectedRole == role;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(role.toUpperCase()),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setSheetState(() => selectedRole = role);
                        },
                        selectedColor: AppColors.gold.withValues(alpha: 0.2),
                        backgroundColor: AppColors.background,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.gold
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (selectedRole == 'admin') ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Permissions',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...permissions.keys.map((perm) {
                    return CheckboxListTile(
                      title: Text(
                        perm
                            .split('_')
                            .map((e) => e[0].toUpperCase() + e.substring(1))
                            .join(' '),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      value: permissions[perm],
                      onChanged: (val) {
                        setSheetState(() => permissions[perm] = val ?? false);
                      },
                      activeColor: AppColors.gold,
                      checkColor: AppColors.black,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final performerId =
                          context.read<AuthProvider>().currentUser?.uid ??
                          'unknown';
                      await _firebaseService.updateAdmin(
                        adminId: admin.id,
                        updates: {
                          'role': selectedRole,
                          'permissions': selectedRole == 'admin'
                              ? permissions
                              : null,
                        },
                        performedBy: performerId,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Admin admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Remove Admin',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove ${admin.fullName} from administrators?',
          style: const TextStyle(color: AppColors.textSecondary),
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
            onPressed: () async {
              final performerId =
                  context.read<AuthProvider>().currentUser?.uid ?? 'unknown';
              await _firebaseService.deleteAdmin(admin.id, performerId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.gold),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.gold),
      ),
      filled: true,
      fillColor: AppColors.background,
    );
  }
}
