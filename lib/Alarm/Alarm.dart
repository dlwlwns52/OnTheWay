import 'package:OnTheWay/Chat/AllUsersScreen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AlarmUi.dart';

class Alarm {
  int notificationCount = 0;
  String currentUserEmail;
  VoidCallback onNotificationCountChanged;
  BuildContext context;

  Alarm(this.currentUserEmail, this.onNotificationCountChanged, this.context) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (context != null) {
        _handleMessage(message);
      }
    });

    // 메시지 카운트 초기화
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    if (message.data['ownerEmail'] == currentUserEmail &&
        message.data['screen'] == 'AlarmUi') {
      await _initializeMessageCount(currentUserEmail);
      if (context != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AlarmUi(),
          ),
        );
      } else {
        print("Context is null");
      }
    } else if (message.data['screen'] == 'AllUsersScreen') {
      if (context != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AllUsersScreen(),
          ),
        );
      } else {
        print("Context is null");
      }
    }
  }

  Future<String?> getNickname(String email) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first['nickname'];
    }
    return null;
  }

  Future<void> resetMessageCount(String email) async {
    String? nickname = await getNickname(email);
    if (nickname != null) {
      DocumentReference docRef =
      FirebaseFirestore.instance.collection('userStatus').doc(nickname);

      await docRef.set({'messageCount': 0}, SetOptions(merge: true));
    }
  }

  Future<void> _initializeMessageCount(String email) async {
    if (email.isNotEmpty) {
      await resetMessageCount(email);
    }
  }
}
