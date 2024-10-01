import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import '../Alarm/AlarmUi.dart';

import '../Chat/AllUsersScreen.dart';

import '../Progress/PaymentScreen.dart';
import '../Profile/Profile.dart';
import '../SchoolBoard/SchoolBoard.dart';
import 'IndividualRankingPage.dart';

class DepartmentRankingScreen extends StatefulWidget {
  @override
  _DepartmentRankingScreenState createState() => _DepartmentRankingScreenState();
}

class _DepartmentRankingScreenState extends State<DepartmentRankingScreen> {

  // 바텀 네비게이션 인덱스
  int _selectedIndex = 3; // 기본 선택된 항목을 '게시판'으로 설정
  String botton_email = ""; // 사용자의 이메일을 저장할 변수
  String botton_domain = ""; // 사용자의 도메인을 저장할 변수

  //닉네임 가져오기
  late Future<String?> _nickname;

  @override
  void initState() {
    super.initState();
    // updateSchoolLogos(); // 초기 로고 업데이트 호출

    final FirebaseAuth _auth = FirebaseAuth.instance;
    botton_email = _auth.currentUser?.email ?? "";
    botton_domain = botton_email.split('@').last.toLowerCase();


    //닉네임 가져옴
    _nickname = getNickname();
  }

  //학과 추가
  // Future<void> addDepartmentsToFirestore() async {
  //   try {
  //     // 학과 리스트 초기화
  //     List<String> departmentsList = [
  //       '국어국문학과', '영어영문학과', '독어독문학과', '불어불문학과', '중어중문학과',
  //       '일어일문학과', '한문학과', '언어학과', '국사학과', '사학과', '고고학과', '철학과',
  //       '사회학과', '문헌정보학과', '심리학과', '언론정보학과', '사회복지학과', '정치외교학과',
  //       '행정학부', '도시·자치융합학과', '수학과', '정보통계학과', '물리학과', '천문우주과학과',
  //       '화학과', '생화학과', '지질환경과학과', '해양환경과학과', '스포츠과학과', '무용학과',
  //       '반도체융합학과', '경제학과', '경영학부', '무역학과', '아시아비즈니스국제학과',
  //       '건축학과(5년제)', '건축공학과', '토목공학과', '환경공학과', '기계공학부',
  //       '메카트로닉스공학과', '선박해양공학과', '항공우주공학과', '전기공학과', '전자공학과',
  //       '전파정보통신공학과', '컴퓨터융합학부', '인공지능학과', '신소재공학과', '응용화학공학과',
  //       '유기재료공학과', '자율운항시스템공학과', '에너지공학과', '식물자원학과', '원예학과',
  //       '산림환경자원학과', '환경소재공학과', '동물자원과학부', '응용생물학과', '생물환경화학과',
  //       '식품공학과', '지역환경토목학과', '바이오시스템기계공학과', '농업경제학과', '약학과',
  //       '의학과(의예과)', '의류학과', '식품영양학과', '소비자학과', '음악과', '관현악과',
  //       '회화과', '조소과', '디자인창의학과', '수의학과(수의예과)', '국어교육과', '영어교육과',
  //       '수학교육과', '교육학과', '체육교육과', '건설공학교육과', '기계·재료공학교육과',
  //       '전기·전자·통신공학교육과', '화학공학교육과', '기술교육과', '간호학과', '생물과학과',
  //       '미생물·분자생명과학과', '생명정보융합학과', '인문사회학과', '리더십과 조직과학과',
  //       '공공안전학과', '국토안보학전공', '해양안보학전공'
  //     ];
  //
  //     // departments 데이터를 Map으로 변환하여 초기 점수 0으로 설정
  //     Map<String, int> departmentsData = {
  //       for (var department in departmentsList) department: 0
  //     };
  //
  //     // Firestore에 departments 필드를 추가
  //     await FirebaseFirestore.instance
  //         .collection('schoolScores')
  //         .doc('g.cnu.ac.kr')  // 문서 id
  //         .set({
  //       'departments': departmentsData
  //     }, SetOptions(merge: true));  // 기존 데이터에 병합 (merge: true)
  //
  //     print('Departments successfully added to Firestore');
  //   } catch (e) {
  //     print('Error adding departments to Firestore: $e');
  //   }
  // }


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



  // 학과 점수 반환
  Future<List<Map<String, dynamic>>> _getDepartmentsTotals() async {
    try {
      // Firestore에서 'naver.com' 문서를 가져옴
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
          .collection('schoolScores')
          .doc(botton_domain)
          .get();

      // 문서의 data를 Map으로 변환
      Map<String, dynamic>? data = snapshot.data();



      if (data != null && data.containsKey('departments')) {
        // departments 필드를 가져와서 Map<String, dynamic>으로 변환
        Map<String, dynamic> departments = Map<String, dynamic>.from(data['departments']);


        // 각 학과별 점수를 포함한 데이터를 리스트로 변환 후 정렬
        List<Map<String, dynamic>> sortedDepartments = departments.entries
            .map((entry) => {
          'department': entry.key?.toString() ?? 'Unknown',  // key가 null일 경우 'Unknown'
          'score': entry.value is int ? entry.value : 0   // value가 null일 경우 0으로 설정
        })
            .toList()
          ..sort((a, b) => b['score'].compareTo(a['score']));  // 점수를 기준으로 내림차순 정렬

        return sortedDepartments;
      } else {
        print("Error: departments 필드를 찾을 수 없습니다.");
        return [];
      }
    } catch (e) {
      print("Error in _getDepartmentsTotals: $e");
      return [];
    }
  }



  // total 색상
  Color _getColor(int index) {
    switch (index) {
      case 0:
        return Color(0xffe8bd50);
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown.shade300;
      default:
        return  Color(0xFF1D4786);
    }
  }

  // 등수 대로 랭킹 순위 크기 차별화
  FontWeight _getFontWeightForRank(int index) {
    switch (index) {
      case 0:
        return FontWeight.w900; // 1등
      case 1:
        return FontWeight.w800; // 2등
      case 2:
        return FontWeight.w700; // 3등
      default:
        return FontWeight.w600; // 4등부터
    }
  }

// 등수 대로 학과 이름 크기 차별화
  double _getSizeForDepartment(int index) {
    switch (index) {
      case 0:
        return 19; // 1등
      case 1:
        return 18; // 2등
      case 2:
        return 17; // 3등
      default:
        return 16; // 4등부터
    }
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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
        child: AppBar(
          title: Text(
            '학과 랭킹',
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



      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getDepartmentsTotals(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                '오류가 발생했습니다: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('No data available'),
            );
          }

          List<Map<String, dynamic>> getDepartments = snapshot.data!;
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Container(
              padding: EdgeInsets.fromLTRB(screenWidth * 0.05, screenHeight * 0.01, screenWidth * 0.05, 0),
              child: ListView.builder(
                itemCount: getDepartments.length,
                itemBuilder: (context, index) {
                  var Department = getDepartments[index];
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: (){
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "${Department['department']}는 현재 ${Department['score']}회로 ${index + 1}위를 기록하고 있습니다.",
                                        textAlign: TextAlign.center,
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                );
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFEEEEEE),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(0, screenHeight * 0.025, 0, screenHeight * 0.025),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            margin: EdgeInsets.fromLTRB(0, screenHeight * 0.006, screenWidth * 0.04, screenHeight * 0.006),
                                            child: Text(
                                              '${index + 1}위',
                                              style: TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontWeight: _getFontWeightForRank(index),
                                                fontSize: 20,
                                                height: 1,
                                                letterSpacing: -0.5,
                                                  color: _getColor(index)
                                                // color: Color(0xFF1D4786),
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                margin: EdgeInsets.fromLTRB(0, 0, screenWidth * 0.03, 0),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(64),
                                                  color: Color(0xFFF6F7F8),
                                                ),
                                                child:
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(32),
                                                  child: Container(
                                                    child: SvgPicture.asset(
                                                      'assets/pigma/cnuLogo.svg',
                                                    ),
                                                    width: screenWidth * 0.08, // 아이콘 크기 조정
                                                    height: screenWidth * 0.08,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                margin: EdgeInsets.fromLTRB(0, screenHeight * 0.01, 0, screenHeight * 0.01),
                                                child: Text(
                                                  Department['department'],
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
                                        ],
                                      ),
                                      Container(
                                        margin: EdgeInsets.fromLTRB(0, screenHeight * 0.006, 0, screenHeight * 0.006),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              margin: EdgeInsets.fromLTRB(0, screenHeight * 0.002, screenWidth * 0.015, screenHeight * 0.002),
                                              child: Text(
                                                '${Department['score']}회',
                                                style: TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  height: 1,
                                                  letterSpacing: -0.4,
                                                  color: Color(0xFF6294E0),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
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
