import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IndividualRankingPage extends StatelessWidget { // 특정 학교 구성원의 랭킹 화면을 보여주는 클래스
  final String domain; // 학교 도메인을 저장하는 변수
  final String name;

  IndividualRankingPage({required this.domain, required this.name}); // 생성자에서 도메인을 받아옴



  // 파어어 스토어 schoolScores 안 domain별로 정보 가져오기
  Future<List<Map<String, dynamic>>> _getSchoolMembersRanking(String domain) async { // 특정 학교 구성원의 랭킹 데이터를 가져오는 메서드
    try {
      DocumentSnapshot schoolSnapshot = await FirebaseFirestore.instance.collection('schoolScores').doc(domain).get(); // Firestore에서 해당 도메인의 문서를 가져옴
      if (!schoolSnapshot.exists) { // 문서가 존재하지 않으면
        return []; // 빈 리스트 반환
      }

      Map<String, dynamic> data = schoolSnapshot.data() as Map<String, dynamic>; // 문서 데이터를 맵으로 변환

      List<Map<String, dynamic>> ranking = data.entries // 데이터 항목들을 리스트로 변환
          .map((entry) => {'id': entry.key, 'score': entry.value}) // 각 항목을 맵으로 변환
          .toList();

      ranking.sort((a, b) => b['score'].compareTo(a['score'])); // 점수를 기준으로 내림차순 정렬

      return ranking; // 정렬된 리스트 반환
    } catch (e) {
      print("Error in _getSchoolMembersRanking: $e"); // 에러가 발생하면 콘솔에 출력
      return []; // 빈 리스트 반환
    }
  }



  @override
  Widget build(BuildContext context) { // 화면을 빌드하는 메서드
    return Scaffold( // 화면의 기본 레이아웃을 설정
      appBar: AppBar( // 상단에 앱바 추가
        title: Text('$name $domain 랭킹',), // 앱바의 제목 설정
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>( // FutureBuilder를 사용하여 비동기 데이터 처리
        future: _getSchoolMembersRanking(domain), // 특정 학교 구성원의 랭킹 데이터를 가져오는 Future 설정
        builder: (context, snapshot) { // 데이터를 기반으로 화면을 구성하는 빌더
          if (snapshot.connectionState == ConnectionState.waiting) { // 데이터 로딩 중일 때
            return Center(child: CircularProgressIndicator()); // 로딩 스피너 표시
          } else if (snapshot.hasError) { // 에러가 발생했을 때
            return Center(child: Text('Error: ${snapshot.error}')); // 에러 메시지 표시
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) { // 데이터가 없을 때
            return Center(child: Text('No data available')); // 데이터 없음 메시지 표시
          }

          List<Map<String, dynamic>> membersRanking = snapshot.data!; // 랭킹 데이터를 변수에 저장
          return ListView.builder( // 리스트뷰로 데이터를 표시
            itemCount: membersRanking.length, // 리스트 아이템 수 설정
            itemBuilder: (context, index) { // 각 리스트 아이템을 빌드하는 메서드
              var member = membersRanking[index]; // 현재 아이템의 데이터를 가져옴
              return ListTile( // 리스트 아이템을 생성
                title: Text('${member['id']} : ${member['score']}'), // 아이템의 텍스트 설정
              );
            },
          );
        },
      ),
    );
  }
}



//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class IndividualRankingPage extends StatelessWidget {
//   final String domain;
//   final String name;
//
//   IndividualRankingPage({required this.domain, required this.name});
//
//   // 파이어스토어 schoolScores 안 domain별로 정보 가져오기
//   Future<List<Map<String, dynamic>>> _getSchoolMembersRanking(String domain) async {
//     try {
//       DocumentSnapshot schoolSnapshot = await FirebaseFirestore.instance.collection('schoolScores').doc(domain).get();
//       if (!schoolSnapshot.exists) {
//         return [];
//       }
//
//       Map<String, dynamic> data = schoolSnapshot.data() as Map<String, dynamic>;
//       List<Map<String, dynamic>> ranking = data.entries
//           .map((entry) => {'id': entry.key, 'score': entry.value})
//           .toList();
//
//       ranking.sort((a, b) => b['score'].compareTo(a['score']));
//
//       return ranking;
//     } catch (e) {
//       print("Error in _getSchoolMembersRanking: $e");
//       return [];
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('$name 랭킹'),
//         backgroundColor: Colors.deepPurple,
//       ),
//       body: FutureBuilder<List<Map<String, dynamic>>>(
//         future: _getSchoolMembersRanking(domain),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple)));
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return Center(child: Text('No data available'));
//           }
//
//           List<Map<String, dynamic>> membersRanking = snapshot.data!;
//           return ListView.builder(
//             itemCount: membersRanking.length,
//             itemBuilder: (context, index) {
//               var member = membersRanking[index];
//               return Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//                 child: Card(
//                   elevation: 4,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(15),
//                   ),
//                   child: ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: Colors.deepPurple,
//                       child: Text(
//                         '${index + 1}',
//                         style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                     title: Text(
//                       '${member['id']}',
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Text(
//                       '점수: ${member['score']}',
//                       style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//                     ),
//                     trailing: Icon(Icons.star, color: Colors.amber),
//                     onTap: () {
//                       _showMemberDetails(context, member);
//                     },
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
//
//   void _showMemberDetails(BuildContext context, Map<String, dynamic> member) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20.0),
//           ),
//           child: Container(
//             padding: EdgeInsets.all(20.0),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.deepPurple, Colors.purpleAccent],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(20.0),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: <Widget>[
//                 Icon(Icons.person, size: 80, color: Colors.white),
//                 SizedBox(height: 20),
//                 Text(
//                   '${member['id']} 상세 정보',
//                   style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
//                 ),
//                 SizedBox(height: 10),
//                 Text(
//                   '점수: ${member['score']}',
//                   style: TextStyle(fontSize: 18, color: Colors.white),
//                 ),
//                 SizedBox(height: 20),
//                 ElevatedButton.icon(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                   },
//                   icon: Icon(Icons.close, color: Colors.white),
//                   label: Text('닫기', style: TextStyle(color: Colors.white)),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.deepPurple,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
