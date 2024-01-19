import UIKit
import Flutter
import Firebase
import UserNotifications
import FirebaseMessaging
import FirebaseCore //Cannot find 'FirebaseApp' in scope  에러로 추가


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Firebase 초기화
        FirebaseApp.configure()
        
        // Flutter 플러그인 등록
        GeneratedPluginRegistrant.register(with: self)
        
        // iOS 기기에 알림 권한 요청 및 설정
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { _, _ in })
        
        // 원격 알림을 위한 등록
        application.registerForRemoteNotifications()
        
        // Firebase Messaging 델리게이트 설정
        Messaging.messaging().delegate = self

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // 아래 부분은 iOS 기기에서 APNs 토큰을 받았을 때 토큰을 출력하는 부분입니다.
    // 주석 처리하거나 제거하여 토큰 출력을 중지할 수 있습니다.
//
//    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
//        print("Device Token: \(token)")
//    }

    
    // 원격 알림을 수신했을 때 호출되는 메서드로, 알림을 처리하는 로직을 추가할 수 있습니다.
    override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                              fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // 푸시 알림을 처리하는 로직을 여기에 추가
    }

    // 앱이 실행 중일 때 푸시 알림을 화면에 표시하기 위한 설정
    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
}

// Firebase Messaging 델리게이트 구현
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            // Firebase에서 발급된 등록 토큰을 출력하고,
            print("Firebase registration token: \(token)")
            
            // NotificationCenter를 통해 Flutter 앱으로 토큰을 전달
            let dataDict: [String: String] = ["token": token]
            NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
        }
    }
}
