import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:OnTheWay/SchoolBoard/WriteBoard.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';


import '../Map/Navigation/HelperTMapView.dart';
import '../Map/Navigation/PostDetailMapView.dart';
import '../Map/LocationTracker.dart';

import 'HelpScreenArguments.dart';
import 'SchoolBoard.dart';


class HelpScreen extends StatefulWidget {

  final HelpScreenArguments args;

  HelpScreen(this.args);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  FirebaseFirestore db = FirebaseFirestore.instance;
  User? user;

  bool _isListening = false;
  String botton_domain = ""; // 사용자의 도메인을 저장할 변수
  String collection_domain = "";

  @override
  void initState() {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    user = _auth.currentUser;
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    botton_domain = currentUserEmail.split('@').last.toLowerCase();
    collection_domain = botton_domain.replaceAll('.','_');


    super.initState();
  }

  //수정,삭제,닫기 바텀시트
  void _showEditDeleteDialog(BuildContext context, DocumentSnapshot doc) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFFFFFFFF),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 15, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(1, 0, 0, 43),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFE3E3E3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  width: 44,
                  height: 4,
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(0, 0, 0, 37),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // 수정 기능 호출
                        HapticFeedback.lightImpact();
                        buildCustomDialog(context, doc, true);

                      },
                      child: Container(
                        margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color(0xFFFFFFFF),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0A000000),
                              offset: Offset(0, 4),
                              blurRadius: 7.5,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(1, 17, 0, 17),
                        child: Center(
                          child: Text(
                            '게시글 수정',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              height: 1,
                              letterSpacing: -0.4,
                              color: Color(0xFF222222),
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // 삭제 기능 호출
                        HapticFeedback.lightImpact();
                        buildCustomDialog(context, doc, false);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color(0xFFFFFFFF),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0A000000),
                              offset: Offset(0, 4),
                              blurRadius: 7.5,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(1, 17, 0, 17),
                        child: Center(
                          child: Text(
                            '게시글 삭제',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              height: 1,
                              letterSpacing: -0.4,
                              color: Color(0xFFE32A1E),
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop(); // 취소 버튼 클릭 시 모달 닫기
                      },
                      child: Container(
                        margin: EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color(0xFFFFFFFF),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0D000000),
                              offset: Offset(0, 4),
                              blurRadius: 7.5,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(1, 17, 0, 17),
                        child: Center(
                          child: Text(
                            '취소',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              height: 1,
                              letterSpacing: -0.4,
                              color: Color(0xFF222222),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  //게시글 수정 or 삭제 다이어로그
  void buildCustomDialog(BuildContext context,DocumentSnapshot doc, bool fixTrue) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 45),
              Text(
                fixTrue ? '게시물을 수정하시겠어요?' : '게시물을 삭제하시겠어요?',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF222222),
                ),
              ),
              SizedBox(height: 40),
              Divider(color: Colors.grey, height: 1,),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
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
                    width: 1.0, // 구분선의 두께
                    height: 60, // 구분선의 높이
                    color: Colors.grey, // 구분선의 색상
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        if(fixTrue){
                          HapticFeedback.lightImpact();
                          _navigateToEditPostScreen(context, doc);
                        }
                        else{
                          HapticFeedback.lightImpact();
                          String postStore = doc['store']; // 게시물의 'store' 값을 가져옵니다.
                          String? postOwnerEmail = getUserEmail(); // 현재 로그인한 사용자의 이메일을 가져옵니다.
                          HapticFeedback.lightImpact();
                          _deletePost(doc.id, postStore, postOwnerEmail!);// '삭제' 버튼 클릭 시 게시물 삭제 메서드 실행
                          Navigator.of(context).push( // 새 화면으로 이동하는 Flutter 내비게이션 함수 호출
                            MaterialPageRoute(
                              builder: (context) => BoardPage(),
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "게시물이 삭제되었습니다.", textAlign: TextAlign.center,),
                              duration: Duration(seconds: 1),
                            ),
                          );

                        }
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                      ),
                      child: Center(
                        child: Text(
                          '확인',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color(0xFF1D4786)
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

  // 게시물 수정 화면으로 이동하는 메서드
  void _navigateToEditPostScreen(BuildContext context, DocumentSnapshot doc) {
    Navigator.of(context).push( // 새 화면으로 이동하는 Flutter 내비게이션 함수 호출
      MaterialPageRoute(
        builder: (context) => HanbatNewPostScreen(post: doc),
      ),
    ).then((_) {
      // 화면이 닫힌 후에 이 부분이 실행됩니다.
      Navigator.of(context).pop(); // 대화 상자 닫기
    });
  }

  //게시물 삭제 메서드
  void _deletePost(String docId, String postStore, String postOwnerEmail) async {
    try {
      // 'UserHelpStatus' 컬렉션에서 문서 이름 생성
      String documentName = createDocumentName(postStore, postOwnerEmail);

      // 'UserHelpStatus' 컬렉션에서 해당 문서 삭제
      await FirebaseFirestore.instance.collection('UserHelpStatus').doc(documentName).delete();

      // 게시물 삭제
      await FirebaseFirestore.instance.collection(collection_domain).doc(docId).delete();

    } catch (e) {
      print('게시물 삭제 중 오류 발생: $e');
      // 오류 발생시 UI 로직 추가...
    }
  }



  String? getUserEmail() {
    // 현재 로그인한 사용자의 이메일 반환하는 메서드 정의
    final user = FirebaseAuth.instance.currentUser; // 현재 로그인한 사용자 정보 가져오기
    return user?.email; // 사용자의 이메일 반환기
  }


  //도와주기 신청 확정하는 다이어로그
  void buildCustomHelpDialog (BuildContext context,DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 45),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '도와주기 신청을 보내시겠습니까? \n상대방이 동의하면 거래가 매칭됩니다!',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF222222),
                      ),
                    ),
                    TextSpan(
                      text: '\n\n⚠️ 거래 매칭 시, 안전한 거래를 위해 일시적으로 \n위치 정보가 공유되며 결제 요청 시 자동 삭제됩니다.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.normal, // 작은 글씨는 일반적인 가중치로 설정
                        fontSize: 12, // 작은 글씨 크기 설정
                        color: Colors.grey, // 회색으로 설정
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              Divider(color: Colors.grey, height: 1,),
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
                    width: 1.0, // 구분선의 두께
                    height: 60, // 구분선의 높이
                    color: Colors.grey, // 구분선의 색상
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        helpPost(context, widget.args.doc, widget.args.pushHelpButton);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                      ),
                      child: Center(
                        child: Text(
                          '확인',
                          style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1D4786)
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

  //위치 추적시 response와 ownerClick 값 추적
  Future<void> listenToResponseChanges(String documentName, LocationTracker locationTracker) async {
    if (_isListening) {
      print("이미 리스너가 등록되었습니다.");
      return; // 리스너가 이미 등록된 경우 중복 등록 방지
    }

    _isListening = true; // 리스너 등록 상태로 변경
    FirebaseFirestore.instance
        .collection('ChatActions')
        .doc(documentName)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final response = data['response'];
        final ownerClick = data['ownerClick'];
        bool success = data['success_trade'];
        if (response == 'accepted' && ownerClick == true && success == false ) {
          print('위치 시작');
          locationTracker.startTracking();
        }

        else { // 우선 임시로 취소
          print('위치 취소');
          locationTracker.stopTracking();
        }

      }
    });
  }


  void helpPost(BuildContext context, DocumentSnapshot doc, Function(bool) _pushHelpButton) async {
    try {
// 현재 로그인된 사용자 가져오기
      User? currentUser = FirebaseAuth.instance.currentUser;

// 로그인하지 않은 경우 오류 메시지 표시 후 함수 종료
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("로그인이 필요합니다.", textAlign: TextAlign.center,),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

// 도와주는 사용자의 이메일 가져오기
      String? helperEmail = getUserEmail();

// 게시물 정보 가져오기
      String postOwnerEmail = doc['email']; // 게시물 작성자의 이메일
      String postStore = doc['store']; // 게시물의 'store' 필드
      String cost = doc['cost']; // 게시물의 가격
      String ownerLocation = doc['my_location']; // 오너(오더)의 위치


// 도와주기 상태 가져오기
      Map<String, dynamic> helpStatus = await getUserHelpClickStatus(postStore, postOwnerEmail);

// 클릭 상태 확인
      var postStatus = helpStatus[helperEmail] ?? {'clickCount': 0, 'lastClickedTime': DateTime(1970)};
      int clickCount = postStatus['clickCount']; // 클릭 횟수 가져오기

// 마지막 클릭 시간 가져오기
      DateTime lastClickedTime;
      if (postStatus['lastClickedTime'] is Timestamp) {
        lastClickedTime = (postStatus['lastClickedTime'] as Timestamp).toDate();
      } else {
        lastClickedTime = postStatus['lastClickedTime'] ?? DateTime(1970);
      }

// 도와주는 사람과 게시물 작성자의 UID 가져오기(Chat 에서 사용)
      String helperUid = '';
      String ownerUid = '';

// 헬퍼 은행명 및 계좌번호
      String helperBank = '';
      String helperAccount = '';

// 현재 시간을 가져옵니다.
      DateTime now = DateTime.now();
      String timestamp = (now.millisecondsSinceEpoch / 1000).round().toString();
      String documentName = "${postStore}_${helperEmail}_$timestamp";


// 만약 사용자가 이미 2번 이상 '도와주기'를 요청했다면, 경고 메시지를 표시하고 함수를 종료합니다.!!!!!!!!!!!!!!!!!!
      if (clickCount >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("도와주기 요청은 최대 2회까지 가능합니다.", textAlign: TextAlign.center,),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

// 만약 마지막 '도와주기' 요청 이후 30초가 지나지 않았다면, 경고 메시지를 표시하고 함수를 종료합니다. !!!!!!!!!!!!!!!!!!
      if (now.difference(lastClickedTime).inSeconds < 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("이미 '도와주기' 요청 완료했습니다.\n다시 한 번 시도하시려면 30초 후에 다시 시도해주세요.", textAlign: TextAlign.center,),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }


      // 도와주기 버튼 누른 사람 닉네임 users 컬렉션에서 조회한 후 변수에 저ㄹ장!
      // Firestore의 'users' 컬렉션에서 helperEmail에 해당하는 사용자 문서를 조회합니다.
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final helpUserDoc = await usersCollection.where('email', isEqualTo: helperEmail).get(); // 도와주기 요청한 사람 이메일
      final ownerUserDoc = await usersCollection.where('email', isEqualTo: postOwnerEmail).get();

      // 사용자 문서가 존재하면 닉네임을 가져옵니다.
      String helperNickname = '';
      if (helpUserDoc.docs.isNotEmpty) {
        // 닉네임을 가져옵니다.
        helperNickname = helpUserDoc.docs.first.data()['nickname'];
        // UID를 가져옵니다.
        helperUid = helpUserDoc.docs.first.data()['uid'];
        // 은행명
        helperBank = helpUserDoc.docs.first.data()['bank'];
        // 계좌번호
        helperAccount = helpUserDoc.docs.first.data()['accountNumber'];



      } else {
        // 사용자 문서가 없다면 에러 처리를 합니다.
        // 예를 들어, 로그를 남기거나 사용자에게 피드백을 줄 수 있습니다.
        print('User document not found for email: $helperEmail');
        return;
      }

      String OwnerNickname = '';
      if (ownerUserDoc.docs.isNotEmpty){
        OwnerNickname = ownerUserDoc.docs.first.data()['nickname'];
        ownerUid = ownerUserDoc.docs.first.data()['uid']; // UID 저장

      } else {
        // 사용자 문서가 없다면 에러 처리를 합니다.
        // 예를 들어, 로그를 남기거나 사용자에게 피드백을 줄 수 있습니다.
        print('User document not found for email: $helperEmail');
        return;
      }

      // 위치 추적 서비스 인스턴스 생성
      LocationTracker locationTracker = LocationTracker(documentName);

      bool hasPermission = await locationTracker.requestPermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("위치 권한이 허락되어야 거래를 진행할 수 있습니다.", textAlign: TextAlign.center,),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      // LocationTracker클래스를 활용해 'ChatActions' 컬렉션에 리스너 추가하여 response, ownerClick 변경 감지
      await listenToResponseChanges(documentName, locationTracker);



      updateHelpClickStatus(postStore, postOwnerEmail, helperEmail!);


      // Firestore에 '도와주기' 액션을 기록하면서 문서 이름을 설정합니다.
      await FirebaseFirestore.instance.collection('helpActions').doc(documentName).set({
        'University' : "naver",
        'post_store' : postStore,
        'post_id': doc.id,
        'owner_email_nickname' : OwnerNickname,
        'helper_email': helperEmail,
        'helper_email_nickname' : helperNickname,
        'owner_email': postOwnerEmail,
        'timestamp': now,
        'touch' : false,
        'response': null,
        'orderer_location' : ownerLocation,
        'cost' : cost,
        'request' : widget.args.request,
      });


      await _alarmMessageCount(OwnerNickname);

      // 대화상자를 닫고 스낵바 표시
      Navigator.of(context).pop();
      Navigator.of(context).pop();

      // 성공 메시지 표시
      await ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("'도와주기'요청이 전송됐습니다.",textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );

      // _pushHelpButton(true);
      // await Future.delayed(Duration(milliseconds: 1200));
      // _pushHelpButton(false);


      // 'ChatActions' 컬렉션에 채팅 관련 정보를 저장합니다.
      await FirebaseFirestore.instance.collection('ChatActions').doc(documentName).set({
        'University' : "naver",
        'post_store' : postStore,
        'post_id': doc.id,
        'owner_email': postOwnerEmail,
        'owner_email_nickname' : OwnerNickname,
        'ownerUid': ownerUid, // 게시물 작성자의 UID
        'helper_email': helperEmail,
        'helper_email_nickname' : helperNickname,
        'helperUid': helperUid, // 도와주는 사람의 UID
        'timestamp': now,
        'currentLocation': doc['current_location'],
        'storeLocation': doc['store_location'],
        'response': null,
        'success_trade' : false,
      });

      // 'Payments' 컬렉션에 결제 관련 정보를 저장합니다.
      await FirebaseFirestore.instance.collection('Payments').doc(documentName).set({
        'University' : "naver",
        'post_store' : postStore,
        'orderer_location' : ownerLocation,
        'owner_email': postOwnerEmail,
        'owner_email_nickname' : OwnerNickname,
        'ownerUid': ownerUid, // 게시물 작성자의 UID
        'helper_email': helperEmail,
        'helper_email_nickname' : helperNickname,
        'helperUid': helperUid, // 도와주는 사람의 UID
        'cost' : cost,
        'docName' : documentName,
        'timestamp': now,
        'response': null,
        'helperBank' : helperBank,
        'helperAccount' : helperAccount,
      });


      _pushHelpButton(true);
      await Future.delayed(Duration(seconds: 2));
      _pushHelpButton(false);

    } catch (e) {
      // 오류 메시지 표시
      // 대화상자를 닫고 스낵바 표시
      Navigator.of(context).pop();
      await ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("도와주기'요청이 전송이 실패하였습니다: $e",textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      ).closed;
    }
  }

// 'UserHelpStatus' 컬렉션에서 특정 문서를 조회하는 메서드입니다.
// 조회에 성공하면 문서의 데이터를 Map 형태로 반환하고, 없으면 빈 Map을 반환합니다.
  Future<Map<String, dynamic>> getUserHelpClickStatus(String postStore, String? postOwnerEmail) async {
    String documentName = createDocumentName(postStore, postOwnerEmail);
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('UserHelpStatus').doc(documentName).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    }
    return {};
  }

// 'UserHelpStatus' 컬렉션에 사용자의 '도와주기' 상태를 업데이트하는 함수
  void updateHelpClickStatus(String postStore, String postOwnerEmail, String helperEmail) {
    // 문서 이름은 게시물을 올린 사용자의 이메일과 스토어 이름을 결합하여 생성합니다.
    String documentName = createDocumentName(postStore, postOwnerEmail);

    // 문서에 '도와주기'를 누른 사용자의 이메일을 키로 하여 클릭 카운트와 마지막 클릭 시간을 저장합니다.
    FirebaseFirestore.instance.collection('UserHelpStatus').doc(documentName).set({
      helperEmail: { // 키
        'clickCount': FieldValue.increment(1),
        'lastClickedTime': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));
  }


  String createDocumentName(String postStore, String? postOwnerEmail) {
    return "${postStore}_${postOwnerEmail}";
  }


// 알람 표시 카운트
//   void _alarmMessageCount(String documentName, String ownerName) async {
//     DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(
//         'helpActions').doc(documentName).get();
//     // 해당 채팅방의 messages 서브컬렉션 참조
//
//     // 상대방이 채팅방에 없는 경우 messageCount 증가
//     int messageCount = userDoc['messageCount_${ownerName}'] ?? 0;
//     await userMessageCount.update(
//         {'messageCount_${ownerName}': messageCount + 1});
//   }

  Future<void> _alarmMessageCount(String ownerNickname) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // helpActions 컬렉션의 해당 문서 참조
    DocumentReference docRef = firestore.collection('userStatus').doc(ownerNickname);

    // 문서 가져오기
    DocumentSnapshot userDoc = await docRef.get();

    // messageCount 필드 값 가져오기 (문서가 없거나 필드가 없을 경우 기본값 0)
    int messageCount = 0;
    if (userDoc.exists && userDoc.data() != null) {
      var data = userDoc.data() as Map<String, dynamic>;
      if(data.containsKey('messageCount')) {
        messageCount = data['messageCount'];
      }
    }
    // messageCount 증가
    messageCount += 1;

    // messageCount 필드 업데이트 (문서가 없을 경우 생성, 있을 경우 업데이트)
    await docRef.set(
      {'messageCount': messageCount},
      SetOptions(merge: true),
    );
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
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              }
            },
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
                child: AppBar(
                  title: Text(
                    '게시글 상세',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 19,
                      height: 1.0,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),

                  centerTitle: true,
                  backgroundColor: Color(0xFF1D4786),
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_outlined), // '<' 모양의 뒤로가기 버튼 아이콘
                    color: Colors.white, // 아이콘 색상
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context); // 뒤로가기 기능
                    },
                  ),
                  // 상단 왼쪽 빈 공간을 만들기 위해 빈 SizedBox를 사용
                  actions: [
                    if(widget.args.isMyPost)
                      Container(
                        margin: EdgeInsets.only(right: 9), // 오른쪽 여백 설정
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent, // 터치 가능한 영역을 넓히도록 설정
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _showEditDeleteDialog(context, widget.args.doc);
                            // _showEditDeleteDialog(context, widget.args.doc);
                          },
                          child: SizedBox(
                            width: 46, // 원하는 터치 영역의 너비
                            height: 46, // 원하는 터치 영역의 높이
                            child: Align(
                              alignment: Alignment.center, // 아이콘을 중앙에 배치
                              child: SvgPicture.asset(
                                'assets/pigma/ellipsis_white.svg',
                                width: 26, // 아이콘 너비
                                height: 26, // 아이콘 높이
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),


              body: SingleChildScrollView( // 내용이 화면을 넘어갈 때 스크롤할 수 있도록 함
                child: Column(
                  children: [
                    SizedBox(height: 20,),
                    Container(
                      margin: EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.fromLTRB(0, 0, 7, 0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFF1D4786), Color(0xFF1D4786)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      (widget.args.profileImageUrl != null && widget.args.profileImageUrl.isNotEmpty)
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
                                    radius: 16, // 반지름 설정 (32 / 2)
                                    backgroundColor: Colors.grey[200],
                                    child: (widget.args.profileImageUrl != null && widget.args.profileImageUrl.isNotEmpty)
                                        ? null
                                        : Icon(
                                      Icons.account_circle,
                                      size: 32, // 원래 코드에서 width와 height가 32였으므로 여기에 맞춤
                                      color: Color(0xFF1D4786),
                                    ),
                                    backgroundImage: widget.args.profileImageUrl != null && widget.args.profileImageUrl.isNotEmpty
                                        ? NetworkImage(widget.args.profileImageUrl)
                                        : null,
                                  ),
                                ),
                              ),

                              Container(
                                margin: EdgeInsets.fromLTRB(0, 8, 0, 8),
                                child: Text(
                                  '${widget.args.userName}',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    height: 1,
                                    letterSpacing: -0.4,
                                    color: Color(0xFF222222),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            margin: EdgeInsets.fromLTRB(0, 10, 0, 9),
                            child: Text(
                              '${widget.args.timeAgo}',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                height: 1,
                                letterSpacing: -0.3,
                                color: Color(0xFFAAAAAA),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(20, 0, 20, 16),
                      width: double.infinity,
                      height: 2,
                      child:
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF6F6F6),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //픽업 장소
                          Container(
                            margin: EdgeInsets.fromLTRB(0, 0, 0, 13),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 0, 6, 0),
                                      width: 24,
                                      height: 24,
                                      child:
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: SvgPicture.asset(
                                          'assets/pigma/vuesaxbulkhouse.svg',
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                                      child: Text(
                                        '픽업 장소',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          height: 1,
                                          letterSpacing: -0.4,
                                          color: Color(0xFF767676),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                                  child: Text(
                                    '${widget.args.storeName}',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      height: 1,
                                      letterSpacing: -0.4,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),


                          //드랍 장소
                          Container(
                            margin: EdgeInsets.fromLTRB(0, 0, 0, 13),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 0, 6, 0),
                                      width: 24,
                                      height: 24,
                                      child:
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: SvgPicture.asset(
                                          'assets/pigma/location.svg',
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                                      child: Text(
                                        '드랍 장소',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          height: 1,
                                          letterSpacing: -0.4,
                                          color: Color(0xFF767676),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                                  child: Text(
                                    '${widget.args.location}',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      height: 1,
                                      letterSpacing: -0.4,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          //비용
                          Container(
                            margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 0, 6, 0),
                                      width: 24,
                                      height: 24,
                                      child:
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: SvgPicture.asset(
                                          'assets/pigma/dollar_circle.svg',
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                                      child: Text(
                                        '헬퍼비',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          height: 1,
                                          letterSpacing: -0.4,
                                          color: Color(0xFF767676),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                                  child: Text(
                                    '${widget.args.cost}',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      height: 1,
                                      letterSpacing: -0.4,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),


                    Container(
                      margin: EdgeInsets.fromLTRB(20, 0, 20, 16),
                      width: double.infinity,
                      height: 2,
                      child:
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF6F6F6),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 0, 61),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      '요청사항',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        height: 1,
                                        letterSpacing: -0.4,
                                        color: Color(0xFF222222),
                                      ),
                                    ),
                                  ),
                                ),

                                Container(
                                  width: MediaQuery.of(context).size.width*0.9,
                                  // height: MediaQuery.of(context).size.width*0.2,
                                  padding: EdgeInsets.fromLTRB(15, 25, 27.3, 25),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Color(0xFFD0D0D0)),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Color(0xFFFFFFFF),
                                  ),
                                  child: Container(
                                    child:
                                    Text(
                                      '${widget.args.request}',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        height: 1.4,
                                        letterSpacing: -0.4,
                                        color: Color(0xFF222222),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                            width: double.infinity,
                            height: 10,
                            child:
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFF6F6F6),
                              ),
                              child: Container(
                                width: 375,
                                height: 10,
                              ),
                            ),
                          ),
                          Container(   //지도넣기
                            margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      '위치',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        height: 1,
                                        letterSpacing: -0.4,
                                        color: Color(0xFF222222),
                                      ),
                                    ),
                                  ),
                                ),

                                Platform.isAndroid ? Container(
                                  child: Text('⚠️거래 매칭 시, 안전한 거래를 위해 거래 기간 동안 사용자의 위치 정보가 백그라운드에서 일시적으로 활용될 수 있습니다. 위치 정보는 거래가 완료되거나 앱이 종료될 시 자동으로 삭제됩니다!\n',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.normal, // 작은 글씨는 일반적인 가중치로 설정
                                      fontSize: 12, // 작은 글씨 크기 설정
                                      color: Colors.grey, // 회색으로 설정
                                    ),),
                                ): Container(),

                                Listener(
                                  // behavior: HitTestBehavior.translucent,  // 이 속성을 추가합니다.
                                  onPointerDown: (_) {
                                    HapticFeedback.lightImpact();
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => HelperTMapView(
                                        currentLocation: widget.args.current_location,
                                        storeLocation: widget.args.store_location,
                                      ),
                                    ));
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: MediaQuery.of(context).size.height * 0.3,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: PostDetailMapView(
                                        currentLocation: widget.args.current_location,
                                        storeLocation: widget.args.store_location,
                                      ),
                                    ),
                                  ),
                                ),



                              ],
                            ),
                          ),


                        ],
                      ),
                    ),

                    // 여기에 추가 컨텐츠를 넣을 수 있습니다.
                  ],
                ),
              ),


              bottomNavigationBar:
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if(!widget.args.isMyPost)
                    Container(
                      height: Platform.isAndroid ? MediaQuery.of(context).size.width * 0.15 : MediaQuery.of(context).size.width * 0.20,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // helpPost(context, widget.args.doc, widget.args.pushHelpButton); // 도와주기 기능 실행
                          buildCustomHelpDialog(context, widget.args.doc);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1D4786), // 배경색
                          foregroundColor: Colors.white, // 텍스트 색상
                          padding: EdgeInsets.symmetric(vertical: 13), // 내부 패딩 (높이 조정)
                          minimumSize: Size(double.infinity, kBottomNavigationBarHeight), // 버튼 크기 설정
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero, // 둥근 모서리를 제거하고 직사각형 모양으로 설정
                            side: BorderSide(color: Color(0xFF1D4786)), // 테두리 색상 설정
                          ),
                        ),
                        child: Text(
                          '도와주기',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            height: 1,
                            letterSpacing: -0.5,
                            color: Colors.white, // 텍스트 색상
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
        )
    );
  }


}











