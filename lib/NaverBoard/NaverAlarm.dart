import 'package:firebase_messaging/firebase_messaging.dart';

class NaverAlarm {
  int notificationCount = 0; // 알림 수
  String currentUserEmail; // 현재 로그인한 사용자의 이메일


  // 알림 리스너를 초기화하고 설정하는 생성자
  NaverAlarm(this.currentUserEmail) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // 앱이 포그라운드에 있을 때 메시지를 받으면 이 부분이 실행됩니다.
      // 알림 수를 증가시킵니다.
      print("$notificationCount 전");
      if (message.data['ownerEmail'] == currentUserEmail) {
        // 현재 사용자가 알림의 대상 사용자인 경우
        increaseNotificationCount();
        print("$notificationCount 후");
      }
    });

  }

  // 알림 수를 증가시키는 메서드
  void increaseNotificationCount() {
    notificationCount++;
  }

  // 알림 수를 0으로 초기화하는 메서드
  void resetNotificationCount() {
    notificationCount = 0;
  }

  // 현재 알림 수를 가져오는 메서드
  int getNotificationCount() {
    return notificationCount;
  }
}
