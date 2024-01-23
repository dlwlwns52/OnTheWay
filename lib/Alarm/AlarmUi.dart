import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'Alarm.dart'; // Alarm 클래스를 가져옵니다.

class AlarmUi extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<AlarmUi> {
  late final Alarm alarm;  // NaverAlarm 클래스의 인스턴스를 선언합니다.
  late Stream<List<DocumentSnapshot>> notificationsStream; // 알림을 스트림으로 받아오는 변수를 선언합니다.
  bool isDeleteMode = false; // 삭제 모드 활성화 변수


  @override
  void initState() {
    super.initState();
    // 현재 사용자의 이메일을 가져와서 NaverAlarm 클래스를 초기화합니다.
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    alarm = Alarm(currentUserEmail, () => setState(() {}), context);
    notificationsStream = getNotifications(); // 알림 스트림을 초기화합니다.
  }

  // 알림 목록을 스트림 형태로 불러오는 함수
  Stream<List<DocumentSnapshot>> getNotifications() {
    return FirebaseFirestore.instance
        .collection('helpActions') // Firestore에서 'helpActions' 컬렉션을 사용합니다.
        .where('owner_email', isEqualTo: alarm.currentUserEmail) // ownerEmail 필드가 현재 사용자 이메일과 일치하는 문서만 가져옵니다.
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
            icon: Icon(isDeleteMode ? Icons.delete_outline : Icons.delete),
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
                    final String nickname = notification['helper_email_nickname'] ?? '알 수 없는 사용자';
                    final Color avatarColor = _getColorFromName(nickname); // 색상 결정

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: avatarColor, // 여기서 색상 적용
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
                      onTap: () {
                        _showAcceptDeclineDialog(context, nickname, doc.id);
                      },
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
    if (difference.inMinutes <= 1){
      return '방금 전';
    }
    if ( 1 < difference.inMinutes  && difference.inMinutes < 60) {
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

  //아이콘 배경 색상
  Color _getColorFromName(String name) {
    final int hash = name.hashCode;
    final List<Color> colors = [
      Color(0xFF80B3FF),    // 보라색
      Color(0xFF9EDDFF),
      // Color(0xFF687EFF),
      Colors.purple[200] ?? Colors.blue,         // 파란색
      // Colors.blue[300] ?? Colors.orange,                           // 오렌지색
    ];
    return colors[hash % colors.length]; // 해시값을 색상 배열 길이로 나눈 나머지를 인덱스로 사용
  }

  //수락 또는 거절 버튼 구현
  void _showAcceptDeclineDialog(BuildContext context, String nickname, String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder( // 대화 상자의 모서리를 둥글게 합니다.
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            '알림',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black, // 제목 색상 변경
            ),
          ),
          content: Text(
            '\'$nickname\' 님의 도와주기 요청을 수락하시겠습니까?',
            style: TextStyle(
              color: Colors.black87,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // 버튼 모서리 둥글게
                ),
              ),
              child: Text('수락',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
              onPressed: () {
                // 수락 로직 구현
                _respondToHelpRequest(documentId, 'accepted');
                Navigator.of(context).pop(); // 대화 상자 닫기
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "해당 요청이 수락되었습니다.", textAlign: TextAlign.center,),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // 버튼 모서리 둥글게
                ),
              ),
              child: Text('거절',style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
              onPressed: () {
                // 수락 로직 구현
                _respondToHelpRequest(documentId, 'rejected');
                Navigator.of(context).pop(); // 대화 상자 닫기
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "해당 요청이 거절되었습니다.", textAlign: TextAlign.center,),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }


  void _respondToHelpRequest(String documentId, String response) async {
    await FirebaseFirestore.instance.collection('helpActions').doc(documentId)
        .update({'response': response});
  }


}