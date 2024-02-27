//
// //이 코드는 Flutter 애플리케이션에서 모든 사용자 목록을 표시하고 해당 사용자를 선택하여
// //채팅 화면으로 이동할 수 있는 화면을 구현한 것입니다.
//
// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:rxdart/rxdart.dart';
//
// import 'ChatScreen.dart';
//
//
// class AllUsersScreen extends StatefulWidget {
//   _AllUsersScreenState createState() => _AllUsersScreenState();
// }
//
// class _AllUsersScreenState extends State<AllUsersScreen>{
//
//   late StreamSubscription<dynamic> _chatActionsSubscription; // Firestore 스트림 구독을 위한 변수
//   List<DocumentSnapshot> acceptedChatActions = []; // 수락된 도움말 액션을 저장하는 변수
// // 채팅방 별 마지막 메시지 시간을 저장할 변수
//   Map<String, DateTime?> lastMessageTimes = {};
//   // 각 채팅방 및 사용자별 메시지 수를 저장할 Map
//   Map<String, int> messageCounts = {};
//   // 스트림 구독을 저장할 변수를 선언
//   late StreamSubscription<DocumentSnapshot> _messageCountSubscription;
//
//
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchChatActions();
//   }
//
//
//   @override
//   void dispose() {
//     _chatActionsSubscription.cancel(); // 스트림 구독 해제
//     _messageCountSubscription.cancel();
//     super.dispose();
//   }
//
//
//   // 이 함수는 현재 로그인한 사용자의 채팅방 목록을 가져오고, 각 채팅방의 최신 메시지 시간에 따라 목록을 정렬합니다.
//   Future<void> _fetchChatActions() async {
//     // 현재 로그인한 사용자 정보를 가져옵니다.
//     User? currentUser = FirebaseAuth.instance.currentUser;
//     // 사용자가 로그인하지 않았거나 이메일 정보가 없다면 함수를 종료합니다.
//     if (currentUser == null || currentUser.email == null) {
//       return;
//     }
//
//     // 현재 사용자의 이메일 주소를 가져옵니다.
//     String currentUserEmail = currentUser.email!;
//     // 'helper_email' 필드가 현재 사용자의 이메일과 일치하는 'ChatActions' 컬렉션의 문서 스트림을 가져옵니다.
//     var helperEmailStream = FirebaseFirestore.instance
//         .collection('ChatActions')
//         .where('response', isEqualTo: 'accepted')
//         .where('helper_email', isEqualTo: currentUserEmail)
//         .snapshots();
//
//     // 'owner_email' 필드가 현재 사용자의 이메일과 일치하는 'ChatActions' 컬렉션의 문서 스트림을 가져옵니다.
//     var ownerEmailStream = FirebaseFirestore.instance
//         .collection('ChatActions')
//         .where('response', isEqualTo: 'accepted')
//         .where('owner_email', isEqualTo: currentUserEmail)
//         .snapshots();
//
//     // 두 스트림을 결합하여 채팅방 목록을 생성합니다.
//     _chatActionsSubscription = Rx.combineLatest2(
//         helperEmailStream, ownerEmailStream, (QuerySnapshot helperSnapshot, QuerySnapshot ownerSnapshot) async {
//       // helperEmailStream과 ownerEmailStream에서 받은 문서들을 결합합니다.
//       var combinedDocs = {...helperSnapshot.docs, ...ownerSnapshot.docs}.toList();
//
//       // 각 채팅방의 마지막 메시지 시간을 비동기적으로 가져오는 작업 목록을 생성합니다.
//       var fetchLastMessageFutures = <Future<void>>[];
//       for (var doc in combinedDocs) {
//         Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
//         _updateMessageCount(doc.id, userData);
//
//         var docName = doc.id;
//         fetchLastMessageFutures.add(
//           fetchLastMessage(docName).then((timestamp) {
//             lastMessageTimes[docName] = timestamp ?? doc.get('timestamp').toDate();
//           }),
//         );
//       }
//
//       // 모든 채팅방의 마지막 메시지 시간을 가져온 후에 목록을 정렬합니다.
//       await Future.wait(fetchLastMessageFutures);
//       combinedDocs.sort((a, b) => lastMessageTimes[b.id]!.compareTo(lastMessageTimes[a.id]!));
//
//       // 위젯이 화면에 여전히 존재하는 경우에만 상태를 업데이트합니다.
//       if (mounted) {
//         setState(() {
//           acceptedChatActions = combinedDocs;
//         });
//       }
//     }
//     ).listen(
//           (data) {},
//       onError: (error) {
//         // 스트림에서 오류가 발생한 경우 로그를 출력합니다.
//         print("An error occurred: $error");
//       },
//     );
//   }
//
//
//   //마지막 메시지 보낸 시간 확인
//   Future<DateTime?> fetchLastMessage(String documentName) async {
//     try {
//       // 채팅방의 마지막 메시지를 검색하기 위한 쿼리
//       QuerySnapshot<Map<String, dynamic>> lastMessageSnapshot = await FirebaseFirestore.instance
//           .collection('ChatActions')
//           .doc(documentName)
//           .collection('messages')
//           .orderBy('timestamp', descending: true)
//           .limit(1)
//           .get();
//
//       // 검색된 문서가 있는지 확인하고, 있다면 마지막 메시지의 타임스탬프를 가져옴
//       if (lastMessageSnapshot.docs.isNotEmpty) {
//         Timestamp lastMessageTimestamp = lastMessageSnapshot.docs.first.data()['timestamp'];
//         return lastMessageTimestamp.toDate();
//       }
//     }
//     catch (error) {
//       // 에러 처리 로직
//       // 예: print("Error fetching last message: $error");
//     }
//   }
//
//   Future<void> _updateMessageCount(documentName, userData) async {
//     User? currentUser = FirebaseAuth.instance.currentUser;
//     String? currentUserEmail = currentUser?.email;
//     String? helperNickname = userData['helper_email_nickname'];
//     String? ownerNickname = userData['owner_email_nickname'];
//     String helperMessageCountKey = "$documentName-${userData['helper_email']}";
//     String ownerMessageCountKey = "$documentName-${userData['owner_email']}";
//
//     try {
//       if (userData['helper_email'] == currentUserEmail) {
//         _messageCountSubscription = FirebaseFirestore.instance
//             .collection('ChatActions')
//             .doc(documentName)
//             .snapshots()
//             .listen((snapshot) {
//           if (snapshot.exists) {
//             var data = snapshot.data() as Map<String, dynamic>;
//             if (this.mounted) {
//               setState(() {
//                 messageCounts[helperMessageCountKey] = data['messageCount_$helperNickname'] ?? 0;
//               });
//             }
//           }
//         });
//       } else if (userData['owner_email'] == currentUserEmail) {
//         _messageCountSubscription = FirebaseFirestore.instance
//             .collection('ChatActions')
//             .doc(documentName)
//             .snapshots()
//             .listen((snapshot) {
//           if (snapshot.exists) {
//             var data = snapshot.data() as Map<String, dynamic>;
//             if (this.mounted) {
//               setState(() {
//                 messageCounts[ownerMessageCountKey] = data['messageCount_$ownerNickname'] ?? 0;
//               });
//             }
//           }
//         });
//       }
//     } catch (error) {
//       print("Error updating message count: $error");
//     }
//   }
//
//   // 시간을 '분 전' 형식으로 변환하는 함수
//   String getTimeAgo(DateTime dateTime) {
//     final Duration difference = DateTime.now().difference(dateTime);
//     if (difference.inMinutes <= 1){
//       return '방금 전';
//     }
//     if ( 1 < difference.inMinutes  && difference.inMinutes < 60) {
//       return '${difference.inMinutes}분 전';
//     }
//     else if (difference.inHours < 24) {
//       return '${difference.inHours}시간 전';
//     }
//     else {
//       return '${difference.inDays}일 전';
//     }
//   }
//
//   // helper의 isDeleted_ 활성화
//   Future<void> helperDeleteChatRoom(String documentId, String helperNickname) async {
//     await FirebaseFirestore.instance.collection('ChatActions').doc(documentId).update({
//       'isDeleted_$helperNickname': true
//     });
//   }
//
//   //owner의 isDeleted_ 활성화
//   Future<void> ownerDeleteChatRoom(String documentId, String ownerNickname) async {
//     await FirebaseFirestore.instance.collection('ChatActions').doc(documentId).update({
//       'isDeleted_$ownerNickname' : true
//     });
//   }
//
//   //helper의 isDeleted_ 와 owner의 isDeleted_ 두개다 모두 활성화 시 문서삭제
//   Future<void> deleteChatRoomIfBothDeleted(String documentId, String helperNickname, String ownerNickname) async {
//     // 채팅방 문서 참조
//     DocumentReference chatRoomRef = FirebaseFirestore.instance.collection('ChatActions').doc(documentId);
//
//     // 채팅방 문서 가져오기
//     DocumentSnapshot chatRoomSnapshot = await chatRoomRef.get();
//
//     if (chatRoomSnapshot.exists) {
//       Map<String, dynamic> chatRoomData = chatRoomSnapshot.data() as Map<String, dynamic>;
//
//       // 두 사용자 모두 채팅방을 삭제했는지 확인
//       bool isHelperDeleted = chatRoomData['isDeleted_$helperNickname'] ?? false;
//       bool isOwnerDeleted = chatRoomData['isDeleted_$ownerNickname'] ?? false;
//       print(isHelperDeleted);
//       if (isHelperDeleted && isOwnerDeleted) {
//         // 두 사용자 모두 채팅방을 삭제했다면 문서 삭제
//         await chatRoomRef.delete();
//       }
//     }
//   }
//
//
//   // helper 채팅방 나가기 dialog
//   void helperShowExitChatRoomDialog(BuildContext context, String documentId, String ownerNickname, String helperNickname) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15.0),
//           ),
//           title: Text(
//             '채팅방 나가기',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           content: Text(
//             '\'나가기\'를 누르시면 대화내용 및 채팅 목록이 모두 삭제됩니다.',
//             style: TextStyle(
//               color: Colors.black87,
//             ),
//           ),
//           actions: <Widget>[
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 primary: Colors.orangeAccent,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: Text(
//                 '나가기',
//                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//               onPressed: () {
//                 // 여기에 '나가기' 버튼을 눌렀을 때의 로직을 구현하세요.
//                 helperDeleteChatRoom(documentId, helperNickname);
//                 deleteChatRoomIfBothDeleted(documentId, ownerNickname, helperNickname);
//                 Navigator.of(context).pop();
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text(
//                       "채팅방이 삭제되었습니다.",
//                       textAlign: TextAlign.center,
//                     ),
//                     duration: Duration(seconds: 1),
//                   ),
//                 );
//               },
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 primary: Colors.grey,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: Text(
//                 '취소',
//                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//
// // owner 채팅방 나가기 dialog
//   void ownerShowExitChatRoomDialog(BuildContext context, String documentId, String ownerNickname, String helperNickname) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15.0),
//           ),
//           title: Text(
//             '채팅방 나가기',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               color: Colors.black,
//             ),
//           ),
//           content: Text(
//             '\'나가기\'를 누르시면 대화내용 및 채팅 목록이 모두 삭제됩니다.',
//             style: TextStyle(
//               color: Colors.black87,
//             ),
//           ),
//           actions: <Widget>[
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 primary: Colors.orangeAccent,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: Text(
//                 '나가기',
//                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//               onPressed: () {
//                 // 여기에 '나가기' 버튼을 눌렀을 때의 로직을 구현하세요.
//                 ownerDeleteChatRoom(documentId, ownerNickname);
//                 deleteChatRoomIfBothDeleted(documentId, ownerNickname, helperNickname);
//                 Navigator.of(context).pop();
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text(
//                       "채팅방이 삭제되었습니다.",
//                       textAlign: TextAlign.center,
//                     ),
//                     duration: Duration(seconds: 1),
//                   ),
//                 );
//               },
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 primary: Colors.grey,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//               child: Text(
//                 '취소',
//                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           backgroundColor: Color(0xFFFF8B13),
//           elevation: 0,
//           title: Text("채팅",
//             style: TextStyle(fontWeight: FontWeight.bold),),
//           actions: <Widget>[
//           ],
//
//         ),
//
//         body: acceptedChatActions != null
//             ? Container(
//           child: ListView.builder(
//             itemCount: acceptedChatActions.length,
//             itemBuilder: ((context, index) {
//               DocumentSnapshot userDoc = acceptedChatActions[index];
//               Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
//               final DocumentSnapshot doc = acceptedChatActions[index];
//               final String documentName = userDoc.id; // 채팅방 문서 ID
//
//               // 로그인한 사람 이메일 확인
//               User? currentUser = FirebaseAuth.instance.currentUser;
//               String? currentUserEmail = currentUser?.email;
//
//               return Column(
//                 children: [
//                   if (userData['helper_email'] == currentUserEmail) // 조건부로 위젯 생성
//                    ...
//                   else if (userData['owner_email'] == currentUserEmail)
//                    ...
//                   // Divider(thickness: 1),
//                 ],
//               );
//             }),
//           ),
//         )
//             : Center(
//           child: CircularProgressIndicator(), // 로딩 중 표시
//         ));
//   }
// }
//
