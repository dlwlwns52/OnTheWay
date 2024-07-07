import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IndividualRankingPage extends StatelessWidget {
  final String domain;
  final String name;

  IndividualRankingPage({required this.domain, required this.name});

  Future<List<Map<String, dynamic>>> _getSchoolMembersRanking(String domain) async {
    try {
      DocumentSnapshot schoolSnapshot = await FirebaseFirestore.instance.collection('schoolScores').doc(domain).get();
      if (!schoolSnapshot.exists) {
        return [];
      }

      Map<String, dynamic> data = schoolSnapshot.data() as Map<String, dynamic>;

      List<Map<String, dynamic>> ranking = data.entries
          .map((entry) => {'id': entry.key, 'score': entry.value})
          .toList();

      ranking.sort((a, b) => b['score'].compareTo(a['score']));

      return ranking;
    } catch (e) {
      print("Error in _getSchoolMembersRanking: $e");
      return [];
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
          appBar: AppBar(
            title: Text('$name 랭킹'),
            backgroundColor: Colors.deepPurple,
          ),
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
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.deepPurple,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                        title: Text(
                          member['id'],
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        trailing: Text(
                          '${member['score']}',
                          style: TextStyle(color: Colors.deepPurple, fontSize: 16, fontWeight: FontWeight.bold),
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
