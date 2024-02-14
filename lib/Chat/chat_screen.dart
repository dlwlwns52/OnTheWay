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
//   // final String photoUrl;
//   final String receiverUid;
//
//   ChatScreen({
//     required this.name,
//     // required this.photoUrl,
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
//     _messageController = TextEditingController();
//     _initializeChatDetails();
//   }
//
// // 채팅에 필요한 초기 세부 정보를 설정하는 함수
//   Future<void> _initializeChatDetails() async {
//     try {
//       // 현재 로그인한 사용자의 UID를 가져옵니다.
//       var user = await _getUID();
//       // 발신자의 사진 URL과 이름을 Firestore에서 가져옵니다.
//       var senderSnapshot = await _getSenderPhotoUrl(user.uid);
//       // 수신자의 사진 URL과 이름을 Firestore에서 가져옵니다.
//       var receiverSnapshot = await _getReceiverPhotoUrl(widget.receiverUid);
//
//       // 가져온 정보를 바탕으로 상태를 업데이트합니다.
//       setState(() {
//         _senderUid = user.uid; // 발신자의 UID 설정
//         senderPhotoUrl = senderSnapshot['photoUrl']; // 발신자의 사진 URL 설정
//         senderName = senderSnapshot['name']; // 발신자의 이름 설정
//         receiverPhotoUrl = receiverSnapshot['photoUrl']; // 수신자의 사진 URL 설정
//         receiverName = receiverSnapshot['name']; // 수신자의 이름 설정
//       });
//     } catch (error) {
//       // 에러가 발생한 경우의 처리
//       // 에러 처리 로직을 여기에 추가
//     }
//   }
//
//
//
//
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
// // 사용자가 이미지를 선택하고 업로드하는 함수
//   Future<String> _pickImage() async {
//     final ImagePicker _picker = ImagePicker(); // ImagePicker 인스턴스 생성
//     final XFile? selectedImage = await _picker.pickImage(source: ImageSource.gallery); // 갤러리에서 이미지 선택
//
//     if (selectedImage != null) { // 선택된 이미지가 있는 경우
//       File imageFile = File(selectedImage.path); // 선택된 이미지의 파일 경로를 가져와 File 객체 생성
//       setState(() {
//         this.imageFile = imageFile; // 상태를 업데이트하여 선택된 이미지 표시
//       });
//
//       // Firebase Storage에 이미지를 저장하기 위한 참조 생성
//       Reference storageReference = FirebaseStorage.instance
//           .ref()
//           .child('images/${DateTime.now().millisecondsSinceEpoch}');
//
//       // 선택된 이미지 파일을 Firebase Storage에 업로드
//       UploadTask uploadTask = storageReference.putFile(imageFile);
//       TaskSnapshot taskSnapshot = await uploadTask; // 업로드 작업 완료 대기
//       String downloadUrl = await taskSnapshot.ref.getDownloadURL(); // 업로드된 이미지의 URL 획득
//
//       print("URL: $downloadUrl"); // 콘솔에 URL 출력
//       _uploadImageToDb(downloadUrl); // Firestore에 이미지 URL 업로드
//       return downloadUrl; // 업로드된 이미지의 URL 반환
//     }
//     return ''; // 이미지 선택이 없는 경우 빈 문자열 반환
//   }
//
//
//
//
// // Firebase Firestore에 이미지 메시지 정보를 업로드하는 함수
//   void _uploadImageToDb(String downloadUrl) {
//     // Message 객체를 생성하여 이미지 메시지 정보를 초기화
//     _message = Message.withoutMessage(
//       receiverUid: widget.receiverUid, // 수신자 UID
//       senderUid: _senderUid, // 발신자 UID
//       photoUrl: downloadUrl, // 업로드된 이미지의 URL
//       timestamp: FieldValue.serverTimestamp(), // 서버 시간을 기준으로 타임스탬프 설정
//       type: 'image', // 메시지 타입을 'image'로 설정
//     );
//
//     // Firestore에 저장할 메시지 정보를 Map 형식으로 준비
//     map['senderUid'] = _message.senderUid;
//     map['receiverUid'] = _message.receiverUid;
//     map['type'] = _message.type;
//     map['timestamp'] = _message.timestamp;
//     map['photoUrl'] = _message.photoUrl;
//
//     // 준비된 메시지 정보를 콘솔에 출력
//     print("Map : ${map}");
//
//     // 발신자의 UID와 수신자의 UID를 사용하여 Firestore의 경로 설정
//     _collectionReference = FirebaseFirestore.instance
//         .collection("messages")
//         .doc(_message.senderUid)
//         .collection(widget.receiverUid);
//
//     // Firestore에 메시지 정보를 추가하고 완료되면 콘솔에 메시지 출력
//     _collectionReference.add(map).whenComplete(() {
//       print("Messages added to db");
//     });
//
//     // 수신자의 UID와 발신자의 UID를 사용하여 Firestore의 경로 설정 (반대 경우)
//     _collectionReference = FirebaseFirestore.instance
//         .collection("messages")
//         .doc(widget.receiverUid)
//         .collection(_message.senderUid);
//
//     // Firestore에 메시지 정보를 추가하고 완료되면 콘솔에 메시지 출력 (반대 경우)
//     _collectionReference.add(map).whenComplete(() {
//       print("Messages added to db");
//     });
//   }
//
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
//   /*
//   채팅 메시지 목록 위젯
//   */
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
// // 채팅 레이아웃 생성
//   Widget buildChatLayout(QueryDocumentSnapshot<Map<String, dynamic>> snapshot) {
//     return Padding(
//       padding: const EdgeInsets.all(12.0),
//       child: Row(
//         // 보낸 사람이 본인인지 확인하여 채팅 방향을 결정합니다.
//         mainAxisAlignment: snapshot['senderUid'] == _senderUid
//             ? MainAxisAlignment.end
//             : MainAxisAlignment.start,
//         children: <Widget>[
//           // 프로필 사진을 표시합니다.
//           CircleAvatar(
//             backgroundImage: snapshot['senderUid'] == _senderUid
//                 ? (senderPhotoUrl == null
//                 ? AssetImage('assets/blankimage.png')
//                 : NetworkImage(senderPhotoUrl))
//                 : (receiverPhotoUrl == null
//                 ? AssetImage('assets/blankimage.png')
//                 : NetworkImage(receiverPhotoUrl)),
//             radius: 20.0,
//           ),
//           SizedBox(
//             width: 10.0,
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: <Widget>[
//               // 보낸 사람의 이름을 표시합니다.
//               Text(
//                 snapshot['senderUid'] == _senderUid
//                     ? (senderName ?? "")
//                     : (receiverName ?? ""),
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontSize: 16.0,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               // 메시지 유형에 따라 텍스트 또는 이미지를 표시합니다.
//               if (snapshot['type'] == 'text')
//                 Text(
//                   snapshot['message'],
//                   style: TextStyle(
//                     color: Colors.black,
//                     fontSize: 14.0,
//                   ),
//                 )
//               else
//                 InkWell(
//                   // 이미지를 탭하면 전체 화면 이미지를 표시합니다.
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => FullScreenImage(
//                           photoUrl: snapshot['photoUrl'],
//                         ),
//                       ),
//                     );
//                   },
//                   child: Hero(
//                     tag: snapshot['photoUrl'],
//                     child: FadeInImage(
//                       image: NetworkImage(snapshot['photoUrl']),
//                       placeholder: AssetImage('assets/blankimage.png'),
//                       width: 200.0,
//                       height: 200.0,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
