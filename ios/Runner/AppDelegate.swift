import UIKit
import Flutter
import Firebase
import UserNotifications
import FirebaseMessaging

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        GeneratedPluginRegistrant.register(with: self)
        
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { _, _ in })
        
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // 이 부분을 주석 처리하거나 제거하여 APNs 토큰을 출력하지 않도록 할 수 있습니다.
    /*
    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(token)")
    }
    */
    
    // 푸시 알림을 수신할 때 호출되는 메서드는 그대로 유지
    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                              fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // 푸시 알림을 처리
    }

    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("Firebase registration token: \(token)")
            let dataDict: [String: String] = ["token": token]
            NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        }
    }
}





//import UIKit
//import Flutter
//import Firebase
//import UserNotifications
//
//@UIApplicationMain
//@objc class AppDelegate: FlutterAppDelegate {
//    override func application(
//        _ application: UIApplication,
//        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//    ) -> Bool {
//        FirebaseApp.configure()
//        GeneratedPluginRegistrant.register(with: self)
//
//        UNUserNotificationCenter.current().delegate = self
//        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { _, _ in })
//
//        application.registerForRemoteNotifications()
//
//        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//    }
//
//    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        // 디바이스 토큰을 16진수 문자열로 변환
//        let tokenParts = deviceToken.map { data in String(data) }
//        let token = tokenParts.joined()
//        
//        // 로그로 디바이스 토큰 출력
//        print("Device Token: \(token)")
//    }
//
//    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
//                              fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        // 푸시 알림을 처리
//    }
//
//    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
//                                        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        completionHandler([.alert, .badge, .sound])  // 알림 옵션 설정
//    }
//}

//
//import UIKit
//import Flutter
//import Firebase  // Firebase 라이브러리를 import합니다.
//import UserNotifications  // UserNotifications 프레임워크를 import합니다.
//
//@UIApplicationMain
//@objc class AppDelegate: FlutterAppDelegate {
//    override func application(
//        
//        _ application: UIApplication,
//        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//    ) -> Bool {
//        FirebaseApp.configure()  // Firebase를 초기화합니다.
//        GeneratedPluginRegistrant.register(with: self)
//
//        // 푸시 알림을 위한 권한 요청
//        UNUserNotificationCenter.current().delegate = self
//        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { _, _ in })
//
//        application.registerForRemoteNotifications()  // 디바이스 토큰을 위한 등록
//
//        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//    }
//
//    // 디바이스 토큰이 성공적으로 등록되었을 때 호출되는 메소드
//    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        // 디바이스 토큰을 Firebase에 등록
//        
//    }
//
//    // 푸시 알림 수신 시 호출되는 메소드
//    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
//                              fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        // 푸시 알림을 처리
//    }
//
//    // 앱이 포그라운드 상태일 때 푸시 알림이 도착하면 호출되는 메소드
//    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
//                                        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
//        completionHandler([.alert, .badge, .sound])  // 알림 옵션 설정
//    }
//}


