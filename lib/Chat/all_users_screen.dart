
//이 코드는 Flutter 애플리케이션에서 모든 사용자 목록을 표시하고 해당 사용자를 선택하여
//채팅 화면으로 이동할 수 있는 화면을 구현한 것입니다.

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AllUsersScreen extends StatefulWidget {
  _AllUsersScreenState createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {

  late StreamSubscription<QuerySnapshot> _chatActionsSubscription; // Firestore 스트림 구독을 위한 변수
  List<DocumentSnapshot> acceptedChatActions = []; // 수락된 도움말 액션을 저장하는 변수




  // elif 문 만들기
  // helper_email과 owner_email 합치면 or사용 않해도 되는지 알아보ㄷ


  // @override
  // void initState() {
  //   super.initState();
  //   User? currentUser = FirebaseAuth.instance.currentUser;
  //   String? currentUserEmail = currentUser?.email;
  //
  //   if (currentUserEmail != null) {
  //     _helpActionsSubscription =
  //         FirebaseFirestore.instance // Firebase Firestore 인스턴스 생성
  //             .collection('helpActions') // 'helpActions' 컬렉션을 참조
  //             .where('response', isEqualTo: 'accepted') // 'response' 필드가 'accepted'인 문서만 가져오기
  //             .where('helper_email', isEqualTo: currentUserEmail)
  //             .where('owner_email', isEqualTo: currentUserEmail)
  //             .snapshots() // 실시간 업데이트를 감지하기 위해 스냅샷 생성
  //             .listen((data) { // 스트림을 구독하고 업데이트를 처리하는 콜백 함수
  //           setState(() {
  //             acceptedHelpActions = data.docs; // 수락된 도움말 액션 리스트 업데이트
  //           });
  //
  //         });
  //   }
  // }

  @override
  void initState() {
    super.initState();
    User? currentUser = FirebaseAuth.instance.currentUser;
    String? currentUserEmail = currentUser?.email;

    if (currentUserEmail != null) {
      _chatActionsSubscription = FirebaseFirestore.instance
          .collection('ChatActions')
          .where('response', isEqualTo: 'accepted')
          .snapshots()
          .listen((data) {
        var filteredDocs = data.docs.where((doc) {
          var docData = doc.data() as Map<String, dynamic>;
          return docData['helper_email'] == currentUserEmail ||
              docData['owner_email'] == currentUserEmail;
        }).toList();

        setState(() {
          acceptedChatActions = filteredDocs;
        });
      });
    }
  }

  @override
  void dispose() {
    _chatActionsSubscription.cancel(); // 스트림 구독 해제
    super.dispose();
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFFFF8B13),
          elevation: 0,
          title: Text("채팅",
            style: TextStyle(fontWeight: FontWeight.bold),),
          actions: <Widget>[
          ],

        ),

        body: acceptedChatActions != null
            ? Container(
          child: ListView.builder(
            itemCount: acceptedChatActions.length,
            itemBuilder: ((context, index) {
              DocumentSnapshot userDoc = acceptedChatActions[index];
              Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

              //알림 온 시간 측정
              final DocumentSnapshot doc = acceptedChatActions[index];
              final notification = doc.data() as Map<String, dynamic>;
              final timestamp = notification['timestamp'] as Timestamp;
              final DateTime dateTime = timestamp.toDate();
              final String timeAgo = getTimeAgo(dateTime);

              // 로그인한 사람 이메일 확인
              User? currentUser = FirebaseAuth.instance.currentUser;
              String? currentUserEmail = currentUser?.email;

              return Column(
                children: [
                  if (userData['helper_email'] == currentUserEmail) // 조건부로 위젯 생성
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      child: Stack(
                        children: <Widget>[
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: AssetImage('assets/ava.png'),
                              radius: 30,
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  userData['owner_email_nickname'],
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "마지막 메시지 미리보기",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              // 탭 이벤트 핸들러
                            },
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                '$timeAgo',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (userData['owner_email'] == currentUserEmail)
                    InkWell(
                      onTap: () {
                        // 탭 이벤트 핸들러
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: <Widget>[
                            ListTile(
                              leading: CircleAvatar(
                                backgroundImage: AssetImage('assets/ava.png'),
                                radius: 28,
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    userData['helper_email_nickname'],
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "마지막 메시지 미리보기",
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$timeAgo',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Divider(thickness: 1),
                ],
              );
            }),
          ),
        )
            : Center(
          child: CircularProgressIndicator(), // 로딩 중 표시
        ));
  }
}



