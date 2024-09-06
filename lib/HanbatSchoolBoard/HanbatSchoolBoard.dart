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
import 'package:flutter_svg/svg.dart';
import '../Alarm/AlarmUi.dart';

import '../Board/UiBoard.dart';
import '../Pay/PaymentScreen.dart';
import '../Profile/Profile.dart';
import '../Ranking/DepartmentRanking.dart';
import 'HanbatWriteBoard.dart';
import 'CnuHelpScreen.dart';
import '../Alarm/Alarm.dart';
import 'dart:io' show Platform;
import 'package:lottie/lottie.dart';

import 'HelpScreenArguments.dart';

// BoardPage 클래스는 게시판 화면의 상태를 관리하는 StatefulWidget 입니다.
class HanbatBoardPage extends StatefulWidget {
  @override
  _HanbatBoardPageState createState() => _HanbatBoardPageState(); // 상태(State) 객체를 생성합니다.
}

// _BoardPageState 클래스는 BoardPage의 상태를 관리합니다.
class _HanbatBoardPageState extends State<HanbatBoardPage> {
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

    // 로그인 시 설정된 이메일 및 도메인 가져오기 -> 바텀 네비게이션 이용시 사용
    final FirebaseAuth _auth = FirebaseAuth.instance;
    botton_email = _auth.currentUser?.email ?? "";
    botton_domain = botton_email.split('@').last.toLowerCase();


    //닉네임 가져옴
    _nickname = getNickname();


    // 각 이메일에 대해 프로필 사진 URL을 미리 로드 (학교 바뀌면 컬렉션 변환)
    FirebaseFirestore.instance.collection('naver_posts').get().then((snapshot) {
      for (var doc in snapshot.docs) {
        final email = doc['email'];
        _profilePhotoUrls[email] = _getProfileImage(email);
      }
      setState(() {}); // 상태를 갱신하여 FutureBuilder가 다시 빌드되도록 함
    });



    // _loadPostCount(); // 위젯 초기화 시 게시글 개수를 로드
  }



  void _pushHelpButton(bool value) {
    setState(() {
      _pushHelp = value;
    });
  }

  // Firestore의 'posts' 컬렉션으로부터 게시글 목록을 스트림 형태로 불러오는 함수입니다.
  Stream<List<DocumentSnapshot>> getPosts() {
    return firestore.collection('naver_posts').snapshots().map((snapshot) {
      return snapshot.docs.toList(); // 스냅샷의 문서들을 리스트로 변환하여 반환합니다.
    });
  }

  // 현재 로그인한 사용자의 이메일을 반환하는 메서드로그인이 필요합니다
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

  // //게시글 갯수 - 다른학교 추가시 수정
  // Future<int> getPostCount() async{
  //   try{
  //     QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('naver_posts').get();
  //     return querySnapshot.size;
  //   }
  //   catch(e)
  //   {
  //     print('Error fetching post count: $e');
  //     return 0; // 오류가 발생하면 0을 반환합니다.
  //   }
  // }
  //
  // void _loadPostCount() async {
  //   int count = await getPostCount(); // Firestore에서 게시글 개수를 가져옴
  //   setState(() {
  //     postCount = count; // 가져온 게시글 개수를 상태에 반영
  //   });
  // }



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

  //게시글 내용
  Widget _buildPostCard({
    required String userName,
    required String timeAgo,
    required String location,
    required String cost,
    required String storeName,
    required bool isMyPost,
    required String profileImageUrl
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
                            radius: 16, // 반지름 설정 (32 / 2)
                            backgroundColor: Colors.grey[200],
                            child: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                ? null
                                : Icon(
                              Icons.account_circle,
                              size: 32, // 원래 코드에서 width와 height가 32였으므로 여기에 맞춤
                              color: Color(0xFF1D4786),
                            ),
                            backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : null,
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 8, 0, 8),
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
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 10, 0, 9),
                    child: Text(
                      timeAgo,
                      style: TextStyle(
                        fontFamily: 'Pretendard', // Pretendard 폰트 지정
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height: 1,
                        letterSpacing: -0.5,
                        color: Color(0xFFAAAAAA),
                      ),

                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              width: 303,
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
              label: '비용',
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



  // build 함수는 위젯을 렌더링하는 데 사용됩니다.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
          child: AppBar(
              title: Text(
                '한국대학교 게시판',
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
                margin: EdgeInsets.fromLTRB(20, 0, 20, 19),
                  child: Align(
                  alignment: Alignment.topLeft,
                  child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('naver_posts').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }



                    postCount = snapshot.data?.size ?? 0;
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
                  }
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
                          alignment: Alignment.topCenter,
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
                                color: Colors.grey,
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
                          // bool nextPostIsMine = false;
                          // if (index + 1 < posts.length) {
                          //   Map<String, dynamic> nextData = posts[index + 1]
                          //       .data() as Map<String, dynamic>;
                          //   nextPostIsMine = nextData['email'] == myEmail;
                          // }


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
                            // builder: (context) => HanbatNewPostScreen()),
                          builder: (context) => Design()),
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