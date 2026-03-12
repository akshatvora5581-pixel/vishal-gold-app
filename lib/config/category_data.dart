class CategoryData {
  static const String category84 = '84_melting';
  static const String category92 = '92_melting';
  static const String categoryChains92 = '92_melting_chains';

  static const List<String> subcategories84 = [
    'Latkan 84M',
    'Mangalsutra 84M',
    'MS Dokiya 84M',
    'MS Pendal 84M',
    'Najariya 84M',
    'Najrana Ring 84M',
    'Nath 84M',
    'Patla 84M',
    'R Ladies Ring 84',
    'Round Gents Ring 84',
    'Rudraksh 84M',
    'Salman Bali 84M',
    'Set 84M',
    'Setbutty 84',
    'Step Butty 84',
    'Surya Pendal 84',
    'Tika 84M',
    'UV Bali 84',
    'Vertical Butty 84',
    'Vertical Dokiya 84M',
    'Zummar 84',
    'Zummar Butty 84',
    'Bachha Lucky 84M',
    'Bajubandh 84M',
    'Bali 84',
    'Butty 84',
    'China Butty 84',
    'Fancy Kadi 84',
    'Gents Ring 84',
    'Gol Butty 84',
    'J Butty 84',
    'Kanser 84M',
    'Kayda 84',
    'Ladies Lucky 84M',
    'Ladies Pendal 84M',
    'Ladies Ring 84',
    'Lappa Har 84',
  ];

  static const List<String> subcategories92 = [
    'Antiq Butty 92',
    'Antique Dokiya 92',
    'Bachhalucky 92M',
    'Bajubandh 92M',
    'Bali 92M',
    'Butty 92M',
    'China Butty 92',
    'CZ Butty 92',
    'CZ Gents Ring 92',
    'CZ Ladies Ring 92',
    'CZ MSP 92',
    'CZ Pandal Butty Set',
    'Fancy Kadi 92',
    'Gents Ring 92M',
    'Gol Butty 92',
    'J Butty 92',
    'Kanser 92M',
    'Kayda 92',
    'Keri Butty 92',
    'Ladies Lucky 92M',
    'Ladies Pendal 92M',
    'Long Ring 92',
    'Long Set 92',
    'Mangalsutra 92M',
    'MS Dokiya 92M',
    'MS Pendal 92M',
    'Najariya 92M',
    'Najrana Ring 92',
    'P. Casting GR',
    'P. Casting LR',
    'Patla 92M',
    'R Ladies Ring 92',
    'Rudraksh 92M',
    'Set 92M',
    'Setbutty 92',
    'Step Butty 92',
    'Surya Pendal 92M',
    'Tika 92M',
    'UV Bali 92',
    'Vertical Butty 92',
    'Vertical Dokiya 92M',
    'Zummar 92M',
    'Zummar Butty 92',
  ];

  static const List<String> subcategoriesChains92 = [
    'Handmade Chain 92M',
    'Hollow 92M',
    'Hollow Lucky 92M',
    'Indo Hollow 92M',
    'Lotus 92M',
    'Nice Chain 92M',
    'Silky 92M',
    'Singapuri 92M',
  ];

  static List<Map<String, dynamic>> getSubcategories(String category) {
    List<String> subNames;
    switch (category) {
      case category84:
        subNames = subcategories84;
        break;
      case category92:
        subNames = subcategories92;
        break;
      case categoryChains92:
        subNames = subcategoriesChains92;
        break;
      default:
        return [];
    }

    return subNames
        .map(
          (name) => <String, dynamic>{
            'name': name,
            'image': _getAssetForSubcategory(name),
          },
        )
        .toList();
  }

  static String _getAssetForSubcategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ring')) return 'assets/images/ring.webp';
    if (lower.contains('bangle') || lower.contains('patla')) {
      return 'assets/images/bangles.png';
    }
    if (lower.contains('chain')) return 'assets/images/chain.webp';
    if (lower.contains('bali') ||
        lower.contains('butty') ||
        lower.contains('earring')) {
      return 'assets/images/earrings.png';
    }
    if (lower.contains('set') ||
        lower.contains('har') ||
        lower.contains('neck')) {
      return 'assets/images/necklaces.png';
    }
    if (lower.contains('lucky') ||
        lower.contains('bracelet') ||
        lower.contains('kadi')) {
      return 'assets/images/bracelets.png';
    }
    return 'assets/images/gold_chain.png'; // Updated default fallback
  }
}
