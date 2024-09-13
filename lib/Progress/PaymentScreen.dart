import 'dart:async';
import 'dart:io';

import 'package:OnTheWay/Pay/KaKaoPay.dart';
import 'package:OnTheWay/Pay/TossPay.dart';
import 'package:OnTheWay/Progress/AcceptScreen.dart';
import 'package:OnTheWay/Progress/HandoverCompletedScreen.dart';
import 'package:OnTheWay/Progress/ReceiptCompletedScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';


import '../Alarm/AlarmUi.dart';
import '../Board/UiBoard.dart';
import '../Chat/AllUsersScreen.dart';
import '../Chat/ChatScreen.dart';
import '../Chat/Message.dart';
import '../HanbatSchoolBoard/HanbatSchoolBoard.dart';
import '../Profile/Profile.dart';
import '../Ranking/DepartmentRanking.dart';
import 'RequestScreen.dart';

class PaymentStatusScreen extends StatefulWidget {
  @override
  _PaymentStatusScreenState createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 바텀 네비게이션 인덱스
  int _selectedIndex = 1; // 기본 선택된 항목을 '게시판'으로 설정
  String botton_email = ""; // 사용자의 이메일을 저장할 변수
  String botton_domain = ""; // 사용자의 도메인을 저장할 변수

  //ui 변수
  List<DocumentSnapshot> acceptedPayments = [];
  late StreamSubscription<dynamic> _paymentsSubscription; // Firestore 스트림 구독을 위한 변수

  //오더용 페이 선택 변수
  String selectedPayment = "";

  //사진 전송 변수
  bool isPhotoSent = false;

  late Future<String?> _nickname;

  @override
  void initState() {
    super.initState();
    // 로그인 시 설정된 이메일 및 도메인 가져오기 -> 바텀 네비게이션 이용시 사용
    final FirebaseAuth _auth = FirebaseAuth.instance;
    botton_email = _auth.currentUser?.email ?? "";
    botton_domain = botton_email
        .split('@')
        .last
        .toLowerCase();

    _nickname = getNickname();
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
    return DefaultTabController(
        length: 4,  // 탭의 개수
        child: Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
        child: AppBar(
          title: Text(
            '진행상황',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 19,
              height: 1.0,
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
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data == null) {
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
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data == null) {
                        return Container();
                      }

                      String ownerNickname = snapshot.data!;
                      return StreamBuilder<DocumentSnapshot>(
                        stream: getMessageCountStream(ownerNickname),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return Container();
                          }
                          var data = snapshot.data!.data()
                          as Map<String, dynamic>;
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
                                    fontWeight: FontWeight.bold),
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




          body: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.07,
                child: TabBar(
                  labelColor: Color(0xFF1D4786),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.indigo.shade500,
                  tabs: [
                    Tab(
                      child: Text(
                        '요청',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          height: 1,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    Tab(
                      child: Text(
                        '수락',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          height: 1,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    Tab(
                      child: Text(
                        '수령완료',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          height: 1,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    Tab(
                      child: Text(
                        '전달완료',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          height: 1,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ],
                  onTap: (index)
                    {
                      print(index);
                      HapticFeedback.lightImpact();
                      },
                ),
              ),
              Expanded(
                // TabBarView는 TabBar 아래의 공간에서 다른 내용을 표시
                child: TabBarView(
                  children: [
                    RequestScreen(), // 요청 화면으로 연결
                    AcceptScreen(),
                    ReceiptCompletedScreen(),
                    HandoverCompletedScreen(),
                  ],
                ),
              ),
            ],
          ),

      //
      // Padding(
      //   padding: const EdgeInsets.all(10.0),
      //   child:ListView.builder(
      //   itemCount: acceptedPayments.length,
      //   itemBuilder: (context, index) {
      //     var paymentData = acceptedPayments[index].data() as Map<String, dynamic>;
      //     bool isHelper = paymentData['helper_email'] == botton_email;
      //     return _buildPaymentCard(paymentData, isHelper);
      //   },
      // ),
      // ),
      //
      //



      bottomNavigationBar: Padding(
        padding: Platform.isAndroid ?  EdgeInsets.only(bottom: 80, top: 8): const EdgeInsets.only(bottom: 30, top: 10),
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
        ),
    );
  }
}
