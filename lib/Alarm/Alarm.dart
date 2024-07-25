import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'AlarmUi.dart';


class Alarm  {
  int notificationCount = 0;
  String currentUserEmail;
  VoidCallback onNotificationCountChanged;
  BuildContext context; // BuildContext 추가

  Alarm(this.currentUserEmail, this.onNotificationCountChanged, this.context) {

    // 사용자가 앱을 백그라운드나 종료 상태에서 시작할 때 호출
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });


    // 앱이 포그라운드에 있을 때 호출
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (context != null) { // context가 null이 아닌지 확인
        _handleMessage(message);
      }
    });
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data['ownerEmail'] == currentUserEmail) {//
      increaseNotificationCount();

        if (context != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AlarmUi(),
            ),
          );

        } else {
          print("Context is null");
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
