// import 'dart:io';
//
// import 'package:OnTheWay/Chat/full_screen_image.dart';
// import 'package:OnTheWay/Chat/models/message.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:async';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
//
// class ChatScreen extends StatefulWidget {
//   final String name;
//   final String photoUrl;
//   final String receiverUid;
//
//   ChatScreen({
//     required this.name,
//     required this.photoUrl,
//     required this.receiverUid,
//   });
//
//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }
//
// class _ChatScreenState extends State<ChatScreen> {
//   late Message _message; // 채팅 메시지 객체
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // 폼 상태를 관리하는 GlobalKey
//   final Map<String, dynamic> map = {}; // 메시지 맵
//   late CollectionReference<Map<String, dynamic>> _collectionReference; // 파이어스토어 컬렉션 참조
//   late DocumentReference<Map<String, dynamic>> _receiverDocumentReference; // 수신자 문서 참조
//   late DocumentReference<Map<String, dynamic>> _senderDocumentReference; // 발신자 문서 참조
//   late DocumentReference<Map<String, dynamic>> _documentReference; // 문서 참조
//   late DocumentSnapshot<Map<String, dynamic>> documentSnapshot; // 문서 스냅샷
//   final FirebaseAuth _firebaseAuth = FirebaseAuth.instance; // FirebaseAuth 인스턴스
//   late String _senderUid; // 발신자 UID
//   late File imageFile; // 이미지 파일
//   late Reference _storageReference; // Firebase Storage 참조
//   late TextEditingController _messageController; // 메시지 입력 필드 컨트롤러
//
//   @override
//   void initState() {
//     super.initState();
//     _messageController = TextEditingController(); // 컨트롤러 초기화
//     _getUID().then((user) { // 발신자 UID 가져오기
//       setState(() {
//         _senderUid = user.uid; // 발신자 UID 설정
//         print("sender uid : $_senderUid");
//         _getSenderPhotoUrl(_senderUid).then((snapshot) { // 발신자의 사진 URL 가져오기
//           setState(() {
//             senderPhotoUrl = snapshot['photoUrl']; // 발신자 사진 URL 설정
//             senderName = snapshot['name']; // 발신자 이름 설정
//           });
//         });
//         _getReceiverPhotoUrl(widget.receiverUid).then((snapshot) { // 수신자의 사진 URL 가져오기
//           setState(() {
//             receiverPhotoUrl = snapshot['photoUrl']; // 수신자 사진 URL 설정
//             receiverName = snapshot['name']; // 수신자 이름 설정
//           });
//         });
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     subscription?.cancel(); // 스트림 구독 취소
//   }
//
//   // 파이어스토어에 메시지 추가
//   void _addMessageToDb(Message message) async {
//     print("Message : ${message.message}");
//     map = message.toMap(); // 메시지를 맵으로 변환
//
//     print("Map : ${map}");
//     _collectionReference = FirebaseFirestore.instance
//         .collection("messages")
//         .doc(message.senderUid)
//         .collection(widget.receiverUid);
//
//     _collectionReference.add(map).whenComplete(() {
//       print("Messages added to db");
//     });
//
//     _collectionReference = FirebaseFirestore.instance
//         .collection("messages")
//         .doc(widget.receiverUid)
//         .collection(message.senderUid);
//
//     _collectionReference.add(map).whenComplete(() {
//       print("Messages added to db");
//     });
//
//     _messageController.text = ""; // 메시지 입력 필드 초기화
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.name), // 채팅방 이름 표시
//       ),
//       body: Form(
//         key: _formKey,
//         child: _senderUid == null
//             ? Container(
//           child: CircularProgressIndicator(), // 로딩 표시
//         )
//             : Column(
//           children: <Widget>[
//             ChatMessagesListWidget(), // 채팅 메시지 목록 위젯
//             Divider(
//               height: 20.0,
//               color: Colors.black,
//             ),
//             ChatInputWidget(), // 채팅 입력 위젯
//             SizedBox(
//               height: 10.0,
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   // 채팅 입력 위젯
//   Widget ChatInputWidget() {
//     return Container(
//       height: 55.0,
//       margin: const EdgeInsets.symmetric(horizontal: 8.0),
//       child: Row(
//         children: <Widget>[
//           Container(
//             margin: const EdgeInsets.symmetric(horizontal: 4.0),
//             child: IconButton(
//               splashColor: Colors.white,
//               icon: Icon(
//                 Icons.camera_alt,
//                 color: Colors.black,
//               ),
//               onPressed: () {
//                 _pickImage(); // 이미지 선택
//               },
//             ),
//           ),
//           Flexible(
//             child: TextFormField(
//               validator: (String? input) {
//                 if (input == null || input.isEmpty) {
//                   return "Please enter a message"; // 메시지를 입력하라는 경고
//                 }
//                 return null;
//               },
//               controller: _messageController,
//               decoration: InputDecoration(
//                 hintText: "Enter message...",
//                 labelText: "Message",
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(5.0),
//                 ),
//               ),
//               onFieldSubmitted: (value) {
//                 _messageController.text = value;
//               },
//             ),
//           ),
//           Container(
//             margin: const EdgeInsets.symmetric(horizontal: 4.0),
//             child: IconButton(
//               splashColor: Colors.white,
//               icon: Icon(
//                 Icons.send,
//                 color: Colors.black,
//               ),
//               onPressed: () {
//                 if (_formKey.currentState?.validate() == true) {
//                   _sendMessage(); // 메시지 전송
//                 }
//               },
//             ),
//           )
//         ],
//       ),
//     );
//   }
//
//   // 이미지 선택
//   Future<String> _pickImage() async {
//     var selectedImage =
//     await ImagePicker.pickImage(source: ImageSource.gallery);
//     setState(() {
//       imageFile = selectedImage; // 이미지 파일 설정
//     });
//     _storageReference = FirebaseStorage.instance
//         .ref()
//         .child('${DateTime.now().millisecondsSinceEpoch}');
//     StorageUploadTask storageUploadTask = _storageReference.putFile(imageFile);
//     var url =
//     await (await storageUploadTask.onComplete).ref.getDownloadURL();
//
//     print("URL: $url");
//     _uploadImageToDb(url); // 데이터베이스에 이미지 업로드
//     return url;
//   }
//
//   // 이미지 데이터베이스에 업로드
//   void _uploadImageToDb(String downloadUrl) {
//     _message = Message.withoutMessage(
//       receiverUid: widget.receiverUid,
//       senderUid: _senderUid,
//       photoUrl: downloadUrl,
//       timestamp: FieldValue.serverTimestamp(),
//       type: 'image',
//     );
//     map['senderUid'] = _message.senderUid;
//     map['receiverUid'] = _message.receiverUid;
//     map['type'] = _message.type;
//     map['timestamp'] = _message.timestamp;
//     map['photoUrl'] = _message.photoUrl;
//
//     print("Map : ${map}");
//     _collectionReference = FirebaseFirestore.instance
//         .collection("messages")
//         .doc(_message.senderUid)
//         .collection(widget.receiverUid);
//
//     _collectionReference.add(map).whenComplete(() {
//       print("Messages added to db");
//     });
//
//     _collectionReference = FirebaseFirestore.instance
//         .collection("messages")
//         .doc(widget.receiverUid)
//         .collection(_message.senderUid);
//
//     _collectionReference.add(map).whenComplete(() {
//       print("Messages added to db");
//     });
//   }
//
//   // 메시지 전송
//   void _sendMessage() async {
//     print("Inside send message");
//     var text = _messageController.text;
//     print(text);
//     _message = Message(
//       receiverUid: widget.receiverUid,
//       senderUid: _senderUid,
//       message: text,
//       timestamp: FieldValue.serverTimestamp(),
//       type: 'text',
//     );
//     print(
//         "receiverUid: ${widget.receiverUid} , senderUid : $_senderUid , message: $text");
//     print(
//         "timestamp: ${DateTime.now().millisecond}, type: ${text != null ? 'text' : 'image'}");
//     _addMessageToDb(_message);
//   }
//
//   // 현재 사용자 UID 가져오기
//   Future<User> _getUID() async {
//     User user = await _firebaseAuth.currentUser!;
//     return user;
//   }
//
//   // 발신자 사진 URL 가져오기
//   Future<DocumentSnapshot<Map<String, dynamic>>> _getSenderPhotoUrl(String uid) {
//     var senderDocumentSnapshot =
//     FirebaseFirestore.instance.collection('users').doc(uid).get();
//     return senderDocumentSnapshot;
//   }
//
//   // 수신자 사진 URL 가져오기
//   Future<DocumentSnapshot<Map<String, dynamic>>> _getReceiverPhotoUrl(String uid) {
//     var receiverDocumentSnapshot =
//     FirebaseFirestore.instance.collection('users').doc(uid).get();
//     return receiverDocumentSnapshot;
//   }
//
//   // 채팅 메시지 목록 위젯
//   Widget ChatMessagesListWidget() {
//     print("SENDERUID : $_senderUid");
//     return Flexible(
//       child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//         stream: FirebaseFirestore.instance
//             .collection('messages')
//             .doc(_senderUid)
//             .collection(widget.receiverUid)
//             .orderBy('timestamp', descending: false)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return Center(
//               child: CircularProgressIndicator(), // 로딩 표시
//             );
//           } else {
//             var listItem = snapshot.data!.docs;
//             return ListView.builder(
//               padding: EdgeInsets.all(10.0),
//               itemBuilder: (context, index) =>
//                   chatMessageItem(snapshot.data!.docs[index]), // 채팅 메시지 항목 생성
//               itemCount: snapshot.data!.docs.length,
//             );
//           }
//         },
//       ),
//     );
//   }
//
//   // 채팅 메시지 항목 생성
//   Widget chatMessageItem(QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot) {
//     return buildChatLayout(documentSnapshot);
//   }
//
//   // 채팅 레이아웃 생성
//   Widget buildChatLayout(QueryDocumentSnapshot<Map<String, dynamic>> snapshot) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.start,
//       children: <Widget>[
//         Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Row(
//             mainAxisAlignment: snapshot['senderUid'] == _senderUid
//                 ? MainAxisAlignment.end
//                 : MainAxisAlignment.start,
//             children: <Widget>[
//               snapshot['senderUid'] == _senderUid
//                   ? CircleAvatar(
//                 backgroundImage: senderPhotoUrl == null
//                     ? AssetImage('assets/blankimage.png')
//                     : NetworkImage(senderPhotoUrl),
//                 radius: 20.0,
//               )
//                   : CircleAvatar(
//                 backgroundImage: receiverPhotoUrl == null
//                     ? AssetImage('assets/blankimage.png')
//                     : NetworkImage(receiverPhotoUrl),
//                 radius: 20.0,
//               ),
//               SizedBox(
//                 width: 10.0,
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: <Widget>[
//                   snapshot['senderUid'] == _senderUid
//                       ? Text(
//                     senderName == null ? "" : senderName,
//                     style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 16.0,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   )
//                       : Text(
//                     receiverName == null ? "" : receiverName,
//                     style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 16.0,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   snapshot['type'] == 'text'
//                       ? Text(
//                     snapshot['message'],
//                     style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 14.0,
//                     ),
//                   )
//                       : InkWell(
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => FullScreenImage(
//                             photoUrl: snapshot['photoUrl'],
//                           ),
//                         ),
//                       );
//                     },
//                     child: Hero(
//                       tag: snapshot['photoUrl'],
//                       child: FadeInImage(
//                         image: NetworkImage(snapshot['photoUrl']),
//                         placeholder: AssetImage('assets/blankimage.png'),
//                         width: 200.0,
//                         height: 200.0,
//                       ),
//                     ),
//                   ),
//                 ],
//               )
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
