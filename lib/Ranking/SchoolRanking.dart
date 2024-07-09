import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'IndividualRankingPage.dart';

class SchoolRankingScreen extends StatefulWidget {
  @override
  _SchoolRankingScreenState createState() => _SchoolRankingScreenState();
}

class _SchoolRankingScreenState extends State<SchoolRankingScreen> {
  @override
  void initState() {
    super.initState();
    updateSchoolLogos(); // 초기 로고 업데이트 호출
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
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            Navigator.pop(context);
          }
        },
        child: Scaffold(
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
        ),
      ),
    );
  }
}
