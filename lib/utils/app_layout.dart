import 'package:flutter/material.dart';

/// Central responsive layout utility.
///
/// Usage:
/// ```dart
/// final layout = AppLayout.of(context);
/// GridView.builder(
///   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
///     crossAxisCount: layout.productGridColumns,
///   ),
/// )
/// ```
class AppLayout {
  final double screenWidth;
  final double screenHeight;
  final bool isLandscape;

  const AppLayout._({
    required this.screenWidth,
    required this.screenHeight,
    required this.isLandscape,
  });

  factory AppLayout.of(BuildContext context) {
    final mq = MediaQuery.of(context);
    return AppLayout._(
      screenWidth: mq.size.width,
      screenHeight: mq.size.height,
      isLandscape: mq.orientation == Orientation.landscape,
    );
  }

  // ── Breakpoints ──────────────────────────────────────────────────────────

  /// < 360dp
  bool get isSmall => screenWidth < 360;

  /// 360 – 599dp  (most Android phones)
  bool get isPhone => screenWidth >= 360 && screenWidth < 600;

  /// 600 – 839dp  (large phones, foldables half-open)
  bool get isLargePhone => screenWidth >= 600 && screenWidth < 840;

  /// ≥ 840dp  (tablets, foldables fully open)
  bool get isTablet => screenWidth >= 840;

  // ── Grid Columns ─────────────────────────────────────────────────────────

  /// Product / category grids: 2 → 3 → 4 as screen gets wider.
  int get productGridColumns {
    if (isTablet) return 4;
    if (isLargePhone) return 3;
    return 2;
  }

  /// Admin module grid: same breakpoints.
  int get adminModuleColumns {
    if (isTablet) return 4;
    if (isLargePhone) return 3;
    return 2;
  }

  /// All-subcategories grid: phones=2, large=3, tablet=4
  int get subcategoryGridColumns {
    if (isTablet) return 4;
    if (isLargePhone) return 3;
    return 2;
  }

  // ── Spacing & Padding ────────────────────────────────────────────────────

  /// Horizontal screen padding.
  double get horizontalPadding {
    if (isTablet) return 32;
    if (isLargePhone) return 24;
    if (isSmall) return 12;
    return 16;
  }

  /// Vertical padding between major sections.
  double get sectionSpacing {
    if (isTablet) return 36;
    if (isLargePhone) return 28;
    return 20;
  }

  /// Standard card border radius.
  double get cardRadius {
    if (isTablet) return 20;
    return 16;
  }

  // ── Typography ───────────────────────────────────────────────────────────

  double get titleFontSize {
    if (isTablet) return 30;
    if (isLargePhone) return 26;
    return 22;
  }

  double get bodyFontSize {
    if (isTablet) return 16;
    return 14;
  }

  double get captionFontSize {
    if (isTablet) return 13;
    return 11;
  }

  // ── Category Horizontal List ─────────────────────────────────────────────

  /// Width of a subcategory card in horizontal lists.
  double get categoryCardWidth {
    if (isTablet) return 180;
    if (isLargePhone) return 155;
    if (isSmall) return 115;
    return 135;
  }

  /// Height of the subcategory horizontal list container.
  double get categoryListHeight {
    if (isTablet) return 220;
    if (isLargePhone) return 200;
    if (isSmall) return 155;
    return 175;
  }

  // ── Banner Carousel ──────────────────────────────────────────────────────

  double get bannerHeight {
    if (isTablet) return screenWidth * 0.35;
    if (isLargePhone) return screenWidth * 0.42;
    return screenWidth * 0.50;
  }

  // ── Product Grid Aspect Ratio ────────────────────────────────────────────

  /// childAspectRatio for product grids (width ÷ height of each card).
  double get productCardAspectRatio {
    if (isTablet) return 0.62;
    if (isLargePhone) return 0.65;
    if (isSmall) return 0.68;
    return 0.65;
  }

  // ── Admin Stat Tile ──────────────────────────────────────────────────────

  double get statTileWidth {
    if (isTablet) return 170;
    if (isLargePhone) return 150;
    return 125;
  }

  double get adminHeaderHeight {
    if (isTablet) return 240;
    return 200;
  }

  // ── Admin Module Card ─────────────────────────────────────────────────────

  double get adminModuleAspectRatio {
    if (isTablet) return 2.4;
    if (isLargePhone) return 2.1;
    return 1.9;
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  /// Whether to show NavigationRail instead of BottomNav.
  bool get useNavigationRail => isTablet && isLandscape;
}
