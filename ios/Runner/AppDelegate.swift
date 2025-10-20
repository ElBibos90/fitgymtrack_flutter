import Flutter
import UIKit
import Firebase
import UserNotifications
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 🔥 Firebase Configuration
    FirebaseApp.configure()
    
    // 🔔 Push Notifications Setup
    setupPushNotifications(application)
    
    // 📱 Flutter Plugin Registration
    GeneratedPluginRegistrant.register(with: self)
    
    // 🔔 Setup Badge Channel
    setupBadgeChannel()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // 🔔 Setup Push Notifications
  private func setupPushNotifications(_ application: UIApplication) {
    // Request notification permissions
    UNUserNotificationCenter.current().delegate = self
    
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(
      options: authOptions,
      completionHandler: { granted, error in
        print("🔔 [iOS] Notification permission granted: \(granted)")
        if let error = error {
          print("🔔 [iOS] Notification permission error: \(error)")
        }
      }
    )
    
    // Register for remote notifications
    application.registerForRemoteNotifications()
    
    // Set FCM messaging delegate
    Messaging.messaging().delegate = self
  }
  
  // 🔔 Setup Badge Channel
  private func setupBadgeChannel() {
    let controller = window?.rootViewController as! FlutterViewController
    let badgeChannel = FlutterMethodChannel(name: "flutter_badge_channel", binaryMessenger: controller.binaryMessenger)
    
    badgeChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "setBadgeCount":
        if let args = call.arguments as? [String: Any],
           let count = args["count"] as? Int {
          DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
            print("🔔 [iOS] Badge count set to: \(count)")
            result(nil)
          }
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
  
  // 📱 Handle APNs Token Registration
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("🔔 [iOS] APNs token registered successfully")
    Messaging.messaging().apnsToken = deviceToken
  }
  
  override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("🔔 [iOS] Failed to register for remote notifications: \(error)")
  }
}

// 🔔 UNUserNotificationCenterDelegate
extension AppDelegate {
  
  // Handle notification when app is in foreground
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                             willPresent notification: UNNotification,
                             withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    print("🔔 [iOS] Foreground notification received: \(userInfo)")
    
    // Show notification even when app is in foreground
    completionHandler([[.alert, .badge, .sound]])
  }
  
  // Handle notification tap
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                             didReceive response: UNNotificationResponse,
                             withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("🔔 [iOS] Notification tapped: \(userInfo)")
    
    // Handle notification tap - you can add navigation logic here
    handleNotificationTap(userInfo)
    
    completionHandler()
  }
  
  private func handleNotificationTap(_ userInfo: [AnyHashable: Any]) {
    // Extract notification data
    if let notificationId = userInfo["notification_id"] as? String {
      print("🔔 [iOS] Opening notification: \(notificationId)")
      // TODO: Navigate to specific screen based on notification type
    }
  }
}

// 🔥 Firebase Messaging Delegate
extension AppDelegate: MessagingDelegate {
  
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔔 [iOS] FCM registration token: \(fcmToken ?? "nil")")
    
    // Send token to your server
    if let token = fcmToken {
      sendTokenToServer(token)
    }
  }
  
  private func sendTokenToServer(_ token: String) {
    // TODO: Implement server call to register FCM token
    print("🔔 [iOS] Sending FCM token to server: \(token)")
    
    // This should call your API to register the token
    // Similar to what's already implemented in FirebaseService.dart
  }
}

