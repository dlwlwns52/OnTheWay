import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../Board/UiBoard.dart';
import '../Chat/AllUsersScreen.dart';
import '../HanbatSchoolBoard/HanbatUiBoard.dart';
import '../Profile/Profile.dart';
import 'SchoolRanking.dart';

class IndividualRankingPage extends StatefulWidget {
  final String domain;
  final String name;

  IndividualRankingPage({required this.domain, required this.name});

  @override
  _IndividualRankingPageState createState() => _IndividualRankingPageState();
}

class _IndividualRankingPageState extends State<IndividualRankingPage> {
  late Future<List<Map<String, dynamic>>> _rankingFuture;
  // 바텀 네비게이션 인덱스
  int _selectedIndex = 3; // 기본 선택된 항목을 '게시판'으로 설정
  String botton_email = ""; // 사용자의 이메일을 저장할 변수
  String botton_domain = ""; // 사용자의 도메인을 저장할 변수

  @override
  void initState() {
    super.initState();
    _rankingFuture = _getSchoolMembersRanking(widget.domain);
    final FirebaseAuth _auth = FirebaseAuth.instance;
    botton_email = _auth.currentUser?.email ?? "";
    botton_domain = botton_email.split('@').last.toLowerCase();

  }

  // 파이어스토어에서 학생 데려오기
  Future<List<Map<String, dynamic>>> _getSchoolMembersRanking(String domain) async {
    try {
      DocumentSnapshot schoolSnapshot = await FirebaseFirestore.instance.collection('schoolScores').doc(domain).get();
      if (!schoolSnapshot.exists) {
        return [];
      }

      Map<String, dynamic> data = schoolSnapshot.data() as Map<String, dynamic>;

      List<Map<String, dynamic>> ranking = data.entries
          .where((entry) => entry.key != 'logoUrl') // logoUrl 필드 제외
          .map((entry) {
        num score;
        if (entry.value is num) {
          score = entry.value;
        } else if (entry.value is String) {
          score = num.tryParse(entry.value) ?? 0;
        } else {
          score = 0;
        }
        return {'id': entry.key, 'score': score};
      }).toList();

      ranking.sort((a, b) => b['score'].compareTo(a['score']));

      return ranking;
    } catch (e) {
      print("Error in _getSchoolMembersRanking: $e");
      return [];
    }
  }

  // 등수 ui
  Widget _buildLeading(int index) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _getGradient(index), // 등수에 따른 그라디언트 적용
        border: Border.all(color: Colors.white, width: 2.0),
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.transparent,
        child: Text(
          '${index + 1}',
          style: TextStyle(
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
                  colors: [Colors.deepPurpleAccent, Colors.indigoAccent, Colors.deepPurpleAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: AppBar(
                title: Text(
                  '${widget.name} 랭킹',
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
            future: _rankingFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Colors.deepPurple));
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No data available', style: TextStyle(color: Colors.grey)));
              }

              List<Map<String, dynamic>> membersRanking = snapshot.data!;
              return ListView.builder(
                itemCount: membersRanking.length,
                itemBuilder: (context, index) {
                  var member = membersRanking[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        leading: _buildLeading(index),
                        title: Text(
                          member['id'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'NanumSquareRound',
                          ),
                        ),
                        trailing: Text(
                          '${member['score']}',
                          style: TextStyle(color: _getColor(index), fontSize: _getSizeForRank(index), fontWeight: FontWeight.bold),
                        ),
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
        ),
      ),
    );
  }
}
