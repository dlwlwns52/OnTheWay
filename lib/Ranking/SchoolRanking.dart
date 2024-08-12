import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../Board/UiBoard.dart';
import '../Chat/AllUsersScreen.dart';
import '../HanbatSchoolBoard/HanbatUiBoard.dart';
import '../Pay/PaymentScreen.dart';
import '../Profile/Profile.dart';
import 'IndividualRankingPage.dart';

class SchoolRankingScreen extends StatefulWidget {
  @override
  _SchoolRankingScreenState createState() => _SchoolRankingScreenState();
}

class _SchoolRankingScreenState extends State<SchoolRankingScreen> {

  // 바텀 네비게이션 인덱스
  int _selectedIndex = 3; // 기본 선택된 항목을 '게시판'으로 설정
  String botton_email = ""; // 사용자의 이메일을 저장할 변수
  String botton_domain = ""; // 사용자의 도메인을 저장할 변수


  @override
  void initState() {
    super.initState();
    updateSchoolLogos(); // 초기 로고 업데이트 호출

    final FirebaseAuth _auth = FirebaseAuth.instance;
    botton_email = _auth.currentUser?.email ?? "";
    botton_domain = botton_email.split('@').last.toLowerCase();

  }


  // 도메인과 학교 이름 매핑 - !! 학교 추가시 작성
  final List<Map<String, String>> _domains = [
    {'name': '전북대학교', 'domain': 'jbnu.ac.kr'},
    {'name': '충남대학교', 'domain': 'cnu.ac.kr'},
    {'name': '한밭대학교', 'domain': 'edu.hanbat.ac.kr'},
    {'name': '부산대학교', 'domain': 'pusan.ac.kr'},
    //임시
    {'name': '카카오대학교', 'domain': 'kakao.com'},
    {'name': '네이버대학교', 'domain': 'naver.com'},
    {'name': '지메일 대학교', 'domain': 'gmail.com'},
    // 도메인 추가
  ];
  //학교 이름 리턴
  String _getSchoolName(String domain) {
    var school = _domains.firstWhere((element) => element['domain'] == domain, orElse: () => {'name': domain});
    return school['name']!;
  }

  // Firebase Storage에서 이미지 URL을 가져오는 함수
  Future<String> getDownloadUrlFromStorage(String fileName) async {
    Reference storageReference = FirebaseStorage.instance.ref().child('schoolLogo/$fileName');
    String downloadUrl = await storageReference.getDownloadURL();
    return downloadUrl;
  }

  // 각 대학 별로 Firestore에 이미지 URL을 저장하는 함수
  Future<void> saveImageUrlToFirestore(String schoolDomain, String imageUrl) async {
    await FirebaseFirestore.instance.collection('schoolScores').doc(schoolDomain).update({'logoUrl': imageUrl});
  }

  // 이미지 파일을 Firebase Storage에서 가져와 URL을 얻고 Firestore에 저장
  Future<void> updateSchoolLogos() async {
    final Map<String, String> logoFiles = {
      // 학교 추가시 이부분 꼭 추가!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!1
      'cnu.ac.kr': 'CNU.jpg',
      'edu.hanbat.ac.kr': 'HBNU.jpeg',
      'jbnu.ac.kr': 'JBNU.jpg',
      'pusan.ac.kr': 'PNU.jpg',
      'naver.com' : 'naver.png',
      'gmail.com' : 'naver.png',
    };

    for (var entry in logoFiles.entries){
      String domain = entry.key; // 도메인
      String fileName = entry.value; // 파일명
      try {
        // 파일명으로부터 다운로드 URL을 가져옵니다.
        String downloadUrl = await getDownloadUrlFromStorage(fileName);
        // 해당 도메인의 Firestore 문서에 다운로드 URL을 저장합니다.
        await saveImageUrlToFirestore(domain, downloadUrl);

      }catch (e) {
        print('Error updating logo for $domain: $e');
      }
    }
  }


  // 학교 도메인 , 학교 이름, 총 점수 반환
  Future<List<Map<String, dynamic>>> _getSchoolTotals() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('schoolScores').get();

      List<Map<String, dynamic>> schoolTotals = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // logoUrl은 String이므로 0 처리
        int total = data.values.fold(0, (sum, value){
          int intValue = 0;
          if (value is int){
            intValue = value;
          }
          else if (value is String) {
            intValue = int.tryParse(value) ?? 0;
          }
          return sum + intValue;
        });

        return {
          'domain': doc.id,
          'name': _getSchoolName(doc.id),
          'total': total,
          'logoUrl': data['logoUrl'] ?? ''
        };

      }).toList();
      schoolTotals.sort((a, b) => b['total'].compareTo(a['total']));
      return schoolTotals;

    } catch (e) {
      print("Error in _getSchoolTotals: $e");
      return [];
    }
  }


  Widget _buildLeading(int index) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _getGradient(index), // 등수에 따른 그라디언트 적용
        border: Border.all(color: Colors.white, width: 2.0),
      ),
      child: CircleAvatar(
        radius: 25,
        backgroundColor: Colors.transparent,
        child: Text(
          '${index + 1}',
          style:
          TextStyle(
            color: Colors.white,
            fontFamily: 'NanumSquareRound',
            fontWeight: FontWeight.w700,
            fontSize: 25,
          ),
        ),
      ),
    );
  }

  //메달 색상
  LinearGradient _getGradient(int index) {
    switch (index) {
      case 0: // 1등
        return LinearGradient(
          colors: [Colors.amber, Colors.amber, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 1: // 2등
        return LinearGradient(
          colors: [Colors.grey, Colors.grey, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 2: // 3등
        return LinearGradient(
          colors: [Color(0xFFB87333), Color(0xFFB87333), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default: // 4등부터
        return LinearGradient(
          colors: [Colors.purple.shade300, Colors.purple.shade300],
          // colors: [Colors.indigo.shade300, Colors.indigo.shade300, Colors.grey.shade300, Colors.indigo.shade300, Colors.indigo.shade300,],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
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
        return Colors.purple.shade300;
    }
  }

  // 등수 대로 크기 차별화
  double _getSizeForRank(int index) {
    switch (index) {
      case 0:
        return 24; // 1등
      case 1:
        return 23; // 2등
      case 2:
        return 22; // 3등
      default:
        return 21; // 4등부터
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.purpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: AppBar(
                automaticallyImplyLeading : false, // '<' 이 뒤로가기 버튼 삭제
                title:  Text(
                  '학교별 랭킹',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NanumSquareRound',
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
              ),
            ),
          ),
          body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getSchoolTotals(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple)));
              } else if (snapshot.hasError) {
                return Center(child: Text('오류가 발생했습니다: ${snapshot.error}', style: TextStyle(color: Colors.red)));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No data available'));
              }

              List<Map<String, dynamic>> schoolTotals = snapshot.data!;
              return ListView.builder(
                itemCount: schoolTotals.length,
                itemBuilder: (context, index) {
                  var school = schoolTotals[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(

                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      color: Colors.white,
                      shadowColor: Colors.indigo.withOpacity(0.5),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                        leading: _buildLeading(index),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            SizedBox(),
                            Column(
                              children: [
                                Image.network(
                                  school['logoUrl'],
                                  height: 50,
                                  width: 50,
                                ),
                                SizedBox(height: 7),
                                Text(
                                  school['name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'NanumSquareRound',
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${school['total']}',
                              style: TextStyle(
                                fontSize: _getSizeForRank(index),
                                fontWeight: FontWeight.w800,
                                fontFamily: 'NanumSquareRound',
                                color: _getColor(index)
                                ,
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.black, size: 30),
                          ],
                        ),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => IndividualRankingPage(domain: school['domain'], name: school['name']),
                          ));
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_rounded, color: _selectedIndex == 0 ? Colors.indigo : Colors.black),
            label: '채팅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hourglass_empty_rounded,color: _selectedIndex == 1 ? Colors.indigo : Colors.black), //search
            label: '진행 상황',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined, color: _selectedIndex == 2 ? Colors.indigo : Colors.black),
            label: '게시판',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school, color: _selectedIndex == 3 ? Colors.indigo : Colors.black),
            label: '학교 랭킹',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: _selectedIndex == 4 ? Colors.indigo : Colors.black),
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
        selectedItemColor: Colors.indigo,    // 선택된 항목의 텍스트 색상
        unselectedItemColor: Colors.black,  // 선택되지 않은 항목의 텍스트 색상

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
