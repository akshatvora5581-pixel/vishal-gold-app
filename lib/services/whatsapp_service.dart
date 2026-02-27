import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  static const String adminNumber = '+919510687981';

  /// Notifies the admin via WhatsApp about a new design upload.
  static Future<void> notifyAdmin({
    required BuildContext context,
    required String customerName,
    required String customerPhone,
    required String category,
    required String itemName,
    required String qty,
    required String size,
    required String weight,
    required String totalWeight,
    required bool rodium,
    required bool huid,
    required String remarks,
    required List<String> imageUrls,
  }) async {
    // Formatting Boolean values
    final String rodiumText = rodium ? 'Yes' : 'No';
    final String huidText = huid ? 'Yes' : 'No';

    // Constructing the message using standard \n
    final String message =
        '👑 *NEW ORDER ALERT* 👑\n'
        '👤 *Customer:* $customerName\n'
        '📞 *Phone:* $customerPhone\n'
        '\n'
        '📦 *PRODUCT DETAILS*\n'
        '🔹 *Category:* $category\n'
        '🔹 *Item Name:* $itemName\n'
        '🔹 *Qty / Size:* $qty / $size\n'
        '🔹 *Weight / Total:* $weight / $totalWeight\n'
        '🔹 *Rodium:* $rodiumText | *HUID:* $huidText\n'
        '\n'
        '📝 *REMARKS:*\n'
        '$remarks\n'
        '\n'
        '🖼️ *DESIGN LINKS:*\n'
        '${imageUrls.asMap().entries.map((e) {
          final List<String> numberEmojis = ['1️⃣', '2️⃣', '3️⃣', '4️⃣'];
          final String emoji = e.key < numberEmojis.length ? numberEmojis[e.key] : '${e.key + 1}.';
          return '$emoji ${e.value}';
        }).join('\n')}';

    // Technical Fix: Use Uri.https to handle encoding properly
    final Uri uri = Uri.https('wa.me', '/919510687981', {'text': message});

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp not installed or could not be opened'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching WhatsApp: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Could not open WhatsApp'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
