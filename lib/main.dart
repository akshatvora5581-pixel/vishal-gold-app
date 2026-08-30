import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:vishal_jewelers/services/local_storage_service.dart';
import 'package:vishal_jewelers/constants/app_colors.dart';
import 'package:vishal_jewelers/constants/app_strings.dart';
import 'package:vishal_jewelers/providers/auth_provider.dart';
import 'package:vishal_jewelers/providers/cart_provider.dart';
import 'package:vishal_jewelers/providers/product_provider.dart';
import 'package:vishal_jewelers/providers/order_provider.dart';
import 'package:vishal_jewelers/providers/wishlist_provider.dart';
import 'package:vishal_jewelers/providers/preview_provider.dart';
import 'package:vishal_jewelers/providers/notification_provider.dart';
import 'package:vishal_jewelers/providers/language_provider.dart';
import 'package:vishal_jewelers/providers/notification_settings_provider.dart';
import 'package:vishal_jewelers/widgets/auth/auth_wrapper.dart';
import 'package:vishal_jewelers/widgets/shared/presence_wrapper.dart';
import 'package:vishal_jewelers/services/fcm_service.dart';

/// Global navigator key — used by FCMService for deep-link navigation
/// when a push notification is tapped from background/terminated state.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await LocalStorageService.init();

    // --- Firebase Setup ---
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode ? const AppleDebugProvider() : const AppleDeviceCheckProvider(),
    );
    // NOTE: appVerificationDisabledForTesting is intentionally NOT set here
    // because it only works for test phone numbers, NOT real phone numbers.
    // Real numbers need a valid App Check attestation token (above).

    // Initialize FCM and inject the navigator key for deep-link navigation
    final fcmService = FCMService();
    fcmService.navigatorKey = navigatorKey;
    await fcmService.initialize();

    // Initialize Analytics
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  } catch (e) {
    debugPrint('Initialization error: $e');
  }

  // Use a targeted error boundary for the top-level app
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Global Flutter Error: ${details.exception}');
  };

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
        ChangeNotifierProvider(create: (_) => PreviewProvider()),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, auth, notif) =>
              notif!..updateUser(auth.currentUser?.uid, isAdmin: auth.isAdmin),
        ),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => NotificationSettingsProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.dark(
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
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.gold, width: 1.5),
            ),
            labelStyle: TextStyle(color: AppColors.textSecondary),
            hintStyle: TextStyle(color: AppColors.textTertiary),
          ),
        ),
        home: const PresenceWrapper(child: AuthWrapper()),
      ),
    );
  }
}
