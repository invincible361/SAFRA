import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // TODO: Replace with your actual Google Maps API key
    // For production, consider using a more secure method like keychain or build-time configuration
    GMSServices.provideAPIKey("AIzaSyA1nhqmZMTFmqktFcJML_6WR5PDFGqH6N8")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
