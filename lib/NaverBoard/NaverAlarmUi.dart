import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'NaverAlarm.dart'; // NaverAlarm 클래스를 가져옵니다.

class NaverAlarmUi extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NaverAlarmUi> {
  late final NaverAlarm naverAlarm; // NaverAlarm 클래스의 인스턴스를 선언합니다.
  late Stream<List<DocumentSnapshot>> notificationsStream; // 알림을 스트림으로 받아오는 변수를 선언합니다.
  bool isDeleteMode = false; // 삭제 모드 활성화 변수

  @override
  void initState() {
    super.initState();
    // 현재 사용자의 이메일을 가져와서 NaverAlarm 클래스를 초기화합니다.
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    naverAlarm = NaverAlarm(currentUserEmail, () => setState(() {}));
    notificationsStream = getNotifications(); // 알림 스트림을 초기화합니다.
  }

  // 알림 목록을 스트림 형태로 불러오는 함수
  Stream<List<DocumentSnapshot>> getNotifications() {
    return FirebaseFirestore.instance
        .collection('helpActions') // Firestore에서 'helpActions' 컬렉션을 사용합니다.
        .where('owner_email', isEqualTo: naverAlarm.currentUserEmail) // ownerEmail 필드가 현재 사용자 이메일과 일치하는 문서만 가져옵니다.
        .snapshots() // 문서 변경사항을 실시간으로 스트림으로 받아옵니다.
        .map((snapshot) {
          var docs = snapshot.docs.toList();
          // 시간을 기준으로 목록을 역순 정렬
          docs.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
          return docs;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF86F03),
        title: Text('알림', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              setState(() {
                isDeleteMode = !isDeleteMode; // 삭제 모드 상태 토글
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: notificationsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('오류가 발생했습니다.'));
                }
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final notifications = snapshot.data!;

                return ListView.separated(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final DocumentSnapshot doc = notifications[index];
                    final notification = doc.data() as Map<String, dynamic>;
                    final timestamp = notification['timestamp'] as Timestamp;
                    final DateTime dateTime = timestamp.toDate();
                    final String timeAgo = getTimeAgo(dateTime);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple[300],
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification['helper_email_nickname'] ?? '알 수 없는 사용자',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '도와주기를 요청하였습니다.',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600], fontSize: 14),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '$timeAgo',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ],
                      ),
                      trailing: isDeleteMode ? IconButton(
                        icon: Icon(Icons.close, color: Colors.black),
                        onPressed: () {
                          _deleteNotification(doc.id);
                        },
                      ) : null,
                    );
                  },
                  separatorBuilder: (context, index) => Divider(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 시간을 '분 전' 형식으로 변환하는 함수
  String getTimeAgo(DateTime dateTime) {
    final Duration difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }

  // 알림을 삭제하는 함수
  void _deleteNotification(String docId) {
    FirebaseFirestore.instance
        .collection('helpActions')
        .doc(docId)
        .delete()
        .then((_) => print("Document successfully deleted"))
        .catchError((error) => print("Failed to delete document: $error"));
  }
}

