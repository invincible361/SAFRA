# SAFRA App

A Flutter application with Google Maps integration and Supabase authentication.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## API Key Configuration

### Google Maps API Key

This app uses Google Maps API. To set up your API key:

1. **Get your API key** from [Google Cloud Console](https://console.cloud.google.com/)
2. **Create environment files**:
   - Copy `.env.example` to `.env`
   - Copy `android/gradle.properties.example` to `android/gradle.properties`
3. **Add your API key** to both files:
   - In `.env`: `GOOGLE_MAPS_API_KEY=your_actual_api_key_here`
   - In `android/gradle.properties`: `GOOGLE_MAPS_API_KEY=your_actual_api_key_here`

### Security Notes

- Never commit your actual API keys to version control
- The `.env` and `android/gradle.properties` files are already in `.gitignore`
- Use the example files as templates for other developers

## Dependencies

Run `flutter pub get` to install dependencies.
