import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ontheway_notebook/NaverBoard/NaverPostManager.dart';

class NaverHelpScreen extends StatefulWidget {
  @override
  _NaverHelpScreenState createState() => _NaverHelpScreenState();
}

class _NaverHelpScreenState extends State<NaverHelpScreen> {
  bool isDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    String? userEmail = NaverPostManager().getUserEmail();

    return Scaffold(
      appBar: AppBar(
        title: Text("내 게시물"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('naver_helpActions')
            .where('owner_email', isEqualTo: userEmail)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            // 에러가 있는 경우 UI에 에러 메시지를 표시합니다.
            return Center(child: Text('데이터 로드 중 오류가 발생했습니다.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 데이터 로딩 중인 경우 로딩 인디케이터를 표시합니다.
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty && !isDialogShowing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!isDialogShowing) {
                setState(() {
                  isDialogShowing = true;
                });
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('도움 제공 알림'),
                      content: Text('누군가 당신의 게시물에 도움을 제공하고 싶어합니다!'),
                      actions: <Widget>[
                        ElevatedButton(
                          child: Text('확인'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                ).then((value) {
                  setState(() {
                    isDialogShowing = false;
                  });
                });
              }
            });
          } else {
            // 데이터가 없는 경우 UI에 표시할 메시지입니다.
            return Center(child: Text('도움을 요청하는 게시물이 없습니다.'));
          }

          // 여기에서 사용자의 게시물 목록을 표시하는 위젯을 반환하도록 합니다.
          // 예시를 위해 빈 ListView를 반환합니다.
          return ListView(
            children: [/* 사용자 게시물 목록 위젯 */],
          );
        },
      ),
    );
  }
}





// class MyPostsScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     String? userEmail = NaverPostManager().getUserEmail(); // 현재 로그인한 사용자의 이메일
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("내 게시물"),
//       ),
//       body: StreamBuilder(
//         stream: FirebaseFirestore.instance
//             .collection('helpActions')
//             .where('owner_email', isEqualTo: userEmail)
//             .snapshots(),
//         builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
//           if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
//             // '도와주기' 액션이 감지되었을 때 처리 로직
//             showDialog(
//               context: context,
//               builder: (BuildContext context) {
//                 return AlertDialog(
//                   title: Text('도움 제공 알림'),
//                   content: Text('누군가 당신의 게시물에 도움을 제공하고 싶어합니다!'),
//                   actions: <Widget>[
//                     ElevatedButton(
//                       child: Text('확인'),
//                       onPressed: () {
//                         Navigator.of(context).pop();
//                       },
//                     ),
//                   ],
//                 );
//               },
//             );
//           }
//           // 여기서 사용자의 게시물 목록을 빌드하거나, 또는 다른 위젯을 반환할 수 있습니다.
//           return ListView(
//             children: [/* 사용자 게시물 목록 위젯 */],
//           );
//         },
//       ),
//     );
//   }
// }

