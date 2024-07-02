import 'package:OnTheWay/Alarm/Grade.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:lottie/lottie.dart';

import '../Chat/AllUsersScreen.dart';
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


    alarm = Alarm(currentUserEmail, () {
      if (mounted) {
        setState(() {});
      }
    }, context);
    notificationsStream = getNotifications(); // 알림 스트림을 초기화합니다.
  }

  @override
  void dispose() {
    // 여기에서 스트림 구독 취소 및 기타 정리 작업을 수행합니다.
    super.dispose();
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
    return WillPopScope(
      onWillPop: () async{
        return true;
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details){
          if (details.primaryVelocity! >  0){
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Lottie.asset(
                    'assets/lottie/BoardColor.json',
                    fit: BoxFit.fill,
                  ),
                ),
                AppBar(
                  backgroundColor: Colors.transparent,
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
              ],
            ),
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

                        //알림 온 시간 측정
                        final DocumentSnapshot doc = notifications[index];
                        final notification = doc.data() as Map<String, dynamic>;
                        final timestamp = notification['timestamp'] as Timestamp;
                        final DateTime dateTime = timestamp.toDate();
                        final String timeAgo = getTimeAgo(dateTime);
                        //닉네임
                        final String nickname = notification['helper_email_nickname'] ?? '알 수 없는 사용자';
                        final Color avatarColor = _getColorFromName(nickname); // 색상 결정

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: avatarColor, // 여기서 색상 적용
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Row(
                            children : [
                              Column(
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
                              Spacer(),
                              Column(
                                // crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  FutureBuilder<String>(
                                    future: getGradeByNickname(notification['helper_email_nickname']),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text('에러가 발생하였습니다.');
                                      } else if (!snapshot.hasData || snapshot.data == '정보 없음') {
                                        return Text('정보 없음', style: TextStyle(color: Colors.grey, fontSize: 5));
                                      } else {
                                        // double grade = double.parse(snapshot.data!);
                                        double gradeValue = double.parse(snapshot.data!);
                                        Grade grade = Grade(gradeValue);
                                        return
                                          isDeleteMode  ? Text('') :  Container(
                                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              // border: Border.all(color: grade.color, width: 2),
                                              border: grade.border,
                                              borderRadius: BorderRadius.circular(8),
                                              // color: Colors.black.withOpacity(0.1),
                                              color: grade.color2.withOpacity(0.05),
                                            ),
                                            child: Row(
                                                children: [
                                                  Icon(Icons.school_outlined, color: grade.color),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    grade.letter,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: grade.color,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  SizedBox(width: 7),
                                                  Column(
                                                      children : [
                                                        SizedBox(height: 12,),
                                                        Text(
                                                          gradeValue.toStringAsFixed(2),
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: grade.color,
                                                            fontSize: 8,
                                                          ),
                                                        ),
                                                      ]),
                                                ]
                                            ),
                                          );
                                      }
                                    },
                                  ),
                                ],
                              )
                            ],
                          ),
                          onTap: () {
                            _showAcceptDeclineDialog(context, nickname, doc.id);
                          },
                          trailing: isDeleteMode ? IconButton(
                            icon: Icon(Icons.close, color: Colors.black),
                            onPressed: () {
                              _deleteNotification(doc.id);
                              _deleteChatActions(doc.id);
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
        ),
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

  // 수락시 게시글 삭제
  Future<void> _deletePost(String docId) async{
    DocumentSnapshot postId = await FirebaseFirestore.instance
        .collection('helpActions')
        .doc(docId)
        .get();

    String deletePostId = postId.get('post_id');

    FirebaseFirestore.instance
        .collection('naver_posts')
        .doc(deletePostId)
        .delete()
        .then((_) => print("Document successfully deleted"))
        .catchError((error) => print("Failed to delete document: $error"));
  }


  //채팅 정보 삭제
  void _deleteChatActions(String docId) {
    FirebaseFirestore.instance
        .collection('ChatActions')
        .doc(docId)
        .delete()
        .then((_) => print("Document successfully deleted"))
        .catchError((error) => print("Failed to delete document: $error"));
  }


  Color _getColorFromName(String name) {
    final int nameLength = name.length;
    final List<Color> colors = [
      Color(0xFF80B3FF),    // 보라색
      // Color(0xFF9EDDFF),
      Color(0xFF687EFF),    // 파란색
      Color(0xFFFF8B13),    // 오렌지색
    ];

    return colors[(nameLength ) % colors.length];
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
                backgroundColor: Colors.indigo[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // 버튼 모서리 둥글게
                ),
              ),
              child: Text('수락',style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
              onPressed: () async {
                await _HelperCount(documentId);
                // 수락 로직 구현
                _respondToHelpRequest(documentId, 'accepted');
                Navigator.of(context).pop(); // 대화 상자 닫기

                Navigator.of(context).push(MaterialPageRoute(//채팅 목록창으로 이동
                  builder: (context) => AllUsersScreen(),
                ));

                // await _deletePost(documentId); // 수락시 게시글 삭제
                _deleteNotification(documentId); // 수락시 알림 내용 삭제
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
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // 버튼 모서리 둥글게
                ),
              ),
              child: Text('거절',style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
              onPressed: () {
                // 수락 로직 구현
                _respondToHelpRequest(documentId, 'rejected');
                Navigator.of(context).pop(); // 대화 상자 닫기
                _deleteNotification(documentId); // 거절시 알림 내용 삭제
                _deleteChatActions(documentId); // 거절시 채팅 정보 삭제
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

  // 수락시 상대방 및 본인 도와주기 횟수 카운트!
  Future<void> _HelperCount(String docId) async{
    try {
      DocumentSnapshot postId = await FirebaseFirestore.instance
          .collection('helpActions')
          .doc(docId)
          .get();

      if (!postId.exists) {
        print("Document does not exist.");
        return;
      }

      String helper_email = postId.get('helper_email');
      String owner_email = postId.get('owner_email');

      String helperDomain = _extractDomain(helper_email);
      String ownerDomain = _extractDomain(owner_email);

      String helperId = _extractId(helper_email);
      String ownerId = _extractId(owner_email);

      // // // 도메인별로 점수 증가
      await _updateIndividualCount(helperId, helperDomain);

      await _updateIndividualCount(ownerId, ownerDomain);



    } catch (e) {
      print("Error in _HelperCount: $e");
    }
  }

  // 도메인 추출
  String _extractDomain(String email)  {
    return email.split('@').last;
  }
  // 아이디 추출
   String _extractId(String email)  {
      return email.split('@').first;
  }

  // 도메인 별로 카운트
  Future<void> _updateIndividualCount(String Id, String domain) async {
    try {
      DocumentReference schoolRef = FirebaseFirestore.instance
          .collection('schoolScores')
          .doc(domain);

      DocumentSnapshot schoolSnapshot = await schoolRef.get();

      if (!schoolSnapshot.exists) {
        // 문서가 존재하지 않으면 새로 생성하고 초기값 설정
        await schoolRef.set({Id: 1});
      } else {
        // 문서가 존재하면 해당 이메일의 값을 업데이트
        int currentCount = (schoolSnapshot.data() as Map<String, dynamic>)[Id] ?? 0;
        await schoolRef.update({Id: currentCount + 1});
      }
    } catch (e) {
      print("Error in _updateIndividualCount: $e");
    }
  }


  //주어진 닉네임(helperEmailNickname)에서 Firestore 일치하는 계정 학점 반환
  Future<String> getGradeByNickname(String helperEmailNickname) async{
    final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

    DocumentSnapshot documentSnapshot = await usersCollection.doc(helperEmailNickname).get();

    if(documentSnapshot.exists){
      Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
      return data['grade'].toString();
    }
    else {
      return '정보 없음';
    }
  }


  void _respondToHelpRequest(String documentId, String response) async {
    await FirebaseFirestore.instance.collection('ChatActions').doc(documentId)
        .update({'response': response});
  }




}