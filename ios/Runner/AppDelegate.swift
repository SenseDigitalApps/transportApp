import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyDn9k7vvdxbJgDgjpCFRXJOdLilbGfVlNA")
    GeneratedPluginRegistrant.register(with: self)

    // Registrar para notificaciones push (necesario con FirebaseAppDelegateProxyEnabled = false)
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("Error registrando notificaciones push: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // Manejar deep link cuando la app está abierta o se abre via URL
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // queryapp://pago-exitoso?collection_id=...&status=approved
    // Flutter lo maneja via app_links plugin
    return super.application(app, open: url, options: options)
  }
}