class OAuthConfig {
  // Supabase OAuth configuration
  static const String supabaseUrl = 'https://fjsrzduddrgciuytkrad.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZqc3J6ZHVkZHJnY2l1eXRrcmFkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA5MjAyNTUsImV4cCI6MjA2NjQ5NjI1NX0.LwyrVqvWKxLmoZZc7uzC8vvIkiYz9tjbN1f-zVXzR5g';

  // OAuth redirect URLs
  static const String webRedirectUrl = 'https://fjsrzduddrgciuytkrad.supabase.co/auth/v1/callback';
  static const String mobileRedirectUrl = 'io.supabase.flutter://login-callback';
  
  // Alternative mobile redirect URL format that might work better
  static const String mobileRedirectUrlAlt = 'io.supabase.flutter://';
  
  // Get the appropriate redirect URL based on platform
  static String getRedirectUrl(bool isWeb) {
    return isWeb ? webRedirectUrl : mobileRedirectUrl;
  }
  
  // Get mobile redirect URL with different formats to try
  static String getMobileRedirectUrl() {
    // Try the standard format first
    return mobileRedirectUrl;
  }

  // Google OAuth configuration (placeholders kept for potential platform needs)
  static const String googleClientId = '107140583191311884519';
  static const String googleClientIdIos = 'com.googleusercontent.apps.107140583191311884519';

  // Get Google client ID based on platform
  static String getGoogleClientId(bool isIos) {
    return isIos ? googleClientIdIos : googleClientId;
  }
}