import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // <--- Professional setup import
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/constants/app_strings.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/providers/cart_provider.dart';
import 'package:vishal_gold/providers/product_provider.dart';
import 'package:vishal_gold/providers/order_provider.dart';
import 'package:vishal_gold/providers/wishlist_provider.dart';
import 'package:vishal_gold/screens/splash_screen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // --- Firebase Setup Cleaned ---
    // Ab ye khud hi Android, Web aur iOS ko detect kar lega.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Seed initial data in background (don't block the UI)
    FirebaseService().seedInitialData().catchError((e) {
      debugPrint('Error seeding data: $e');
    });
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.dark(
            primary: AppColors.gold,
            secondary: AppColors.softGold,
            surface: AppColors.surface,
            error: AppColors.errorRed,
            onPrimary: AppColors.black,
            onSecondary: AppColors.black,
            onSurface: AppColors.textPrimary,
            onError: AppColors.black,
          ),
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.outfitTextTheme().copyWith(
            displayLarge: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            displayMedium: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            displaySmall: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            headlineLarge: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            headlineMedium: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            titleLarge: GoogleFonts.playfairDisplay(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: GoogleFonts.outfit(color: AppColors.textPrimary),
            bodyMedium: GoogleFonts.outfit(color: AppColors.textSecondary),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: 1.0,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.black,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
            ),
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            hintStyle: const TextStyle(color: AppColors.textTertiary),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}