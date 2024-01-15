// import 'package:firebase_messaging/firebase_messaging.dart';
//
// class NaverAlarm {
//   int notificationCount = 0; // 알림 수
//   String currentUserEmail; // 현재 로그인한 사용자의 이메일
//   Function onNotificationCountChanged;
//
//   // 알림 리스너를 초기화하고 설정하는 생성자
//   NaverAlarm(this.currentUserEmail, this.onNotificationCountChanged) {
//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message)  {
//       // 알림 수를 증가시킵니다.
//       if (message.data['ownerEmail'] == currentUserEmail) {// 현재 사용자가 알림의 대상 사용자인 경우
//         increaseNotificationCount();// 알림 수를 증가시킵니다.
//
//       }
//     });
//
//   }
//
//
//   // 알림 수를 증가시키는 메서드
//   void increaseNotificationCount() {
//     notificationCount += 1;
//     if (onNotificationCountChanged != null) {
//       onNotificationCountChanged();
//     }
//   }
//
//   void resetNotificationCount() {
//     notificationCount = 0;
//     if (onNotificationCountChanged != null) {
//       onNotificationCountChanged();
//     }
//   }
//
//   // 현재 알림 수를 가져오는 메서드
//   int getNotificationCount() {
//     return notificationCount;
//   }
// }


import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class NaverAlarm {
  int notificationCount = 0;
  String currentUserEmail;
  VoidCallback onNotificationCountChanged;

  NaverAlarm(this.currentUserEmail, this.onNotificationCountChanged) {
    // 사용자가 앱을 백그라운드나 종료 상태에서 시작할 때 호출
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    // 앱이 포그라운드에 있을 때 호출
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    // 백그라운드 메시지 처리 (별도의 Isolate에서 실행)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data['ownerEmail'] == currentUserEmail) {
      increaseNotificationCount();
    }
    // 여기에서 추가적인 알림 처리 로직을 구현할 수 있습니다.
  }

  void increaseNotificationCount() {
    notificationCount += 1;
    onNotificationCountChanged();
  }

  void resetNotificationCount() {
    notificationCount = 0;
    onNotificationCountChanged();
  }

  int getNotificationCount() {
    return notificationCount;
  }
}

// 백그라운드 메시지 처리를 위한 핸들러
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 백그라운드에서 알림이 수신 될 때 필요한 처리를 여기에 구현합니다. 예를 들어, 로컬 알림을 표시하거나,
// 특정 데이터를 로컬 데이터베이스에 저장하는 등의 작업을 수행할 수 있습니다.
  print("Handling a background message: ${message.messageId}");
}