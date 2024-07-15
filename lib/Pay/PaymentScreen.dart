import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

import '../Board/UiBoard.dart';
import '../Chat/AllUsersScreen.dart';
import '../HanbatSchoolBoard/HanbatUiBoard.dart';
import '../Profile/Profile.dart';
import '../Ranking/SchoolRanking.dart';

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
  }


  Future<Map<String, dynamic>> _fetchPaymentData() async {
    DocumentSnapshot<Map<String, dynamic>> student1Doc = await _firestore
        .collection('Payments').doc('학생1').get();
    DocumentSnapshot<Map<String, dynamic>> student2Doc = await _firestore
        .collection('Payments').doc('학생2').get();

    return {
      'student1': student1Doc.data(),
      'student2': student2Doc.data(),
    };
  }

  //비용을 숫자만 가져온다.
  String _extractCost(String cost) {
    final RegExp regex = RegExp(r'\d+');
    final match = regex.firstMatch(cost);
    return match != null ? match.group(0)! : '0';
  }

  //비용을 int형으로 바꾼다.
  int _extractCostAsInt(String cost) {
    String costString = _extractCost(cost);
    return int.parse(costString);
  }


  Widget _buildOrderInfoCard(Map<String, dynamic> student1, Map<String, dynamic> student2, int cost) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '주문자: ${student1['name']}   ⇢   헬퍼: ${student2['name']}',
                style: TextStyle(
                  fontFamily: 'NanumSquareRound',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(height: 10),
            Divider(thickness: 3),
            SizedBox(height: 10),
            Center(child:
            Text(
                '비용: $cost원',
              style: TextStyle(
                  fontFamily: 'NanumSquareRound',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Colors.indigo
              ), textAlign: TextAlign.center,
            ),
            ),
            SizedBox(height: 10),
            Divider(thickness: 2),
            SizedBox(height: 10),
            Center(child:
            Container(
              width: 150,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  backgroundColor: Colors.indigo[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                ),
                icon: Icon(Icons.payment), // 버튼 아이콘
                label: Text(
                  '결제하기',
                  style: TextStyle(
                    fontFamily: 'NanumSquareRound',
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            ),

            // Align(
            //   alignment: Alignment.center,
            //   child:Container(
            //     margin: EdgeInsets.all(8.0), // 여백 추가
            //     decoration: BoxDecoration(
            //       color: Colors.indigo[300], // 버튼 배경색
            //       borderRadius: BorderRadius.circular(10.0), // 버튼 모서리를 둥글게 만듦
            //     ),
            //     child: ElevatedButton.icon(
            //       onPressed: (){
            //
            //       },
            //       icon: Icon(Icons.payment), // 버튼 아이콘
            //       label: Text(
            //         '결제하기',
            //         style: TextStyle(
            //             fontFamily: 'NanumSquareRound',
            //             fontWeight: FontWeight.w600,
            //             fontSize: 20,
            //         ),
            //       ),
            //       style: ElevatedButton.styleFrom(
            //         backgroundColor: Colors.transparent, // 버튼 색상 투명하게 설정
            //         shadowColor: Colors.transparent, // 그림자 색상 투명하게 설정
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Stack(
          children: [
            Positioned.fill(
              child: Lottie.asset(
                'assets/lottie/login.json',
                fit: BoxFit.fill,
              ),
            ),
            AppBar(
              backgroundColor: Colors.transparent,
              title: Text(
                "진행 상황",
                style: TextStyle(
                  fontFamily: 'NanumSquareRound',
                  fontWeight: FontWeight.w600,
                  fontSize: 25,
                ),
              ),
              centerTitle: true,
              automaticallyImplyLeading: false, // '<' 이 뒤로가기 버튼 삭제
            ),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchPaymentData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('데이터 없음'));
          }

          var student1 = snapshot.data!['student1'];
          var student2 = snapshot.data!['student2'];
          int cost = _extractCostAsInt(student1['cost'].toString());

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildOrderInfoCard(student1, student2, cost),

              ],
            ),
          );
        },
      ),


      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_rounded,
                color: _selectedIndex == 0 ? Colors.indigo : Colors.black),
            label: '채팅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hourglass_empty_rounded,
                color: _selectedIndex == 1 ? Colors.indigo : Colors.black),
            //search
            label: '진행 상황',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined,
                color: _selectedIndex == 2 ? Colors.indigo : Colors.black),
            label: '게시판',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school,
                color: _selectedIndex == 3 ? Colors.indigo : Colors.black),
            label: '학교 랭킹',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person,
                color: _selectedIndex == 4 ? Colors.indigo : Colors.black),
            label: '프로필',
          ),
        ],
        selectedLabelStyle: TextStyle(
          fontFamily: 'NanumSquareRound',
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'NanumSquareRound',
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        selectedItemColor: Colors.indigo,
        // 선택된 항목의 텍스트 색상
        unselectedItemColor: Colors.black,
        // 선택되지 않은 항목의 텍스트 색상

        currentIndex: _selectedIndex,

        onTap: (index) {
          if (_selectedIndex == index) {
            // 현재 선택된 탭을 다시 눌렀을 때 아무 동작도 하지 않음
            return;
          }

          setState(() {
            _selectedIndex = index;
          });

          // 채팅방으로 이동
          if (index == 0) {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AllUsersScreen()),
            );
          }
          //진행 상황
          else if (index == 1) {
            HapticFeedback.lightImpact();

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PaymentStatusScreen()),
            );
          }


          //새 게시글 만드는 곳으로 이동
          else if (index == 2) {
            HapticFeedback.lightImpact();
            switch (botton_domain) {
              case 'naver.com':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HanbatBoardPage()),
                );
                break;
            // case 'hanbat.ac.kr':
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (context) => HanbaBoardPage()),
            //   );
            //   break;
              default:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BoardPage()),
                );
                break;
            }
          }


          // 학교 랭킹
          else if (index == 3) {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SchoolRankingScreen()),
            );
          }
          // 프로필
          else if (index == 4) {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserProfileScreen()),
            );
          }
        },
      ),
    );
  }
}
