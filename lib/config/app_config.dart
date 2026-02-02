class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://cnxxfqktzkzjfnsaqqej.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNueHhmcWt0emt6amZuc2FxcWVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk5MjYyODQsImV4cCI6MjA4NTUwMjI4NH0.XJ5edyEyIrsllUX7JmoET_Xoyu5tQlhO4Nt3Cx1GlLc';

  // App Configuration
  static const String appName = 'Vishal Jewellers';
  static const int itemsPerPage = 20;
  static const int maxRecentViews = 30;
  static const int maxUploadImages = 10;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration splashDuration = Duration(seconds: 2);
}
