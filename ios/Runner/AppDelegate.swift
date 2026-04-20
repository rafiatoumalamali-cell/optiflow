import Flutter
import UIKit
import GoogleMaps // 🚩 ADDED

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 🚩 PASTE YOUR GOOGLE MAPS API KEY IN THE LINE BELOW
    GMSServices.provideAPIKey("AIzaSyBotQKApNILQ4NZIm6UTXDv1sDEqODDVtc")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
