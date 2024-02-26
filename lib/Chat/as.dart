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
//               //알림 온 시간 측정
//               final DateTime? lastMessageTime = lastMessageTimes[documentName];
//               if (lastMessageTime == null) {
//                 // 마지막 메시지 시간을 아직 가져오지 않았다면, 비동기로 가져옵니다.
//                 fetchLastMessage(documentName).then((timestamp) {
//                   if (mounted) { // 위젯이 아직 화면에 존재하는지 확인
//                     setState(() {
//                       lastMessageTimes[documentName] = timestamp;
//                     });
//                   }
//                 });
//               }
//               // 마지막 메시지 시간 또는 채팅방 생성 시간을 사용하여 시간 표시
//               final DateTime dateTime = lastMessageTime ?? userData['timestamp'].toDate();
//               final String timeAgo = getTimeAgo(dateTime);
//
//
//               // 로그인한 사람 이메일 확인
//               User? currentUser = FirebaseAuth.instance.currentUser;
//               String? currentUserEmail = currentUser?.email;
//
//               // 메시지 카운트 키 생성
//               String messageCountKey;
//               if (userData['helper_email'] == currentUserEmail) {
//                 messageCountKey = "$documentName-${userData['helper_email']}";
//               }
//               else if (userData['owner_email'] == currentUserEmail) {
//                 messageCountKey = "$documentName-${userData['owner_email']}";
//               }
//               // 메시지 카운트 가져오기
//               int messageCount = messageCounts[messageCountKey] ?? 0;
//
//               return Column(
//                 children: [
//                   if (userData['helper_email'] == currentUserEmail) // 조건부로 위젯 생성
//                     InkWell(
//                         child: Stack(
//                           children: <Widget>[
//                             // 메시지 카운트를 표시하는 배지 추가
//                             if (messageCount > 0) // messageCount는 현재 채팅방의 안 읽은 메시지 수
//                               Positioned(
//                                 top: 5,
//                                 right: 5,
//                                 child: Container(
//                                   padding: EdgeInsets.all(6),
//                                   decoration: BoxDecoration(
//                                     color: Colors.red, // 배지의 배경 색상
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   constraints: BoxConstraints(
//                                     minWidth: 24,
//                                     minHeight: 24,
//                                   ),
//                                   child: Text(
//                                     messageCount.toString(),
//                                     textAlign: TextAlign.center,
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                     )
//                   else if (userData['owner_email'] == currentUserEmail)
//                     InkWell(
//                             // 메시지 카운트를 표시하는 배지 추가
//                             if (messageCount > 0) // messageCount는 현재 채팅방의 안 읽은 메시지 수
//                               Positioned(
//                                 top: 5,
//                                 right: 5,
//                                 child: Container(
//                                   padding: EdgeInsets.all(6),
//                                   decoration: BoxDecoration(
//                                     color: Colors.red, // 배지의 배경 색상
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   constraints: BoxConstraints(
//                                     minWidth: 24,
//                                     minHeight: 24,
//                                   ),
//                                   child: Text(
//                                     messageCount.toString(),
//                                     textAlign: TextAlign.center,
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                     ),
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
