
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:OnTheWay/Board/PostManager.dart';

class MyPostsScreen extends StatefulWidget {
  @override
  _MyPostsScreenState createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  bool isDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    String? userEmail = PostManager().getUserEmail(); // 현재 로그인한 사용자의 이메일

    return Scaffold(
      appBar: AppBar(
        title: Text("내 게시물"),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('helpActions')
            .where('owner_email', isEqualTo: userEmail)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty && !isDialogShowing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!isDialogShowing) {
                setState(() {
                  isDialogShowing = true; // Set the flag to true so it doesn't open again
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
                            setState(() {
                              isDialogShowing = false; // Reset the flag when the dialog is dismissed
                            });
                          },
                        ),
                      ],
                    );
                  },
                ).then((value) => {
                  // Reset the flag when the dialog is dismissed
                  if (isDialogShowing) {
                    setState(() {
                      isDialogShowing = false;
                    })
                  }
                });
              }
            });
          }
          // 여기서 사용자의 게시물 목록을 빌드하거나, 또는 다른 위젯을 반환할 수 있습니다.
          return ListView(
            children: [/* 사용자 게시물 목록 위젯 */],
          );
        },
      ),
    );
  }
}

//
// class MyPostsScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     String? userEmail = PostManager().getUserEmail(); // 현재 로그인한 사용자의 이메일
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

