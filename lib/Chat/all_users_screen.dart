//
// //이 코드는 Flutter 애플리케이션에서 모든 사용자 목록을 표시하고 해당 사용자를 선택하여
// //채팅 화면으로 이동할 수 있는 화면을 구현한 것입니다. 주석을 추가하여 코드를 설명하겠습니다:
//
// import 'package:OnTheWay/Chat/chat_screen.dart';
// import 'package:OnTheWay/Chat/home_page.dart';
// import 'package:OnTheWay/Chat/main.dart';
// import 'package:OnTheWay/Chat/models/user_details.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_sign_in/google_sign_in.dart';
//
// class AllUsersScreen extends StatefulWidget {
//   _AllUsersScreenState createState() => _AllUsersScreenState();
// }
//
// class _AllUsersScreenState extends State<AllUsersScreen> {
//   final GoogleSignIn googleSignIn = GoogleSignIn();
//   FirebaseAuth firebaseAuth = FirebaseAuth.instance;
//   StreamSubscription<QuerySnapshot> _subscription;
//   List<DocumentSnapshot> usersList; // 모든 사용자 목록을 저장하는 리스트
//   final CollectionReference _collectionReference =
//   Firestore.instance.collection("users"); // Firestore에서 사용자 정보를 가져오는 레퍼런스
//
//   @override
//   void initState() {
//     super.initState();
//     // Firestore의 'users' 컬렉션을 모니터링하여 데이터 스냅샷을 수신하는 리스너를 등록합니다.
//     _subscription = _collectionReference.snapshots().listen((datasnapshot) {
//       setState(() {
//         usersList = datasnapshot.documents; // 사용자 목록을 업데이트합니다.
//         print("Users List ${usersList.length}");
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     _subscription.cancel(); // 화면이 제거될 때 데이터 스냅샷 리스너를 해제합니다.
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("All Users"), // 화면 제목
//         actions: <Widget>[
//           IconButton(
//             icon: Icon(Icons.close),
//             onPressed: () async {
//               // 로그아웃 버튼 클릭 시 로그아웃 동작 수행
//               await firebaseAuth.signOut();
//               await googleSignIn.disconnect();
//               await googleSignIn.signOut();
//               print("Signed Out");
//               Navigator.of(context).pushAndRemoveUntil(
//                   MaterialPageRoute(builder: (context) => MyApp()),
//                       (Route<dynamic> route) => false);
//             },
//           )
//         ],
//       ),
//       body: usersList != null
//           ? Container(
//         child: ListView.builder(
//           itemCount: usersList.length,
//           itemBuilder: ((context, index) {
//             return ListTile(
//               leading: CircleAvatar(
//                 backgroundImage:
//                 NetworkImage(usersList[index].data['photoUrl']),
//               ),
//               title: Text(usersList[index].data['name'],
//                   style: TextStyle(
//                     color: Colors.black,
//                     fontWeight: FontWeight.bold,
//                   )),
//               subtitle: Text(usersList[index].data['emailId'],
//                   style: TextStyle(
//                     color: Colors.grey,
//                   )),
//               onTap: (() {
//                 // 사용자를 탭하면 해당 사용자와의 채팅 화면으로 이동합니다.
//                 Navigator.push(
//                     context,
//                     new MaterialPageRoute(
//                         builder: (context) => ChatScreen(
//                             name: usersList[index].data['name'],
//                             photoUrl: usersList[index].data['photoUrl'],
//                             receiverUid: usersList[index].data['uid'])));
//               }),
//             );
//           }),
//         ),
//       )
//           : Center(
//         child: CircularProgressIndicator(), // 사용자 목록을 로드하는 동안 로딩 스피너 표시
//       ),
//     );
//   }
// }
