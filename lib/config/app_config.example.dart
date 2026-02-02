/// App configuration template
///
/// Copy this file to `app_config.dart` and replace with your actual Supabase credentials.
///
/// To get your credentials:
/// 1. Go to https://supabase.com and create a project
/// 2. Go to Project Settings → API
/// 3. Copy the URL and anon/public key
///
class AppConfig {
  // Supabase Configuration - REPLACE THESE WITH YOUR VALUES
  static const String supabaseUrl = 'https://YOUR_PROJECT_REF.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY_HERE';

  // App Configuration
  static const String appName = 'Vishal Jewellers';
  static const int itemsPerPage = 20;
  static const int maxRecentViews = 30;
  static const int maxUploadImages = 10;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration splashDuration = Duration(seconds: 2);
}
