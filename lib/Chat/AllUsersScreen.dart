
//이 코드는 Flutter 애플리케이션에서 모든 사용자 목록을 표시하고 해당 사용자를 선택하여
//채팅 화면으로 이동할 수 있는 화면을 구현한 것입니다.

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import 'ChatScreen.dart';


class AllUsersScreen extends StatefulWidget {
  _AllUsersScreenState createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {

  late StreamSubscription<dynamic> _chatActionsSubscription; // Firestore 스트림 구독을 위한 변수
  List<DocumentSnapshot> acceptedChatActions = []; // 수락된 도움말 액션을 저장하는 변수
// 채팅방 별 마지막 메시지 시간을 저장할 변수
  Map<String, DateTime?> lastMessageTimes = {};

  @override
  void initState() {
    super.initState();
    _fetchChatActions();
    _fetchLastMessageTimes();
  }


  @override
  void dispose() {
    _chatActionsSubscription.cancel(); // 스트림 구독 해제
    super.dispose();
  }


  // 이 함수는 현재 로그인한 사용자의 채팅방 목록을 가져오고, 각 채팅방의 최신 메시지 시간에 따라 목록을 정렬합니다.
  Future<void> _fetchChatActions() async {
    // 현재 로그인한 사용자 정보를 가져옵니다.
    User? currentUser = FirebaseAuth.instance.currentUser;
    // 사용자가 로그인하지 않았거나 이메일 정보가 없다면 함수를 종료합니다.
    if (currentUser == null || currentUser.email == null) {
      return;
    }

    // 현재 사용자의 이메일 주소를 가져옵니다.
    String currentUserEmail = currentUser.email!;
    // 'helper_email' 필드가 현재 사용자의 이메일과 일치하는 'ChatActions' 컬렉션의 문서 스트림을 가져옵니다.
    var helperEmailStream = FirebaseFirestore.instance
        .collection('ChatActions')
        .where('response', isEqualTo: 'accepted')
        .where('helper_email', isEqualTo: currentUserEmail)
        .snapshots();

    // 'owner_email' 필드가 현재 사용자의 이메일과 일치하는 'ChatActions' 컬렉션의 문서 스트림을 가져옵니다.
    var ownerEmailStream = FirebaseFirestore.instance
        .collection('ChatActions')
        .where('response', isEqualTo: 'accepted')
        .where('owner_email', isEqualTo: currentUserEmail)
        .snapshots();

    // 두 스트림을 결합하여 채팅방 목록을 생성합니다.
    _chatActionsSubscription = Rx.combineLatest2(
        helperEmailStream,
        ownerEmailStream,
            (QuerySnapshot helperSnapshot, QuerySnapshot ownerSnapshot) async {
          // helperEmailStream과 ownerEmailStream에서 받은 문서들을 결합합니다.
          var combinedDocs = {...helperSnapshot.docs, ...ownerSnapshot.docs}.toList();

          // 각 채팅방의 마지막 메시지 시간을 비동기적으로 가져오는 작업 목록을 생성합니다.
          var fetchLastMessageFutures = <Future<void>>[];
          for (var doc in combinedDocs) {
            var docName = doc.id;
            fetchLastMessageFutures.add(
              fetchLastMessage(docName).then((timestamp) {
                lastMessageTimes[docName] = timestamp ?? doc.get('timestamp').toDate();
              }),
            );
          }

          // 모든 채팅방의 마지막 메시지 시간을 가져온 후에 목록을 정렬합니다.
          await Future.wait(fetchLastMessageFutures);
          combinedDocs.sort((a, b) => lastMessageTimes[b.id]!.compareTo(lastMessageTimes[a.id]!));

          // 위젯이 화면에 여전히 존재하는 경우에만 상태를 업데이트합니다.
          if (mounted) {
            setState(() {
              acceptedChatActions = combinedDocs;
            });
          }
        }
    ).listen(
          (data) {},
      onError: (error) {
        // 스트림에서 오류가 발생한 경우 로그를 출력합니다.
        print("An error occurred: $error");
      },
    );
  }


  //마지막 메시지 보낸 시간 확인
  Future<DateTime?> fetchLastMessage(String documentName) async {
    try {
      // 채팅방의 마지막 메시지를 검색하기 위한 쿼리
      QuerySnapshot<Map<String, dynamic>> lastMessageSnapshot = await FirebaseFirestore.instance
          .collection('ChatActions')
          .doc(documentName)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      // 검색된 문서가 있는지 확인하고, 있다면 마지막 메시지의 타임스탬프를 가져옴
      if (lastMessageSnapshot.docs.isNotEmpty) {
        Timestamp lastMessageTimestamp = lastMessageSnapshot.docs.first.data()['timestamp'];
        return lastMessageTimestamp.toDate();
      } else {
        // 메시지가 없을 경우 채팅방 생성 시간을 사용해야 하므로 해당 로직을 구현
        // 예시: lastMessageTimestamp = 채팅방 생성 타임스탬프;
        // 참고: 여기서 채팅방 생성 타임스탬프를 어떻게 가져올지에 대한 로직이 필요함
      }

    }
    catch (error) {
      // 에러 처리 로직
      // 예: print("Error fetching last message: $error");
    }
  }

  void _fetchLastMessageTimes() async {
    for (var doc in acceptedChatActions) {
      String documentName = doc.id;
      DateTime? lastMessageTime = await fetchLastMessage(documentName);
      if (mounted) {
        setState(() {
          lastMessageTimes[documentName] = lastMessageTime;
        });
      }
    }
  }

  // 시간을 '분 전' 형식으로 변환하는 함수
  String getTimeAgo(DateTime dateTime) {
    final Duration difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes <= 1){
      return '방금 전';
    }
    if ( 1 < difference.inMinutes  && difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    }
    else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    }
    else {
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
              final DocumentSnapshot doc = acceptedChatActions[index];

              //알림 온 시간 측정
              final String documentName = userDoc.id; // 채팅방 문서 ID
              final DateTime? lastMessageTime = lastMessageTimes[documentName];

              if (lastMessageTime == null) {
                // 마지막 메시지 시간을 아직 가져오지 않았다면, 비동기로 가져옵니다.
                fetchLastMessage(documentName).then((timestamp) {
                  if (mounted) { // 위젯이 아직 화면에 존재하는지 확인
                    setState(() {
                      lastMessageTimes[documentName] = timestamp;
                    });
                  }
                });
              }
              // 마지막 메시지 시간 또는 채팅방 생성 시간을 사용하여 시간 표시
              final DateTime dateTime = lastMessageTime ?? userData['timestamp'].toDate();
              final String timeAgo = getTimeAgo(dateTime);


              // 로그인한 사람 이메일 확인
              User? currentUser = FirebaseAuth.instance.currentUser;
              String? currentUserEmail = currentUser?.email;


              return Column(
                children: [
                  if (userData['helper_email'] == currentUserEmail) // 조건부로 위젯 생성
                    InkWell(
                      onTap: (() {
                        Navigator.push(
                            context,
                            new MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  senderName: userData['helper_email_nickname'],
                                  receiverName : userData['owner_email_nickname'],
                                  // photoUrl: userData['photoUrl'],
                                  receiverUid: userData['ownerUid'],
                                  documentName : doc.id,
                                )));
                      }),
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
                                backgroundColor: Colors.transparent,
                                backgroundImage: userData['photoUrl'] is String
                                    ? NetworkImage(userData['photoUrl'])
                                    : AssetImage('assets/ava.png') as ImageProvider<Object>,
                                radius: 30,
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    userData['owner_email_nickname'],
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
                    )
                  else if (userData['owner_email'] == currentUserEmail)
                    InkWell(
                      onTap: (() {
                        Navigator.push(
                            context,
                            new MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  senderName: userData['owner_email_nickname'],
                                  receiverName : userData['helper_email_nickname'],
                                  receiverUid: userData['helperUid'],
                                  documentName : doc.id,
                                )));
                      }),
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
                                backgroundColor: Colors.transparent,
                                backgroundImage: userData['photoUrl'] is String
                                    ? NetworkImage(userData['photoUrl'])
                                    : AssetImage('assets/ava.png') as ImageProvider<Object>,
                                radius: 30,
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