import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RankingPage extends StatefulWidget {
  final String userId;
  RankingPage({required this.userId});

  @override
  _RankingPageState createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  Future<List<MapEntry<String, dynamic>>> _fetchScores() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('SchoolScores')
        .doc(widget.userId)
        .get();


    Map<String, int> scores = Map.from(snapshot.data() as Map<String, dynamic>);
    var sortedScores = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedScores;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async{
          return true;
        },
      child: GestureDetector(
        onHorizontalDragEnd: (details){
          if (details.primaryVelocity! >  0){
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
            title: Text('학교별 랭킹', style: TextStyle(fontSize: 22),),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: FutureBuilder<List<MapEntry<String, dynamic>>>(
        future: _fetchScores(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var entry = snapshot.data![index];
                  return _buildRankingCard(entry, index);
                },
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text("오류가 발생했습니다: ${snapshot.error}", style: TextStyle(color: Colors.red)),
              );
            }
          }
          return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple)));
        },
      ),
    ),
    ),
    );
  }

  Widget _buildRankingCard(MapEntry<String, dynamic> entry, int index) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getBackgroundColor(index),
            child: Text(
              '${index + 1}',
              style: TextStyle(color: Colors.white),
            ),
          ),
          title: Text(entry.key, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          trailing: Chip(
            label: Text('${entry.value}', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.deepPurple,
          ),
          onTap: () {
            _showDetailsDialog(entry.key, entry.value);
          },
        ),
      ),
    );
  }

  Color _getBackgroundColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return Colors.deepPurple;
    }
  }

  void _showDetailsDialog(String school, int score) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.school, size: 80, color: Colors.white),
                SizedBox(height: 20),
                Text(
                  '$school 상세 정보',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 10),
                Text(
                  '점수: $score',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.close, color: Colors.white),
                  label: Text('닫기', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
