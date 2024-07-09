import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IndividualRankingPage extends StatelessWidget {
  final String domain;
  final String name;

  IndividualRankingPage({required this.domain, required this.name});


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
          .map((entry) { num score;
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
                    colors: [Colors.deepPurpleAccent, Colors.indigoAccent, Colors.deepPurpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: AppBar(
                  title:  Text(
                    '$name 랭킹',
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
          // appBar: AppBar(
          //   title: Text('$name 랭킹',
          //     style : TextStyle(
          //       color: Colors.white,
          //       fontFamily: 'NanumSquareRound',
          //       fontWeight: FontWeight.w700,
          //       fontSize: 20,
          //     ),
          //   ),

            // backgroundColor: Colors.deepPurple,

          body: FutureBuilder<List<Map<String, dynamic>>>(
            future: _getSchoolMembersRanking(domain),
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
        ),
        ),
        );
      }
    }
