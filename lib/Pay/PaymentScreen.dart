import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:rxdart/rxdart.dart';

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

  //ui 변수
  List<DocumentSnapshot> acceptedPayments = [];
  late StreamSubscription<dynamic> _paymentsSubscription; // Firestore 스트림 구독을 위한 변수


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


    _fetchPayments(); // 정보가져
  }

  // 이 함수는 현재 로그인한 사용자의 채팅방 목록을 가져오고, 각 채팅방의 최신 메시지 시간에 따라 목록을 정렬합니다.
  Future<void> _fetchPayments() async {
    // 현재 로그인한 사용자 정보를 가져옵니다.
    User? currentUser = FirebaseAuth.instance.currentUser;
    // 사용자가 로그인하지 않았거나 이메일 정보가 없다면 함수를 종료합니다.
    if (currentUser == null || currentUser.email == null) {
      return;
    }

    // 현재 사용자의 이메일 주소를 가져옵니다.
    String currentUserEmail = currentUser.email!;
    // 'helper_email' 필드가 현재 사용자의 이메일과 일치하는 'Payments' 컬렉션의 문서 스트림을 가져옵니다.
    var helperEmailStream = FirebaseFirestore.instance
        .collection('Payments')
        .where('response', isEqualTo: 'accepted')
        .where('helper_email', isEqualTo: currentUserEmail)
        .snapshots();

    // 'owner_email' 필드가 현재 사용자의 이메일과 일치하는 'Payments' 컬렉션의 문서 스트림을 가져옵니다.
    var ownerEmailStream = FirebaseFirestore.instance
        .collection('Payments')
        .where('response', isEqualTo: 'accepted')
        .where('owner_email', isEqualTo: currentUserEmail)
        .snapshots();

    // 두 스트림을 결합하여 채팅방 목록을 생성합니다.
    _paymentsSubscription = Rx.combineLatest2(
        helperEmailStream, ownerEmailStream, (QuerySnapshot helperSnapshot, QuerySnapshot ownerSnapshot) async {
      // helperEmailStream과 ownerEmailStream에서 받은 문서들을 결합합니다.
      var combinedDocs = {...helperSnapshot.docs, ...ownerSnapshot.docs}.toList();


      // 위젯이 화면에 여전히 존재하는 경우에만 상태를 업데이트합니다.
      if (mounted) {
        setState(() {
          acceptedPayments = combinedDocs;
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

  Widget _buildPaymentCard(Map<String, dynamic> paymentData, bool isHelper) {
    int intCost = _extractCostAsInt('${paymentData['cost']}');
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 7,
      margin: EdgeInsets.fromLTRB(0,0,0,20), // 카드 위아래에 간격 추가
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '오더: ',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRound',
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: isHelper ? Colors.black : Colors.indigo[700]
                      ),
                    ),
                    TextSpan(
                      text: '${paymentData['owner_email_nickname']}',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRound',
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: isHelper ? Colors.black : Colors.indigo[700]
                      ),
                    ),
                    TextSpan(
                      text: '   ⇢   ',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRound',
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: Colors.black
                      ),
                    ),
                    TextSpan(
                      text: '헬퍼: ',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRound',
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: isHelper ? Colors.indigo[700] : Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: '${paymentData['helper_email_nickname']}',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRound',
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: isHelper ? Colors.indigo[700] : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Divider(thickness: 2),
            SizedBox(height: 10),
            Center(
              child: Text(
                '${paymentData['post_store']}  ⇢  ${paymentData['orderer_location']}',
                style: TextStyle(
                  fontFamily: 'NanumSquareRound',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Colors.indigo[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 7),
            Divider(thickness: 2),
            SizedBox(height: 7),
            Center(
              child: Text(
                '비용: $intCost원',
                style: TextStyle(
                  fontFamily: 'NanumSquareRound',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Colors.indigo[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 10),
            Divider(thickness: 3),
            SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: double.infinity, // 너비를 부모의 너비로 설정
                child: ElevatedButton.icon(
                  onPressed: () {
                    isHelper ? print(1) : print(2);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    backgroundColor: Colors.indigo[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  icon: Icon(Icons.payment), // 버튼 아이콘
                  label: Text(
                    isHelper ? '결제 요청하기' : '결제하기',
                    style: TextStyle(
                      fontFamily: 'NanumSquareRound',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                ),
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

      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child:ListView.builder(
        itemCount: acceptedPayments.length,
        itemBuilder: (context, index) {
          var paymentData = acceptedPayments[index].data() as Map<String, dynamic>;
          bool isHelper = paymentData['helper_email'] == botton_email;
          return _buildPaymentCard(paymentData, isHelper);
        },
      ),
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
