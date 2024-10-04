import 'dart:async';

import 'package:OnTheWay/Chat/AllUsersScreen.dart';
import 'package:OnTheWay/login/PasswordFind.dart';
import 'package:OnTheWay/test/Design.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // 플러터의 머티리얼 디자인 위젯을 사용하기 위한 임포트입니다.
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 데이터베이스를 사용하기 위한 임포트입니다.
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app_badge/flutter_app_badge.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/date_symbol_data_file.dart';
import '../Alarm/AlarmUi.dart';


import '../Progress/HandoverCompletedScreen.dart';
import '../Progress/PaymentScreen.dart';
import '../Profile/Profile.dart';
import '../Ranking/DepartmentRanking.dart';
import 'ReportUserService.dart';
import 'WriteBoard.dart';
import 'HelpScreen.dart';
import '../Alarm/Alarm.dart';
import 'dart:io' show Platform;
import 'package:lottie/lottie.dart';

import 'HelpScreenArguments.dart';

// BoardPage 클래스는 게시판 화면의 상태를 관리하는 StatefulWidget 입니다.
class BoardPage extends StatefulWidget {
  @override
  _BoardPageState createState() => _BoardPageState(); // 상태(State) 객체를 생성합니다.
}

// _BoardPageState 클래스는 BoardPage의 상태를 관리합니다.
class _BoardPageState extends State<BoardPage> {
  // Firestore 인스턴스를 생성하여 데이터베이스에 접근할 수락 있게 합니다.
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  // PostManager 인스턴스 생성
  // final helpManager = HelpScreen();

  // NaverAlarm 인스턴스를 생성합니다.
  late Alarm alarm;

  // 도와주기시 애니메이션 클릭
  bool _pushHelp = false;

  // 바텀 네비게이션 인덱스
  int _selectedIndex = 2; // 기본 선택된 항목을 '게시판'으로 설정
  String botton_email = ""; // 사용자의 이메일을 저장할 변수
  String botton_domain = ""; // 사용자의 도메인을 저장할 변수
  String collection_domain = "";
  //닉네임 가져오기
  late Future<String?> _nickname;

  //프로필 사진 유저정도
  User? user;
  Map<String, Future<String?>> _profilePhotoUrls = {};

  // 초기 게시글 개수를 0으로 설정
  int postCount = 0;





  @override
  void initState() {
    super.initState();
    alarm = Alarm(FirebaseAuth.instance.currentUser?.email ?? '', () => setState(() {}), context,);

    FlutterAppBadge.count(0); // 실질적으로 배지 0 설정
    badge_zero(); // 배지 파이어스토어 0으로 업데이트


    // 로그인 시 설정된 이메일 및 도메인 가져오기 -> 바텀 네비게이션 이용시 사용
    final FirebaseAuth _auth = FirebaseAuth.instance;
    botton_email = _auth.currentUser?.email ?? "";
    botton_domain = botton_email.split('@').last.toLowerCase();
    collection_domain = botton_domain.replaceAll('.','_');



    //닉네임 가져옴
    _nickname = getNickname(botton_email);


    // 각 이메일에 대해 프로필 사진 URL을 미리 로드 (학교 바뀌면 컬렉션 변환)
    FirebaseFirestore.instance.collection(collection_domain).get().then((snapshot) {
      for (var doc in snapshot.docs) {
        final email = doc['email'];
        _profilePhotoUrls[email] = _getProfileImage(email);
      }
      setState(() {}); // 상태를 갱신하여 FutureBuilder가 다시 빌드되도록 함
    });



    // _loadPostCount(); // 위젯 초기화 시 게시글 개수를 로드
  }

  Future<void> badge_zero() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    User? user = FirebaseAuth.instance.currentUser;
    String? email = user?.email;
    if(email != null){
      QuerySnapshot querySnapshot = await firestore.collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = querySnapshot.docs.first;

        await firestore.collection('users').doc(userDoc.id).update({'badgeCount': 0});

      }
    }
  }

  void _pushHelpButton(bool value) {
    setState(() {
      _pushHelp = value;
    });
  }
  Stream<List<DocumentSnapshot>> getPosts() async* {
    String? helperUserNickName = await getNickname(botton_email);
    // 현재 사용자가 차단한 사람들의 이메일 목록을 가져옵니다.
    QuerySnapshot blockedSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(helperUserNickName) // 현재 사용자 UID
        .collection('blacklist')
        .get();

    // 차단된 사용자의 이메일을 리스트로 변환
    List blockedEmails = blockedSnapshot.docs.map((doc) {
      return doc['blockedEmail']; // 각 차단된 사용자의 이메일
    }).toList();

    // 차단된 사용자의 게시물을 제외하고 스트림으로 반환
    yield* FirebaseFirestore.instance.collection(collection_domain).snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String postEmail = data['email'];

        // 차단된 사용자의 이메일이 아니면 게시물을 반환
        return !blockedEmails.contains(postEmail);
      }).toList();
    });
  }



  // 현재 로그인한 사용자의 이메일을 반환하는 메서드
  String? currentUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email;
  }

  //ios, 안드로이드 기기 텍스트 크기 다르게 하기
  double getTextSize(bool isMyPost) {
    if (Platform.isIOS) { // ios
      return isMyPost ? 18 : 18;
    } else if (Platform.isAndroid) { // Android
      return isMyPost ? 16 : 16;
    } else {
      return isMyPost ? 16 : 16; // 기본 텍스트 크기
    }
  }

  //랭킹 페이지로 이동시 아이디 확인 안되면 새엇ㅇ
  void showCustomSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "아이디를 확인할 수 없습니다. \n다시 로그인 해주세요.",
          textAlign: TextAlign.center,
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  //본인 nickname 찾기
  Future<String?> getNickname(String email) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
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


  //프로필 사진 링크 가져오기
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

  String formatTimeAgo(Timestamp timestamp) {
    // Timestamp를 DateTime으로 변환
    DateTime dateTime = timestamp.toDate();
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes <= 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }


  //게시판 제목 (대학 추가시 추가)
  String getTitle(String domain){
    switch (domain) {
      case 'naver.com':
        return '네이버대학교 게시판';
      case 'g.cnu.ac.kr':
        return '충남대학교 게시판';
      case 'edu.hanbat.ac.kr':
        return '다음 게시판';
      default:
        return '기본 타이틀'; // 기본값 설정
    }
  }


  Future<void> blockUser(String targetUserEmail) async {

    String? helperUserNickName = await getNickname(botton_email);
    String? targetUserNickName =  await getNickname(targetUserEmail);

    // 현재 사용자의 blacklist에 차단할 사용자를 추가
    await firestore.collection('users')
        .doc(helperUserNickName)
        .collection('blacklist')
        .doc(targetUserNickName)
        .set({
      'blockedEmail': targetUserEmail,
      'blockedNickname' : targetUserNickName,
      'timestamp': FieldValue.serverTimestamp(),
      'target' : true,
    });

    // 차단된 사용자의 blacklist에도 현재 사용자를 추가 (양방향 차단)
    await firestore.collection('users')
        .doc(targetUserNickName)
        .collection('blacklist')
        .doc(helperUserNickName)
        .set({
      'blockedEmail': botton_email,
      'blockerNickname' : helperUserNickName,
      'timestamp': FieldValue.serverTimestamp(),
      'target' : false,
    });
  }


  //게시글 내용
  Widget _buildPostCard({
    required String userName,
    required String timeAgo,
    required String location,
    required String cost,
    required String storeName,
    required String email,
    required bool isMyPost,
    required String profileImageUrl,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFD0D0D0)),
        borderRadius: BorderRadius.circular(12),
        color: Color(0xFFFFFFFF),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(15, 15, 15, 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Row(
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
                            radius: 19, // 반지름 설정 (32 / 2)
                            backgroundColor: Colors.grey[200],
                            child: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                ? null
                                : Icon(
                              Icons.account_circle,
                              size: 38, // 원래 코드에서 width와 height가 32였으므로 여기에 맞춤
                              color: Color(0xFF1D4786),
                            ),
                            backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : null,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.fromLTRB(0, 0, 0, 5),
                            child: Text(
                              isMyPost ? '${userName} - 내 게시글' : userName,
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                height: 1,
                                letterSpacing: -0.5,
                                color: isMyPost ? Color(0xFF1D4786) : Color(0xFF222222),
                              ),
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              fontFamily: 'Pretendard', // Pretendard 폰트 지정
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              height: 1,
                              letterSpacing: -0.5,
                              color: Color(0xFFAAAAAA),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  isMyPost
                      ? Container()
                      : Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
                                child: GestureDetector(
                                  child: SvgPicture.asset(
                                    'assets/pigma/more_vert_AAAAAA.svg',
                                    width: 24,
                                    height: 24,
                                  ),
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _blockAndReportUserDialog(context, email);
                                  },
                                ),
                              ),
                            ],
                          ),
                      )
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              width: MediaQuery.of(context).size.width * 0.8,
              height: 1,
              color: Color(0xFFF6F6F6),
            ),
            _buildInfoRow(
              iconPath: 'assets/pigma/vuesaxbulkhouse.svg',
              label: '픽업 장소',
              value: storeName,
            ),
            _buildInfoRow(
              iconPath: 'assets/pigma/location.svg',
              label: '드랍 장소',
              value: location,
            ),
            _buildInfoRow(
              iconPath: 'assets/pigma/dollar_circle.svg',
              label: '헬퍼비',
              value: cost,
            ),
          ],
        ),
      ),
    );
  }


  //게시글 구조
  Widget _buildInfoRow({
    required String iconPath,
    required String label,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
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
                child: SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                child: Text(
                  label,
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
              value,
              style:TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1,
                letterSpacing: -0.1,
                color: Color(0xFF222222),
              ),
            ),
          ),
        ],
      ),
    );
  }



  //바텀바
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



  //사용자 차단 다이어로그
  void blockUserDialog(BuildContext context, String targetEmail) {
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
              Container(
                margin:  EdgeInsets.fromLTRB(
                    MediaQuery.of(context).size.width *0.05,
                    0,
                    MediaQuery.of(context).size.width *0.05,
                    0),
              child:
              RichText(
                textAlign: TextAlign.center,
                  text: TextSpan(
                      children: [
                        TextSpan(
                          text: '사용자 차단\n\n',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            height: 1,
                            letterSpacing: -0.4,
                            color: Colors.black,
                          ),

                        ),
                        TextSpan(
                          text: '사용자를 차단하면 해당 사용자의 게시글과 본인의 게시글이 서로 보이지 않게 됩니다. \n차단 여부는 상대방이 알 수 없으며, 프로필에서 언제든 차단을 해제할 수 있습니다.',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            height: 1,
                            letterSpacing: -0.4,
                            color: Colors.black,
                          ),
                        )
                      ])

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
                          blockUser(targetEmail);
                          // 상태 변경

                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(
                              ),
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "사용자를 성공적으로 차단했습니다. \n프로필에서 차단을 해제할 수 있습니다.",
                                  textAlign: TextAlign.center,
                                ),
                                duration: Duration(seconds: 2),
                              )
                          );

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



  //사용자 차단 및 신고 바텀시트 다이어로그
  void _blockAndReportUserDialog(BuildContext context, String targetEmail) {
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
                        // 차단하기 기능 호출
                        HapticFeedback.lightImpact();
                        blockUserDialog(context, targetEmail);
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.block, // 차단하기에 알맞은 블록 아이콘
                                color: Color(0xFF1D4786),
                              ),
                              SizedBox(width: 5), // 아이콘과 텍스트 사이 간격
                              Text(
                                '차단하기',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                  height: 1,
                                  letterSpacing: -0.4,
                                  color: Color(0xFF1D4786),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // 신고하기 기능 호출
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ReportUserService(helperEmail : botton_email, targetEmail: targetEmail,)),
                        );
                        HapticFeedback.lightImpact();
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_active_sharp, // 신고하기와 관련된 경고 아이콘
                                color: Color(0xFF1D4786),
                              ),
                              SizedBox(width: 5), // 아이콘과 텍스트 사이 간격
                              Text(
                                '신고하기',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                  height: 1,
                                  letterSpacing: -0.4,
                                  color: Color(0xFF1D4786),
                                ),
                              ),
                            ],
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






  // build 함수는 위젯을 렌더링하는 데 사용됩니다.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
        child: AppBar(
          title: Text(
            getTitle(botton_domain),
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
      //게시판 몸통
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 10), // AppBar와 Row 사이에 10픽셀의 높이를 가진 공간을 추가합니다.
              Container(
                margin: EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: FutureBuilder<String?>(
                    future: getNickname(botton_email), // 닉네임 가져오기
                    builder: (context, nicknameSnapshot) {
                      if (nicknameSnapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(); // 닉네임 로딩 중
                      } else if (nicknameSnapshot.hasError) {
                        return Text("Error: ${nicknameSnapshot.error}");
                      } else if (!nicknameSnapshot.hasData || nicknameSnapshot.data == null) {
                        return Text('닉네임을 찾을 수 없습니다.');
                      }

                      String? helperUserNickName = nicknameSnapshot.data;

                      // 차단된 사용자 목록 가져오기
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('users')
                            .doc(helperUserNickName)
                            .collection('blacklist')
                            .snapshots(),
                        builder: (context, blacklistSnapshot) {
                          if (blacklistSnapshot.hasError) {
                            return Text("Error: ${blacklistSnapshot.error}");
                          }
                          if (blacklistSnapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }

                          // 차단된 사용자 목록을 리스트로 변환
                          List blockedEmails = blacklistSnapshot.data!.docs.map((doc) {
                            return doc['blockedEmail'];
                          }).toList();

                          // 게시글 스트림 생성
                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection(collection_domain).snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Text("Error: ${snapshot.error}");
                              }
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              }

                              // 차단된 사용자의 게시글을 필터링하여 개수 계산
                              var filteredPosts = snapshot.data!.docs.where((doc) {
                                return !blockedEmails.contains(doc['email']); // 차단된 사용자의 이메일 필터링
                              }).toList();

                              postCount = filteredPosts.length; // 필터링된 게시물 개수

                              return RichText(
                                text: TextSpan(
                                  text: '총 ',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    height: 1,
                                    letterSpacing: -0.5,
                                    color: Color(0xFF222222),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '$postCount건',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 20,
                                        height: 1.3,
                                        letterSpacing: -0.5,
                                        color: Color(0xFF1D4786),
                                      ),
                                    ),
                                    TextSpan(
                                      text: '의 게시글이 있어요!',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        height: 1,
                                        letterSpacing: -0.5,
                                        color: Color(0xFF222222),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              Flexible(
                child: StreamBuilder<List<DocumentSnapshot>>(
                  stream: getPosts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('오류가 발생했습니다.'));
                    } else if (snapshot.hasData) {
                      final posts = snapshot.data!;


                      if (posts.isEmpty) {
                        return Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 300,
                            height: 200,
                            child: Text(
                              '현재 게시물이 없습니다. \n새로운 주문이 들어오면 알림과 함께 \n이곳에서 확인하실 수 있습니다.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'NanumSquareRound',
                                color: Color(0xFF1D4786),
                              ),
                            ),
                          ),
                        );
                      }
                      final myEmail = currentUserEmail();

                      posts.sort((a, b) {
                        Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
                        Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
                        bool isMyPostA = dataA['email'] == myEmail;
                        bool isMyPostB = dataB['email'] == myEmail;
                        if (isMyPostA && !isMyPostB) return -1;
                        if (!isMyPostA && isMyPostB) return 1;
                        // 이메일이 같을 경우 시간을 기준으로 정렬
                        Timestamp timeA = dataA['date'];
                        Timestamp timeB = dataB['date'];

                        return timeB.compareTo(timeA); // 최신 순으로 정렬
                      });


                      return ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot doc = posts[index];
                          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                          bool isMyPost = data['email'] == myEmail;

                          return Column(
                            children: <Widget>[
                              Container(
                                width: MediaQuery.of(context).size.width * 0.9,

                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();

                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => FutureBuilder<String?>(
                                          future: _profilePhotoUrls[data['email']],
                                          // future: _getProfileImage(data['email']),
                                          builder: (context, snapshot) {
                                            String? profileImageUrl = snapshot.data;

                                            return HelpScreen(
                                              HelpScreenArguments(
                                                doc: doc,
                                                pushHelpButton: _pushHelpButton,
                                                userName: data['nickname'] ?? '사용자 이름 없음',
                                                timeAgo: data['date'] != null ? formatTimeAgo(data['date'] as Timestamp) : '시간 정보 없음',
                                                location: data['my_location'] ?? '위치 정보 없음',
                                                cost: data['cost'] ?? '비용 정보 없음',
                                                storeName: data['store'] ?? '가게 이름 없음',
                                                email: data['email'],
                                                request: data['Request'],
                                                current_location: data['current_location'],
                                                store_location: data['store_location'],
                                                isMyPost: isMyPost,
                                                profileImageUrl: profileImageUrl ?? '', // 프로필 이미지 URL 추가
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },

                                  child: FutureBuilder<String?>(
                                    future: _profilePhotoUrls[data['email']],
                                    builder: (context, snapshot) {
                                      String? profileImageUrl = snapshot.data;

                                      return _buildPostCard(
                                        userName: data['nickname'] ?? '사용자 이름 없음',
                                        timeAgo: data['date'] != null ? formatTimeAgo(data['date'] as Timestamp) : '시간 정보 없음',
                                        location: data['my_location'] ?? '위치 정보 없음',
                                        cost: data['cost'] ?? '비용 정보 없음',
                                        storeName: data['store'] ?? '가게 이름 없음',
                                        email: data['email'] ?? '가게 이름 없음',
                                        isMyPost: isMyPost,
                                        profileImageUrl: profileImageUrl ?? '',
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );

                        },
                      );
                    } else {
                      return Center(child: Text('게시글이 없습니다.'));
                    }
                  },
                ),
              ),
            ],
          ),
          if (_pushHelp)
            Container(
              color: Colors.grey.withOpacity(0.5),
              child: Center(
                child: Lottie.asset(
                  'assets/lottie/check_indigo.json',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            right: 20,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Container(
                  // width: 100,
                  // height: 45,
                  child: FloatingActionButton(
                    onPressed: () {
                      // 글쓰기 버튼 눌렀을 때의 동작
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => HanbatNewPostScreen()),

                      );
                    },
                    child: Icon(Icons.edit),
                    backgroundColor:Color(0xFF1D4786),
                    foregroundColor: Colors.white,
                    elevation: 3.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BoardPage()),
                      );
                    }
                  },
                ),
                _buildBottomNavItem(
                  iconPath: 'assets/pigma/school.svg',
                  label: '학과랭킹',
                  isActive: _selectedIndex == 3,
                  onTap: () {
                    if (_selectedIndex != 3) {
                      setState(() {
                        _selectedIndex = 3;
                      });
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DepartmentRankingScreen()),
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