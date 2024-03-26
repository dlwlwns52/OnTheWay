import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'AlarmUi.dart';

class Alarm  {
  int notificationCount = 0;
  String currentUserEmail;
  VoidCallback onNotificationCountChanged;
  BuildContext context; // BuildContext 추가

  Alarm(this.currentUserEmail, this.onNotificationCountChanged, this.context) {
    // 사용자가 앱을 백그라운드나 종료 상태에서 시작할 때 호출 9840
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });
    // 푸시 알림에 'screen' 데이터가 포함되어 있는 경우, 해당 화면으로 이동


    // 앱이 포그라운드에 있을 때 호출 // -> 이거왜안되지
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
      print(2);
      // print(FirebaseMessaging.onMessage);
    });

    // 백그라운드 메시지 처리 (별도의 Isolate에서 실행)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data['ownerEmail'] == currentUserEmail) {
      increaseNotificationCount();


      if (message.data['screen'] == 'AlarmUi') {
        // BuildContext를 사용하여 화면 전환
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AlarmUi()));
      }
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