import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('kn')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SAFRA App'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Get Started'**
  String get getStarted;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @verificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get enterVerificationCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @setPassword.
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get setPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save Password'**
  String get savePassword;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @streetView.
  ///
  /// In en, this message translates to:
  /// **'Street View'**
  String get streetView;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @securitySettings.
  ///
  /// In en, this message translates to:
  /// **'Security Settings'**
  String get securitySettings;

  /// No description provided for @biometricAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricAuthentication;

  /// No description provided for @enableBiometric.
  ///
  /// In en, this message translates to:
  /// **'Enable Biometric'**
  String get enableBiometric;

  /// No description provided for @disableBiometric.
  ///
  /// In en, this message translates to:
  /// **'Disable Biometric'**
  String get disableBiometric;

  /// No description provided for @pinCode.
  ///
  /// In en, this message translates to:
  /// **'PIN Code'**
  String get pinCode;

  /// No description provided for @setPinCode.
  ///
  /// In en, this message translates to:
  /// **'Set PIN Code'**
  String get setPinCode;

  /// No description provided for @removePinCode.
  ///
  /// In en, this message translates to:
  /// **'Remove PIN Code'**
  String get removePinCode;

  /// No description provided for @enterPinCode.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN Code'**
  String get enterPinCode;

  /// No description provided for @confirmPinCode.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN Code'**
  String get confirmPinCode;

  /// No description provided for @pinCodesDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'PIN codes do not match'**
  String get pinCodesDoNotMatch;

  /// No description provided for @authenticationRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication Required'**
  String get authenticationRequired;

  /// No description provided for @pleaseAuthenticate.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate'**
  String get pleaseAuthenticate;

  /// No description provided for @useBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use Biometric'**
  String get useBiometric;

  /// No description provided for @usePinCode.
  ///
  /// In en, this message translates to:
  /// **'Use PIN Code'**
  String get usePinCode;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid password'**
  String get invalidPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password too short'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// No description provided for @checkConnection.
  ///
  /// In en, this message translates to:
  /// **'Check connection'**
  String get checkConnection;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pin;

  /// No description provided for @pinAuthenticationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'PIN authentication successful! Please use your credentials to login.'**
  String get pinAuthenticationSuccessful;

  /// No description provided for @incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN. Please use your credentials.'**
  String get incorrectPin;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get pleaseEnterEmail;

  /// No description provided for @passwordResetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to your email'**
  String get passwordResetLinkSent;

  /// No description provided for @errorLoadingSecurityStatus.
  ///
  /// In en, this message translates to:
  /// **'Error loading security status'**
  String get errorLoadingSecurityStatus;

  /// No description provided for @faceRecognitionEnabledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Face Recognition enabled successfully!'**
  String get faceRecognitionEnabledSuccessfully;

  /// No description provided for @faceRecognitionEnabled.
  ///
  /// In en, this message translates to:
  /// **'Face Recognition enabled! Please test by signing out and back in.'**
  String get faceRecognitionEnabled;

  /// No description provided for @faceRecognitionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Face Recognition disabled successfully!'**
  String get faceRecognitionDisabled;

  /// No description provided for @pinCodeSetSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PIN code set successfully!'**
  String get pinCodeSetSuccessfully;

  /// No description provided for @pinCodeRemovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PIN code removed successfully!'**
  String get pinCodeRemovedSuccessfully;

  /// No description provided for @biometricNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric not available'**
  String get biometricNotAvailable;

  /// No description provided for @biometricNotEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Biometric not enrolled'**
  String get biometricNotEnrolled;

  /// No description provided for @biometricAuthenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication failed'**
  String get biometricAuthenticationFailed;

  /// No description provided for @biometricAuthenticationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication successful'**
  String get biometricAuthenticationSuccess;

  /// No description provided for @pinCodeSet.
  ///
  /// In en, this message translates to:
  /// **'PIN code set'**
  String get pinCodeSet;

  /// No description provided for @pinCodeRemoved.
  ///
  /// In en, this message translates to:
  /// **'PIN code removed'**
  String get pinCodeRemoved;

  /// No description provided for @biometricEnabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric enabled'**
  String get biometricEnabled;

  /// No description provided for @biometricDisabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric disabled'**
  String get biometricDisabled;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @kannada.
  ///
  /// In en, this message translates to:
  /// **'Kannada'**
  String get kannada;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @disableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Disable Notifications'**
  String get disableNotifications;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @shareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share Location'**
  String get shareLocation;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @customMessage.
  ///
  /// In en, this message translates to:
  /// **'Custom Message (Optional)'**
  String get customMessage;

  /// No description provided for @includeAddress.
  ///
  /// In en, this message translates to:
  /// **'Include Address'**
  String get includeAddress;

  /// No description provided for @addressRequiresInternet.
  ///
  /// In en, this message translates to:
  /// **'Address requires internet connection'**
  String get addressRequiresInternet;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @searchPlaces.
  ///
  /// In en, this message translates to:
  /// **'Search Places'**
  String get searchPlaces;

  /// No description provided for @searchForPlaces.
  ///
  /// In en, this message translates to:
  /// **'Search for places...'**
  String get searchForPlaces;

  /// No description provided for @pleaseFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get pleaseFillAllFields;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials'**
  String get invalidCredentials;

  /// No description provided for @noPlacesFound.
  ///
  /// In en, this message translates to:
  /// **'No places found'**
  String get noPlacesFound;

  /// No description provided for @selectPlace.
  ///
  /// In en, this message translates to:
  /// **'Select Place'**
  String get selectPlace;

  /// No description provided for @placeDetails.
  ///
  /// In en, this message translates to:
  /// **'Place Details'**
  String get placeDetails;

  /// No description provided for @startNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start Navigation'**
  String get startNavigation;

  /// No description provided for @calculatingRoute.
  ///
  /// In en, this message translates to:
  /// **'Calculating Route...'**
  String get calculatingRoute;

  /// No description provided for @switchToMap.
  ///
  /// In en, this message translates to:
  /// **'Switch to Map'**
  String get switchToMap;

  /// No description provided for @routeProgress.
  ///
  /// In en, this message translates to:
  /// **'Route Progress'**
  String get routeProgress;

  /// No description provided for @destination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openInMaps;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @navigationGuidance.
  ///
  /// In en, this message translates to:
  /// **'Navigation Guidance'**
  String get navigationGuidance;

  /// No description provided for @smsAppOpened.
  ///
  /// In en, this message translates to:
  /// **'SMS app opened! If no SMS app is available, the message may have been copied to clipboard.'**
  String get smsAppOpened;

  /// No description provided for @smsAppNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Could not open SMS app. Please try manually sending the location.'**
  String get smsAppNotAvailable;

  /// No description provided for @smsWebLimited.
  ///
  /// In en, this message translates to:
  /// **'SMS functionality is limited on web browsers. The app will try to open your SMS app.'**
  String get smsWebLimited;

  /// No description provided for @selectContact.
  ///
  /// In en, this message translates to:
  /// **'Select Contact'**
  String get selectContact;

  /// No description provided for @searchContacts.
  ///
  /// In en, this message translates to:
  /// **'Search contacts...'**
  String get searchContacts;

  /// No description provided for @favoriteContacts.
  ///
  /// In en, this message translates to:
  /// **'Favorite Contacts'**
  String get favoriteContacts;

  /// No description provided for @noContactsFound.
  ///
  /// In en, this message translates to:
  /// **'No contacts found'**
  String get noContactsFound;

  /// No description provided for @noContactsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No contacts available'**
  String get noContactsAvailable;

  /// No description provided for @addContacts.
  ///
  /// In en, this message translates to:
  /// **'Add Contacts'**
  String get addContacts;

  /// No description provided for @contactPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Contact permission denied'**
  String get contactPermissionDenied;

  /// No description provided for @contactPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Contact permission is required to access your contacts'**
  String get contactPermissionRequired;

  /// No description provided for @viewDirections.
  ///
  /// In en, this message translates to:
  /// **'View Directions'**
  String get viewDirections;

  /// No description provided for @openInGoogleMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Google Maps'**
  String get openInGoogleMaps;

  /// No description provided for @aiRouteSelection.
  ///
  /// In en, this message translates to:
  /// **'AI Route Selection'**
  String get aiRouteSelection;

  /// No description provided for @analyzingRoutes.
  ///
  /// In en, this message translates to:
  /// **'Analyzing routes with AI...'**
  String get analyzingRoutes;

  /// No description provided for @routePreferences.
  ///
  /// In en, this message translates to:
  /// **'Route Preferences'**
  String get routePreferences;

  /// No description provided for @preferFastest.
  ///
  /// In en, this message translates to:
  /// **'Prefer fastest route'**
  String get preferFastest;

  /// No description provided for @preferEcoFriendly.
  ///
  /// In en, this message translates to:
  /// **'Prefer eco-friendly route'**
  String get preferEcoFriendly;

  /// No description provided for @avoidTraffic.
  ///
  /// In en, this message translates to:
  /// **'Avoid traffic'**
  String get avoidTraffic;

  /// No description provided for @preferScenic.
  ///
  /// In en, this message translates to:
  /// **'Prefer scenic route'**
  String get preferScenic;

  /// No description provided for @preferSafe.
  ///
  /// In en, this message translates to:
  /// **'Prefer safe route'**
  String get preferSafe;

  /// No description provided for @maxDuration.
  ///
  /// In en, this message translates to:
  /// **'Maximum Duration (minutes)'**
  String get maxDuration;

  /// No description provided for @advantages.
  ///
  /// In en, this message translates to:
  /// **'Advantages'**
  String get advantages;

  /// No description provided for @considerations.
  ///
  /// In en, this message translates to:
  /// **'Considerations'**
  String get considerations;

  /// No description provided for @lowTraffic.
  ///
  /// In en, this message translates to:
  /// **'Low Traffic'**
  String get lowTraffic;

  /// No description provided for @mediumTraffic.
  ///
  /// In en, this message translates to:
  /// **'Medium Traffic'**
  String get mediumTraffic;

  /// No description provided for @highTraffic.
  ///
  /// In en, this message translates to:
  /// **'High Traffic'**
  String get highTraffic;

  /// No description provided for @pleaseSetDestination.
  ///
  /// In en, this message translates to:
  /// **'Please set a destination first'**
  String get pleaseSetDestination;

  /// No description provided for @loadingRoute.
  ///
  /// In en, this message translates to:
  /// **'Loading route...'**
  String get loadingRoute;

  /// No description provided for @routeLoaded.
  ///
  /// In en, this message translates to:
  /// **'Route loaded successfully!'**
  String get routeLoaded;

  /// No description provided for @errorLoadingRoute.
  ///
  /// In en, this message translates to:
  /// **'Error loading route'**
  String get errorLoadingRoute;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi', 'kn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
    case 'kn': return AppLocalizationsKn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
