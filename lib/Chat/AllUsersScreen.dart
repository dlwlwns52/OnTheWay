
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:rxdart/rxdart.dart';

import '../Alarm/AlarmUi.dart';
import '../Board/UiBoard.dart';
import '../HanbatSchoolBoard/HanbatSchoolBoard.dart';
import '../HanbatSchoolBoard/HanbatWriteBoard.dart';
import '../Pay/PaymentScreen.dart';
import '../Profile/Profile.dart';
import '../Ranking/SchoolRanking.dart';
import 'ChatScreen.dart';
import 'FullScreenImage.dart';


class AllUsersScreen extends StatefulWidget {
  _AllUsersScreenState createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen>{

  late StreamSubscription<dynamic> _chatActionsSubscription; // Firestore 스트림 구독을 위한 변수
  List<DocumentSnapshot> acceptedChatActions = []; // 수락된 도움말 액션을 저장하는 변수
// 채팅방 별 마지막 메시지 시간을 저장할 변수
  Map<String, DateTime?> lastMessageTimes = {};
  // 각 채팅방 및 사용자별 메시지 수를 저장할 Map
  Map<String, int> messageCounts = {};
  // 스트림 구독을 저장할 변수를 선언
  late StreamSubscription<DocumentSnapshot> _messageCountSubscription;

  // 바텀 네비게이션 인덱스
  int _selectedIndex = 0; // 기본 선택된 항목을 '게시판'으로 설정
  String botton_email = ""; // 사용자의 이메일을 저장할 변수
  String botton_domain = ""; // 사용자의 도메인을 저장할 변수


  //닉네임 가져오기
  late Future<String?> _nickname;



  @override
  void initState() {
    super.initState();
    _fetchChatActions();

    final FirebaseAuth _auth = FirebaseAuth.instance;
    botton_email = _auth.currentUser?.email ?? "";
    botton_domain = botton_email.split('@').last.toLowerCase();

    //닉네임 가져옴
    _nickname = getNickname();

  }


  @override
  void dispose() {
    _chatActionsSubscription.cancel(); // 스트림 구독 해제
    _messageCountSubscription.cancel();
    super.dispose();
  }


  //앱바 알림기능
  //userStatus에서 본인 nickname 찾기
  Future<String?> getNickname() async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: botton_email)
        .get();

    if (querySnapshot.docs.isNotEmpty){
      return querySnapshot.docs.first['nickname'];
    }
    return null;
  }

  // Firestore에서 messageCount 값을 실시간으로 가져오는 메서드
  Stream<DocumentSnapshot> getMessageCountStream(String nickname) {
    return FirebaseFirestore.instance
        .collection('userStatus')
        .doc(nickname)
        .snapshots();
  }

  //userStatus messageCount 값 초기화
  Future<void> resetMessageCount(String nickname) async {
    DocumentReference docRef = FirebaseFirestore.instance.collection('userStatus').doc(nickname);

    await docRef.set({'messageCount': 0}, SetOptions(merge: true));

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
        helperEmailStream, ownerEmailStream, (QuerySnapshot helperSnapshot, QuerySnapshot ownerSnapshot) async {
          // helperEmailStream과 ownerEmailStream에서 받은 문서들을 결합합니다.
          var combinedDocs = {...helperSnapshot.docs, ...ownerSnapshot.docs}.toList();

          // 각 채팅방의 마지막 메시지 시간을 비동기적으로 가져오는 작업 목록을 생성합니다.
          var fetchLastMessageFutures = <Future<void>>[];
          for (var doc in combinedDocs) {
            Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
            _updateMessageCount(doc.id, userData);

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

  //포르필 사진 기능
  Future<String?> _getProfileImage(String email) async{
    FirebaseFirestore db = FirebaseFirestore.instance;
    QuerySnapshot nicknameSnapshot = await db
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if(nicknameSnapshot.docs.isNotEmpty){
      DocumentSnapshot document = nicknameSnapshot.docs.first;
      String? profilePhotoURL = document.get('profilePhotoURL');
      return profilePhotoURL;
    }

    else {
      print("해당 이메일을 가진 사용자가 없습니다.");
      return null;
    }
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
      }
    }
    catch (error) {
      // 에러 처리 로직
      // 예: print("Error fetching last message: $error");
    }
  }

  Future<void> _updateMessageCount(documentName, userData) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String? currentUserEmail = currentUser?.email;
    String? helperNickname = userData['helper_email_nickname'];
    String? ownerNickname = userData['owner_email_nickname'];
    String helperMessageCountKey = "$documentName-${userData['helper_email']}";
    String ownerMessageCountKey = "$documentName-${userData['owner_email']}";

    try {
      if (userData['helper_email'] == currentUserEmail) {
        _messageCountSubscription = FirebaseFirestore.instance
            .collection('ChatActions')
            .doc(documentName)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            var data = snapshot.data() as Map<String, dynamic>;
            if (this.mounted) {
              setState(() {
                messageCounts[helperMessageCountKey] = data['messageCount_$helperNickname'] ?? 0;
              });
            }
          }
        });
      } else if (userData['owner_email'] == currentUserEmail) {
        _messageCountSubscription = FirebaseFirestore.instance
            .collection('ChatActions')
            .doc(documentName)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            var data = snapshot.data() as Map<String, dynamic>;
            if (this.mounted) {
              setState(() {
                messageCounts[ownerMessageCountKey] = data['messageCount_$ownerNickname'] ?? 0;
              });
            }
          }
        });
      }
    } catch (error) {
      print("Error updating message count: $error");
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

  // helper의 isDeleted_ 활성화
  Future<void> helperDeleteChatRoom(String documentId, String helperNickname) async {
    await FirebaseFirestore.instance.collection('ChatActions').doc(documentId).update({
      'isDeleted_$helperNickname': true
    });
    await _deleteUserStatusChatRoom(documentId, helperNickname);
  }

  //owner의 isDeleted_ 활성화
  Future<void> ownerDeleteChatRoom(String documentId, String ownerNickname) async {
    await FirebaseFirestore.instance.collection('ChatActions').doc(documentId).update({
      'isDeleted_$ownerNickname' : true
    });
    await _deleteUserStatusChatRoom(documentId, ownerNickname);
  }

  //나가기를 눌렀을 때 각 닉네임을 가진 사람의 상태 정보 삭제
  Future<void> _deleteUserStatusChatRoom(String documentId, String nickname) async {
    await FirebaseFirestore.instance
        .collection('userStatus')
        .doc(nickname)
        .collection('chatRooms')
        .doc(documentId)
        .delete();
  }


// helper의 isDeleted_ 와 owner의 isDeleted_ 두 개 다 모두 활성화 시 문서 삭제
  Future<void> deleteChatRoomIfBothDeleted(String documentId, String helperNickname, String ownerNickname) async {
    // 채팅방 문서 참조
    DocumentReference chatRoomRef = FirebaseFirestore.instance.collection('ChatActions').doc(documentId);

    // 채팅방 문서 가져오기
    DocumentSnapshot chatRoomSnapshot = await chatRoomRef.get();

    if (chatRoomSnapshot.exists) {
      Map<String, dynamic> chatRoomData = chatRoomSnapshot.data() as Map<String, dynamic>;

      // 두 사용자 모두 채팅방을 삭제했는지 확인
      bool isHelperDeleted = chatRoomData['isDeleted_$helperNickname'] ?? false;
      bool isOwnerDeleted = chatRoomData['isDeleted_$ownerNickname'] ?? false;

      if (isHelperDeleted && isOwnerDeleted) {
        // 채팅방에 있는 모든 이미지 URL 가져오기
        QuerySnapshot messagesImageSnapshot = await chatRoomRef.collection('messages')
            .where('type', isEqualTo: 'image')
            .get();

        // Firebase Storage에서 이미지 삭제
        for (var doc in messagesImageSnapshot.docs) {
          var messageData = doc.data() as Map<String, dynamic>;
          var photoUrl = messageData['photoUrl'];
          if (photoUrl != null) {
            try {
              await FirebaseStorage.instance.refFromURL(photoUrl).delete();
            } catch (e) {
              print("Error deleting image from Storage: $e");
            }
          }
        }

        // 서브컬렉션의 모든 문서 삭제
        await _deleteSubCollection(chatRoomRef);

        // 두 사용자 모두 채팅방을 삭제했다면 문서 삭제
        await chatRoomRef.delete();
      }
    }
  }

// 서브컬렉션의 모든 문서를 삭제하는 메서드
  Future<void> _deleteSubCollection(DocumentReference parentDocRef) async {
    // 서브컬렉션 참조
    CollectionReference subcollectionRef = parentDocRef.collection('messages');

    // 서브컬렉션의 모든 문서 가져오기
    QuerySnapshot subcollectionSnapshot = await subcollectionRef.get();

    // 각 문서 삭제
    for (var doc in subcollectionSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  // helper 채팅방 나가기 dialog
  void helperShowExitChatRoomDialog(BuildContext context, String documentId, String ownerNickname, String helperNickname) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            '채팅방 나가기',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NanumSquareRound',
              fontWeight: FontWeight.w800,
              fontSize: 25,
            ),
          ),
          content: Text(
            '대화내용 및 채팅 목록이 모두 삭제됩니다.',
            style: TextStyle(
              fontFamily: 'NanumSquareRound',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                '나가기',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                // 여기에 '나가기' 버튼을 눌렀을 때의 로직을 구현하세요.
                helperDeleteChatRoom(documentId, helperNickname);
                deleteChatRoomIfBothDeleted(documentId, ownerNickname, helperNickname);
                Navigator.of(context).pop();
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "채팅방이 삭제되었습니다.",
                      textAlign: TextAlign.center,
                    ),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                '취소',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }



// owner 채팅방 나가기 dialog
  void ownerShowExitChatRoomDialog(BuildContext context, String documentId, String ownerNickname, String helperNickname) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Column (
                  children: [
                      Text(
                      '채팅방 나가기',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'NanumSquareRound',
                        fontWeight: FontWeight.w800,
                        fontSize: 25,
                    ),
                  ),
                    SizedBox(height: 20,)
                ]
            ,),
          content: Text(
            '대화내용 및 채팅 목록이 모두 삭제됩니다.\n',
            style: TextStyle(
              fontFamily: 'NanumSquareRound',
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                '나가기',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                // 여기에 '나가기' 버튼을 눌렀을 때의 로직을 구현하세요.
                HapticFeedback.lightImpact();
                ownerDeleteChatRoom(documentId, ownerNickname);
                deleteChatRoomIfBothDeleted(documentId, ownerNickname, helperNickname);
              Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "채팅방이 삭제되었습니다.",
                      textAlign: TextAlign.center,
                    ),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                '취소',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showNicknameConfirmationDialog(BuildContext context, String documentId, String ownerNickname, String helperNickname, bool isHelper) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 35),
              Container(
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '채팅방 나가기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1D1D1D),
                      ),

                    ),
                    SizedBox(height: 13),
                    Text(
                      '⚠️ 대화내용 및 채팅 목록이 모두 삭제됩니다.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                        height: 1.5,
                        letterSpacing: -0.2,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),
              Divider(color: Colors.grey, height: 1),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop(); // 취소 버튼 클릭 시 다이얼로그 닫기
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                      ),
                      child: Center(
                        child: Text(
                          '취소',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color(0xFF636666),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 0.5, // 구분선의 두께
                    height: 60, // 구분선의 높이
                    color: Colors.grey, // 구분선의 색상
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: ()  {
                        // '나가기' 버튼을 눌렀을 때의 로직 구현
                        HapticFeedback.lightImpact();
                        if (isHelper) {
                          helperDeleteChatRoom(documentId, helperNickname);
                        } else {
                          ownerDeleteChatRoom(documentId, ownerNickname);
                        }
                        deleteChatRoomIfBothDeleted(documentId, ownerNickname, helperNickname);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "채팅방이 삭제되었습니다.",
                              textAlign: TextAlign.center,
                            ),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                      ),
                      child: Center(
                        child: Text(
                          '나가기',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color(0xFF1D4786),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  //바텀바 구조
  Widget _buildBottomNavItem({
    required String iconPath,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: isActive ? 26 : 24,
              height: isActive ? 26 : 24,
              color: isActive ? Colors.indigo : Colors.black,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                fontSize: isActive ? 14 : 12,
                color: isActive ? Colors.indigo : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
        child: AppBar(
          title: Text(
            '채팅',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 19,
              height: 1.0,
              // letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Color(0xFF1D4786),
          elevation: 0,
          leading: SizedBox(), // 상단 왼쪽 빈 공간을 만들기 위해 빈 SizedBox를 사용
          actions: [
            Container(
              margin: EdgeInsets.only(right: 18.7), // 오른쪽 여백 설정
              child: Stack(
                alignment: Alignment.topRight,
                children: <Widget>[
                  FutureBuilder<String?>(
                    future: _nickname,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                        return IconButton(
                          icon: SvgPicture.asset(
                            'assets/pigma/notification_white.svg',
                            width: 24,
                            height: 24,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "아이디를 확인할 수 없습니다. \n다시 로그인 해주세요.",
                                  textAlign: TextAlign.center,
                                ),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        );
                      }

                      String ownerNickname = snapshot.data!;
                      return IconButton(
                        icon: SvgPicture.asset(
                          'assets/pigma/notification_white.svg',
                          width: 25,
                          height: 25,
                        ),
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await resetMessageCount(ownerNickname);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AlarmUi(),
                              //   builder: (context) => Design(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  FutureBuilder<String?>(
                    future: _nickname,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                        return Container();
                      }

                      String ownerNickname = snapshot.data!;
                      return StreamBuilder<DocumentSnapshot>(
                        stream: getMessageCountStream(ownerNickname),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return Container();
                          }
                          var data = snapshot.data!.data() as Map<String, dynamic>;
                          int messageCount = data['messageCount'] ?? 0;

                          return Positioned(
                            right: 9,
                            top: 9,
                            child: messageCount > 0
                                ? Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Text(
                                '$messageCount',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                                : Container(),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

            body: acceptedChatActions != null
                ? Container(
              padding: EdgeInsets.only(top: 10.0),
              child: ListView.builder(
                itemCount: acceptedChatActions.length,
                itemBuilder: ((context, index) {
                  DocumentSnapshot userDoc = acceptedChatActions[index];
                  Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
                  final DocumentSnapshot doc = acceptedChatActions[index];
                  final String documentName = userDoc.id; // 채팅방 문서 ID

                  // 로그인한 사람 이메일 확인
                  User? currentUser = FirebaseAuth.instance.currentUser;
                  String? currentUserEmail = currentUser?.email;


                  //알림 온 시간 측정
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


                  // 메시지 카운트 키 생성
                  String messageCountKey = "";
                  if (userData['helper_email'] == currentUserEmail) {
                    messageCountKey = "$documentName-${userData['helper_email']}";
                  }
                  else if (userData['owner_email'] == currentUserEmail) {
                    messageCountKey = "$documentName-${userData['owner_email']}";
                  }
                  // 메시지 카운트 가져오기
                  int messageCount = messageCounts[messageCountKey] ?? 0;

                 //마지막으로 온 메시지
                  String lastMessage = userData['lastMessage'] ?? "채팅방이 개설되었습니다.";


                  //나가기 버튼 사용시 상대방 대화 안보이게 하기
                  if (userData['helper_email'] == currentUserEmail && userData['isDeleted_${userData['helper_email_nickname']}'] == true) {
                    return Container(); // 또는 적절한 '삭제됨' UI를 표시
                  }
                  else if (userData['owner_email'] == currentUserEmail && userData['isDeleted_${userData['owner_email_nickname']}'] == true) {
                    return Container(); // 또는 적절한 '삭제됨' UI를 표시
                  }

                  return Column(
                   children: [

                     if (userData['helper_email'] == currentUserEmail) ...[
                       Dismissible(
                         key: Key(doc.id),
                         confirmDismiss: (direction) async {
                           // 스와이프 후 삭제 확인 대화상자 표시
                           showNicknameConfirmationDialog(context, doc.id, userData['owner_email_nickname'], userData['helper_email_nickname'], true);
                         },
                         background: Container(
                           color: Colors.red,
                           child: Align(
                             alignment: Alignment.center, // 왼쪽 정렬
                             child: Row(
                               mainAxisSize: MainAxisSize.min, // 내용물 크기에 맞게 Row 크기 조절
                               children: <Widget>[
                                 Icon(Icons.delete, color: Colors.white, size: 50), // 아이콘
                                 Text(
                                   ' 삭제', // 텍스트
                                   style: TextStyle(
                                     color: Colors.white,
                                     fontWeight: FontWeight.bold,
                                     fontSize: 20,
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         ),
                         child: FutureBuilder<String?>(
                           future:  _getProfileImage(userData['owner_email']),
                           builder: (context, snapshot) {
                             if (snapshot.connectionState == ConnectionState.waiting) {
                               return SizedBox.shrink(); // 아무것도 표시하지 않음
                             }
                             if (snapshot.hasError) {
                               return Text('Error: ${snapshot.error}'); // 오류 발생 시 표시할 위젯
                             }
                             if (!snapshot.hasData || snapshot.data == null) {
                               return Text('No data available'); // 데이터가 없을 때 표시할 위젯
                             }

                             String? profileImageUrl = snapshot.data;

                             return GestureDetector(
                               onTap: () {
                                 HapticFeedback.lightImpact();
                                 String helper_receiver = userData['helper_email_nickname'];
                                 FirebaseFirestore.instance
                                     .collection('ChatActions')
                                     .doc(doc.id)
                                     .update({'messageCount_$helper_receiver': 0});

                                 Navigator.push(
                                     context,
                                     new MaterialPageRoute(
                                         builder: (context) => ChatScreen(
                                           senderName: userData['helper_email_nickname'],
                                           receiverName : userData['owner_email_nickname'],
                                           receiverUid: userData['ownerUid'],
                                           documentName : doc.id,
                                           photoUrl : profileImageUrl,
                                         ))
                                 );
                               },
                               onLongPress: (){
                                 HapticFeedback.heavyImpact();
                                 showNicknameConfirmationDialog(context, doc.id, userData['owner_email_nickname'], userData['helper_email_nickname'], true);
                               },
                               child:
                               Container(
                                 margin: EdgeInsets.fromLTRB(20, 0, 20, 10),
                                 child: Column(
                                   mainAxisAlignment: MainAxisAlignment.start,
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Container(
                                       padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
                                       decoration: BoxDecoration(
                                         border: Border(
                                           bottom: BorderSide(
                                             color: Color(0xFFE3E3E3),
                                             width: 1,
                                           ),
                                         ),
                                       ),
                                       child: Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           Row(
                                             mainAxisAlignment: MainAxisAlignment.start,
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                                               GestureDetector(
                                                 onTap: () {
                                                   HapticFeedback.lightImpact();
                                                   if (profileImageUrl!.isNotEmpty) {
                                                     Navigator.push(
                                                       context,
                                                       MaterialPageRoute(
                                                         builder: (context) => FullScreenImage(photoUrl: profileImageUrl),
                                                       ),
                                                     );
                                                   } else {
                                                     ScaffoldMessenger.of(context).showSnackBar(
                                                       SnackBar(
                                                         content: Text(
                                                           '기본 프로필 사진입니다.',
                                                           textAlign: TextAlign.center,
                                                         ),
                                                         duration: Duration(seconds: 2),
                                                       ),
                                                     );
                                                   }
                                                 },
                                                 child: Container(
                                                   margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                                   child: Container(
                                                     decoration: BoxDecoration(
                                                       shape: BoxShape.circle,
                                                       gradient: LinearGradient(
                                                         colors: [Color(0xFF1D4786), Color(0xFF1D4786)],
                                                         begin: Alignment.topLeft,
                                                         end: Alignment.bottomRight,
                                                       ),
                                                       boxShadow: [
                                                         (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                                             ? BoxShadow(
                                                           color: Colors.black.withOpacity(0.1),
                                                           spreadRadius: 1,
                                                           blurRadius: 1,
                                                           offset: Offset(0, 1), // 그림자 위치 조정
                                                         )
                                                             : BoxShadow(),
                                                       ],
                                                     ),
                                                     child: CircleAvatar(
                                                       radius: 25,
                                                       backgroundColor: Colors.grey[200],
                                                       child: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                                           ? null
                                                           : Icon(
                                                         Icons.account_circle,
                                                         size: 50, // 원래 코드에서 width와 height가 32였으므로 여기에 맞춤
                                                         color: Color(0xFF1D4786),
                                                       ),
                                                       backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                                                           ? NetworkImage(profileImageUrl)
                                                           : null,
                                                     ),
                                                   ),
                                                 ),
                                               ),
                                               Container(
                                                 margin: EdgeInsets.fromLTRB(4, 10, 0, 10),
                                                 child: Column(
                                                   mainAxisAlignment: MainAxisAlignment.start,
                                                   crossAxisAlignment: CrossAxisAlignment.start,
                                                   children: [
                                                     Text(
                                                       userData['owner_email_nickname'],
                                                       style: TextStyle(
                                                         fontFamily: 'Pretendard',
                                                         fontWeight: FontWeight.w600,
                                                         fontSize: 17,
                                                         height: 1,
                                                         letterSpacing: -0.4,
                                                         color: Color(0xFF222222),
                                                       ),
                                                     ),
                                                     SizedBox(height: 10),
                                                     Container(
                                                       width: MediaQuery.of(context).size.width * 0.5,
                                                       child: Text(
                                                         "$lastMessage",
                                                         style: TextStyle(
                                                           fontFamily: 'Pretendard',
                                                           fontWeight: FontWeight.w400,
                                                           fontSize: 14,
                                                           height: 1,
                                                           letterSpacing: -0.4,
                                                           color: Color(0xFF767676),
                                                         ),
                                                         overflow: TextOverflow.ellipsis,
                                                         maxLines: 1,
                                                       ),
                                                     ),
                                                   ],
                                                 ),
                                               ),
                                             ],
                                           ),
                                           Container(
                                             margin: EdgeInsets.fromLTRB(0, 10, 0, 2.5),
                                             child: Column(
                                               mainAxisAlignment: MainAxisAlignment.end,
                                               crossAxisAlignment: CrossAxisAlignment.end,
                                               children: [
                                                 Container(
                                                   margin: EdgeInsets.fromLTRB(0, 0, 0, 5),
                                                   child: Text(
                                                     '$timeAgo',
                                                     style: TextStyle(
                                                       fontFamily: 'Pretendard',
                                                       fontWeight: FontWeight.w400,
                                                       fontSize: 13,
                                                       height: 1,
                                                       letterSpacing: -0.3,
                                                       color: Color(0xFF767676),
                                                     ),
                                                   ),
                                                 ),
                                                 if (messageCount == 0) ...[
                                                   Container(
                                                   ),
                                                 ]
                                                 else ...[
                                                   Container(
                                                     padding: EdgeInsets.all(8.0),  // 원형 크기 조절
                                                     decoration: BoxDecoration(
                                                       color: Color(0xFF1D4786),  // 원형 배경 색상
                                                       shape: BoxShape.circle,    // 원형 모양
                                                     ),
                                                     child: Text(
                                                       messageCount > 99 ? '99+' :'${messageCount}',
                                                       style: TextStyle(
                                                         fontFamily: 'Pretendard',
                                                         fontWeight: FontWeight.w500,
                                                         fontSize: 12,
                                                         height: 1,
                                                         letterSpacing: -0.3,
                                                         color: Color(0xFFFFFFFF),  // 텍스트 색상
                                                       ),
                                                     ),
                                                   ),
                                                 ]
                                               ],
                                             ),
                                           ),
                                         ],
                                       ),
                                     ),
                                     // 나머지 Container와 Row 등에도 동일하게 적용해주면 됩니다.
                                   ],
                                 ),
                               ),

                             );
                           },
                         ),

                       ),
                     ],




                      if (userData['owner_email'] == currentUserEmail) ...[
                        Dismissible(
                          key: Key(doc.id),
                          confirmDismiss: (direction) async {
                            // 스와이프 후 삭제 확인 대화상자 표시
                            showNicknameConfirmationDialog(context, doc.id, userData['owner_email_nickname'], userData['helper_email_nickname'], false);
                          },
                          background: Container(
                            color: Colors.red,
                            child: Align(
                              alignment: Alignment.center, // 왼쪽 정렬
                              child: Row(
                                mainAxisSize: MainAxisSize.min, // 내용물 크기에 맞게 Row 크기 조절
                                children: <Widget>[
                                  Icon(Icons.delete, color: Colors.white, size: 50), // 아이콘
                                  Text(
                                    ' 삭제', // 텍스트
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          child: FutureBuilder<String?>(
                            future:  _getProfileImage(userData['helper_email']),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return SizedBox.shrink(); // 아무것도 표시하지 않음
                              }
                              if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}'); // 오류 발생 시 표시할 위젯
                              }
                              if (!snapshot.hasData || snapshot.data == null) {
                                return Text('No data available'); // 데이터가 없을 때 표시할 위젯
                              }

                              String? profileImageUrl = snapshot.data;

                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  String owner_receiver = userData['owner_email_nickname'];
                                  FirebaseFirestore.instance
                                      .collection('ChatActions')
                                      .doc(doc.id)
                                      .update({'messageCount_$owner_receiver': 0});

                                  Navigator.push(
                                      context,
                                      new MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            senderName: userData['owner_email_nickname'],
                                            receiverName : userData['helper_email_nickname'],
                                            receiverUid: userData['helperUid'],
                                            documentName : doc.id,
                                            photoUrl : profileImageUrl,
                                          )));
                                },
                                onLongPress: (){
                                  HapticFeedback.heavyImpact();
                                  showNicknameConfirmationDialog(context, doc.id, userData['owner_email_nickname'], userData['helper_email_nickname'], false);
                                },
                                child:
                                Container(
                                  margin: EdgeInsets.fromLTRB(20, 0, 20, 10),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Color(0xFFE3E3E3),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.start,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    HapticFeedback.lightImpact();
                                                    if (profileImageUrl!.isNotEmpty) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => FullScreenImage(photoUrl: profileImageUrl),
                                                        ),
                                                      );
                                                    } else {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            '기본 프로필 사진입니다.',
                                                            textAlign: TextAlign.center,
                                                          ),
                                                          duration: Duration(seconds: 2),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: Container(
                                                    margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        gradient: LinearGradient(
                                                          colors: [Color(0xFF1D4786), Color(0xFF1D4786)],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                        boxShadow: [
                                                          (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                                              ? BoxShadow(
                                                            color: Colors.black.withOpacity(0.1),
                                                            spreadRadius: 1,
                                                            blurRadius: 1,
                                                            offset: Offset(0, 1), // 그림자 위치 조정
                                                          )
                                                              : BoxShadow(),
                                                        ],
                                                      ),
                                                      child: CircleAvatar(
                                                        radius: 25, // 반지름 설정 (32 / 2)
                                                        backgroundColor: Colors.grey[200],
                                                        child: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                                            ? null
                                                            : Icon(
                                                          Icons.account_circle,
                                                          size: 50, // 원래 코드에서 width와 height가 32였으므로 여기에 맞춤
                                                          color: Color(0xFF1D4786),
                                                        ),
                                                        backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                                                            ? NetworkImage(profileImageUrl)
                                                            : null,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                Container(
                                                  margin: EdgeInsets.fromLTRB(4, 10, 0, 10),
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        userData['helper_email_nickname'],
                                                        style: TextStyle(
                                                          fontFamily: 'Pretendard',
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 17,
                                                          height: 1,
                                                          letterSpacing: -0.4,
                                                          color: Color(0xFF222222),
                                                        ),
                                                      ),
                                                      SizedBox(height: 10),
                                                      Container(
                                                        width: MediaQuery.of(context).size.width * 0.5,
                                                        child: Text(
                                                          "$lastMessage",
                                                          style: TextStyle(
                                                            fontFamily: 'Pretendard',
                                                            fontWeight: FontWeight.w400,
                                                            fontSize: 14,
                                                            height: 1,
                                                            letterSpacing: -0.4,
                                                            color: Color(0xFF767676),
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              margin: EdgeInsets.fromLTRB(0, 10, 0, 2.5),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    margin: EdgeInsets.fromLTRB(0, 0, 0, 5),
                                                    child: Text(
                                                      '$timeAgo',
                                                      style: TextStyle(
                                                        fontFamily: 'Pretendard',
                                                        fontWeight: FontWeight.w400,
                                                        fontSize: 13,
                                                        height: 1,
                                                        letterSpacing: -0.3,
                                                        color: Color(0xFF767676),
                                                      ),
                                                    ),
                                                  ),
                                                  if (messageCount == 0) ...[
                                                    Container(
                                                    ),
                                                  ]
                                                  else ...[
                                                    Container(
                                                      padding: EdgeInsets.all(8.0),  // 원형 크기 조절
                                                      decoration: BoxDecoration(
                                                        color: Color(0xFF1D4786),  // 원형 배경 색상
                                                        shape: BoxShape.circle,    // 원형 모양
                                                      ),
                                                      child: Text(
                                                        messageCount > 99 ? '99+' :'${messageCount}',
                                                        style: TextStyle(
                                                          fontFamily: 'Pretendard',
                                                          fontWeight: FontWeight.w500,
                                                          fontSize: 12,
                                                          height: 1,
                                                          letterSpacing: -0.3,
                                                          color: Color(0xFFFFFFFF),  // 텍스트 색상
                                                        ),
                                                      ),
                                                    ),
                                                  ]
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // 나머지 Container와 Row 등에도 동일하게 적용해주면 됩니다.
                                    ],
                                  ),
                                ),

                              );
                            },
                          ),

                      ),
                      ],
                      // Divider(thickness: 1),
                    ],
                  );
                }),
              ),
            )
                : Center(
              child: CircularProgressIndicator(), // 로딩 중 표시
            ),










      bottomNavigationBar: Padding(
        padding: Platform.isAndroid ?  EdgeInsets.only(bottom: 8, top: 8): const EdgeInsets.only(bottom: 30, top: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(
                  iconPath: 'assets/pigma/chatbubbles.svg',
                  label: '채팅',
                  isActive: _selectedIndex == 0,
                  onTap: () {
                    if (_selectedIndex != 0) {
                      setState(() {
                        _selectedIndex = 0;
                      });
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AllUsersScreen()),
                      );
                    }
                  },
                ),
                _buildBottomNavItem(
                  iconPath: 'assets/pigma/footsteps.svg',
                  label: '진행상황',
                  isActive: _selectedIndex == 1,
                  onTap: () {
                    if (_selectedIndex != 1) {
                      setState(() {
                        _selectedIndex = 1;
                      });
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PaymentStatusScreen()),
                      );
                    }
                  },
                ),
                _buildBottomNavItem(
                  iconPath: 'assets/pigma/book.svg',
                  label: '게시판',
                  isActive: _selectedIndex == 2,
                  onTap: () {
                    if (_selectedIndex != 2) {
                      setState(() {
                        _selectedIndex = 2;
                      });
                      HapticFeedback.lightImpact();
                      switch (botton_domain) {
                        case 'naver.com':
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HanbatBoardPage()),
                          );
                          break;
                        default:
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => BoardPage()),
                          );
                          break;
                      }
                    }
                  },
                ),
                _buildBottomNavItem(
                  iconPath: 'assets/pigma/school.svg',
                  label: '학교랭킹',
                  isActive: _selectedIndex == 3,
                  onTap: () {
                    if (_selectedIndex != 3) {
                      setState(() {
                        _selectedIndex = 3;
                      });
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SchoolRankingScreen()),
                      );
                    }
                  },
                ),
                _buildBottomNavItem(
                  iconPath: 'assets/pigma/person.svg',
                  label: '프로필',
                  isActive: _selectedIndex == 4,
                  onTap: () {
                    if (_selectedIndex != 4) {
                      setState(() {
                        _selectedIndex = 4;
                      });
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserProfileScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

