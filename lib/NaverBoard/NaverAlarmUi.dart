import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'NaverAlarm.dart';


class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final NaverAlarm naverAlarm;
  late Stream<List<DocumentSnapshot>> notificationsStream;

  @override
  void initState() {
    super.initState();
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    naverAlarm = NaverAlarm(currentUserEmail, () => setState(() {}));
    notificationsStream = getNotifications();
  }

  // 알림 목록을 스트림 형태로 불러오는 함수
  Stream<List<DocumentSnapshot>> getNotifications() {
    return FirebaseFirestore.instance
        .collection('notifications') // 'notifications' 컬렉션을 사용합니다.
        .where('ownerEmail', isEqualTo: naverAlarm.currentUserEmail)
        .snapshots()
        .map((snapshot) => snapshot.docs.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('알림'),
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다.'));
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              // 각 알림을 위한 위젯을 구성합니다.
              return ListTile(
                title: Text(notification['title']), // 알림 제목
                subtitle: Text(notification['body']), // 알림 내용
                onTap: () {
                  // 알림을 탭할 때 수행할 작업을 여기에 작성합니다.
                },
              );
            },
          );
        },
      ),
    );
  }
}
