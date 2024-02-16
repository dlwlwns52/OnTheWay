import 'dart:io';

import 'package:OnTheWay/Chat/full_screen_image.dart';
import 'package:OnTheWay/Chat/models/message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';

class ChatScreen extends StatefulWidget {
  final String receiverName;
  final String senderName;
  final String receiverUid;
  final String documentName;  // 채팅방의 문서 이름
  // final String photoUrl;

  ChatScreen({
    required this.receiverName,
    required this.senderName,
    required this.receiverUid,
    required this.documentName,  // 생성자에 documentName 추가
    // required this.photoUrl,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<
      FormState>(); // 폼 상태를 관리하는 GlobalKey
  Map<String, dynamic> map = {}; // 메시지 맵
  late DocumentReference<Map<String, dynamic>> _documentReference; // 문서 참조
  late DocumentSnapshot<Map<String, dynamic>> documentSnapshot; // 문서 스냅샷
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance; // FirebaseAuth 인스턴스
  String? _senderUid; // 발신자 UID
  late File imageFile; // 이미지 파일
  late TextEditingController _messageController; // 메시지 입력 필드 컨트롤러

  // 추가된 변수 선언
  late String senderPhotoUrl; // 발신자 사진 URL
  late String senderName; // 발신자 이름
  late String receiverPhotoUrl; // 수신자 사진 URL
  late String receiverName; // 수신자 이름

  //색상 변환
  bool isFilled = false;


  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _messageController.addListener(_checkFieldsFilled);
    _initializeChatDetails();
    _markUnreadMessagesAsRead();
  }
  void _checkFieldsFilled() {
    setState(() {
      isFilled = _messageController.text.isNotEmpty;
    });
  }

// 채팅에 필요한 초기 세부 정보를 설정하는 함수
  Future<void> _initializeChatDetails() async {
    try {
      User? user = await _getUID();
      if (user != null && user.uid != null) {
        var senderSnapshot = await _getSenderPhotoUrl();
        var receiverSnapshot = await _getReceiverPhotoUrl();

        setState(() {
          _senderUid = user.uid; // 발신자의 UID 설정
          senderPhotoUrl = senderSnapshot; // 발신자의 사진
          senderName = widget.senderName; // 발신자의 이름 설정
          receiverPhotoUrl = receiverSnapshot; // 수신자의 사진
          receiverName = widget.receiverName; // 수신자의 이름 설정
        });
      } else {
        // 사용자 정보가 없는 경우의 처리 (예: 로그인 화면으로 이동)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사용자 정보가 없는 에러가 발생했습니다. 다시 로그인해 주세요',
            textAlign: TextAlign.center,)),
        );
      }
    } catch (error) {
      print("Error initializing chat details: $error");
    }
  }

  Future<void> _markUnreadMessagesAsRead() async {
    try {
      // 현재 사용자의 UID를 사용하여 아직 읽지 않은 메시지를 조회하고 업데이트합니다.
      QuerySnapshot<Map<String, dynamic>> unreadMessages = await FirebaseFirestore.instance
          .collection('ChatActions')
          .doc(widget.documentName)
          .collection('messages')
          .where('read', isEqualTo: false)
          .get();

      for (var message in unreadMessages.docs) {
        await message.reference.update({'read': true});
      }
    } catch (error) {
      print("Error marking messages as read: $error");
    }
  }


  @override
  void dispose() {
    super.dispose();
    // subscription?.cancel(); // 스트림 구독 취소
  }

/*
사진 설정
* */
// 사용자가 이미지를 선택하고 업로드하는 함수
  Future<String> _pickImage() async {
    final ImagePicker _picker = ImagePicker(); // ImagePicker 인스턴스 생성
    final XFile? selectedImage = await _picker.pickImage(
        source: ImageSource.gallery); // 갤러리에서 이미지 선택

    if (selectedImage != null) { // 선택된 이미지가 있는 경우
      File imageFile = File(
          selectedImage.path); // 선택된 이미지의 파일 경로를 가져와 File 객체 생성
      setState(() {
        this.imageFile = imageFile; // 상태를 업데이트하여 선택된 이미지 표시
      });

      // Firebase Storage에 이미지를 저장하기 위한 참조 생성
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('images/${DateTime
          .now()
          .millisecondsSinceEpoch}');

      // 선택된 이미지 파일을 Firebase Storage에 업로드
      UploadTask uploadTask = storageReference.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask; // 업로드 작업 완료 대기
      String downloadUrl = await taskSnapshot.ref
          .getDownloadURL(); // 업로드된 이미지의 URL 획득

      print("URL: $downloadUrl"); // 콘솔에 URL 출력
      _uploadImageToDb(downloadUrl); // Firestore에 이미지 URL 업로드
      return downloadUrl; // 업로드된 이미지의 URL 반환
    }
    return ''; // 이미지 선택이 없는 경우 빈 문자열 반환
  }

  void _uploadImageToDb(String downloadUrl) {
    DateTime now = DateTime.now();
    Timestamp timestamp = Timestamp.fromDate(now); // DateTime을 Timestamp로 변환

    if (_senderUid != null) {
      Message message = Message.withoutMessage(
        receiverUid: widget.receiverUid,
        senderUid: _senderUid!,
        photoUrl: downloadUrl,
        timestamp: timestamp,
        read: false,
        type: 'image',
      );

      // _addMessageToDb 함수를 사용하여 메시지 추가
      _addMessageToDb(message);
    }
  }

  // 현재까지 기본이미지 사용 -> 수정예정
  // 발신자 기본 사진 URL 반환
  Future<String> _getSenderPhotoUrl() async {
    // Firestore에서 사용자 정보를 가져오는 로직 대신 기본 이미지 경로 반환
    return 'assets/ava.png';
  }

  // 수신자 기본 사진 URL 반환
  Future<String> _getReceiverPhotoUrl() async {
    // Firestore에서 사용자 정보를 가져오는 로직 대신 기본 이미지 경로 반환
    return 'assets/ava.png';
  }


  /*
  텍스트 보내기
  * */
  void _addMessageToDb(Message message) async {
    Map<String, dynamic> messageMap = message.toMap();

    // 해당 채팅방의 messages 서브컬렉션 참조
    CollectionReference messages = FirebaseFirestore.instance
        .collection('ChatActions')
        .doc(widget.documentName)
        .collection('messages');


    // 메시지를 messages 서브컬렉션에 추가
    messages.add(messageMap).whenComplete(() {
      print("Message added to ChatActions");
    });
  }

  void _sendMessage() {
    // 입력된 텍스트 가져오기
    var text = _messageController.text;
    DateTime now = DateTime.now();
    Timestamp timestamp = Timestamp.fromDate(now); // DateTime을 Timestamp로 변환

    // 발신자 UID가 null이 아닌지 확인
    if (_senderUid != null) {
      // 텍스트 메시지 객체 생성
      Message message = Message(
        receiverUid: widget.receiverUid,
        senderUid: _senderUid!,
        message: text,
        timestamp: timestamp,
        read : false,
        type: 'text',
      );

      // _addMessageToDb 함수를 사용하여 메시지 추가
      _addMessageToDb(message);
    } else {
      // _senderUid가 null인 경우 적절한 처리를 할 수 있습니다.
      // 예를 들어, 사용자에게 오류 메시지를 표시하거나 로그인 화면으로 이동할 수 있습니다.
      print("Error: Sender UID is null");
    }
    // 메시지 입력 필드 초기화
    _messageController.clear();
  }


  Widget ChatMessagesListWidget() {
    return Flexible(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>( // 스트림 빌더를 사용하여 데이터 스트림을 처리
        stream: FirebaseFirestore.instance // 파이어스토어의 채팅 액션 컬렉션에서 메시지 스트림을 가져옴
            .collection('ChatActions')
            .doc(widget.documentName)
            .collection('messages')
            .orderBy('timestamp', descending: false)
            .snapshots(),
        builder: (context, snapshot) { // 스냅샷을 기반으로 UI를 빌드
          if (!snapshot.hasData) { // 데이터가 없는 경우 로딩 표시
            return Center(child: CircularProgressIndicator());
          }

          List<QueryDocumentSnapshot<Map<String, dynamic>>> messages = snapshot.data!.docs; // 메시지 목록을 가져옴
          return ListView.builder( // 리스트뷰를 사용하여 메시지 목록을 표시
            padding: EdgeInsets.all(10.0),
            itemCount: messages.length, // 메시지 수에 따라 아이템 수 설정
            itemBuilder: (context, index) { // 각 메시지에 대한 아이템을 빌드
              // 이전 메시지의 발신자와 현재 메시지의 발신자 비교하여 아바타 표시 여부 결정
              bool shouldDisplayAvatar = index == 0 || messages[index - 1]['senderUid'] != messages[index]['senderUid'];
              bool isRead = messages[index]['read'] as bool; // 'read' 필드 확인
              return chatMessageItem(messages[index], shouldDisplayAvatar, isRead); // 채팅 메시지 항목 위젯 반환
            },
          );
        },
      ),
    );
  }

  // 채팅 메시지 항목 생성
  Widget chatMessageItem(
      QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot,
      bool shouldDisplayAvatar, bool isRead) {
    return buildChatLayout(documentSnapshot, shouldDisplayAvatar, isRead);
  }

  // 현재 사용자 UID 가져오기
  Future<User?> _getUID() async {
    User? user = _firebaseAuth.currentUser;
    return user;
  }


  // Timestamp 객체를 입력받아 문자열로 변환하는 함수를 정의합니다.
  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp
        .toDate(); // Firebase의 Timestamp 객체를 Dart의 DateTime 객체로 변환합니다.
    // DateFormat을 사용하여 시간을 '오전/오후 h:mm' 형식으로 포매팅합니다.
    // 'ko' 로케일을 사용하여 한국어 형식(예: 오전 10:30)으로 출력합니다.
    String formattedTime = DateFormat('a h:mm', 'ko').format(dateTime);

    return formattedTime; // 포매팅된 시간 문자열을 반환합니다.
  }



  // 채팅 입력 위젯
  Widget ChatInputWidget() {
    return Container(
      height: 60.0, // 높이 조정
      margin: const EdgeInsets.symmetric(horizontal:8.0, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.image, color: Colors.grey[600], size:35,), // 아이콘 색상 조정
            onPressed: () {
              _pickImage(); // 이미지 선택
            },
          ),
          Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0), // 좌우 여백 추가
              child: TextFormField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "메시지 입력...",
                  contentPadding: EdgeInsets.symmetric(vertical: 9.0, horizontal: 15.0), // 패딩 조정
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0), // 둥근 모서리 적용
                    borderSide: BorderSide.none, // 외곽선 제거
                  ),
                  filled: true,
                  fillColor: Colors.grey[200], // 배경색 적용
                ),
              ),
            ),
          ),

          IconButton(
            icon: Icon(Icons.send,  color: isFilled ? Colors.orange :Colors.grey[600], size: 35,), // 아이콘 색상 조정
            onPressed: () {
              _sendMessage(); // 메시지 전송
            },
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),),
        // 채팅방 이름 표시
        // backgroundColor: Color(0XFF98ABEE),
        backgroundColor: Colors.white,
        elevation: 0,        iconTheme: IconThemeData(
          color: Colors.black, // 여기에서 원하는 색상을 설정합니다.
        ),
      ),
      body: Column(
        children: <Widget>[
          Divider(
            height: 2.0, // Divider의 높이 설정
            thickness: 3.0, // Divider의 두께 설정
            color: Colors.grey, // Divider의 색상 설정
          ),
          Expanded(
            child: _senderUid == null
                ? Container(
              child: CircularProgressIndicator(), // 로딩 표시
            )
                : Column(
              children: <Widget>[
                ChatMessagesListWidget(), // 채팅 메시지 목록 위젯
                // Divider(
                //   height: 20.0,
                //   color: Colors.black,
                // ),
                ChatInputWidget(), // 채팅 입력 위젯
                SizedBox(
                  height: 10.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


// 채팅 메시지 레이아웃을 구성하는 함수
  Widget buildChatLayout(QueryDocumentSnapshot<Map<String, dynamic>> snapshot, bool shouldDisplayAvatar, bool isRead ) {
    bool isSentByMe = snapshot['senderUid'] == _senderUid;
    bool isMessageRead = snapshot.data().containsKey('read') ? snapshot.data()['read'] as bool : false; // 읽음 상태

    return Row(

      mainAxisAlignment: isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: <Widget>[
        if (isSentByMe && !isMessageRead)
          Text('1', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),

        if (!isSentByMe )
          shouldDisplayAvatar
          ? CircleAvatar(
            backgroundImage: AssetImage('assets/ava.png'),
            backgroundColor: Colors.grey,
            radius: 25.0,
          )
              : Opacity( // 투명 위젯 사용
            opacity: 0.0,
            child: Container(
              width: 50.0, // CircleAvatar와 동일한 크기
              height: 50.0,
            ),
          ),

        SizedBox(width: 10.0),
          Column(
            crossAxisAlignment:  isSentByMe ? CrossAxisAlignment.start :CrossAxisAlignment.end , // Alignment 조정
            children: <Widget>[
              ChatBubble(
              clipper: isSentByMe
                  ? ChatBubbleClipper4(type: BubbleType.sendBubble)
                  : ChatBubbleClipper4(type: BubbleType.receiverBubble),
              alignment: isSentByMe ? Alignment.topRight : Alignment.topLeft,
              margin: EdgeInsets.only(top: 20),
              backGroundColor: isSentByMe ? Colors.orangeAccent : Colors.grey[300],
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery
                      .of(context)
                      .size
                      .width * 0.7,
                ),
                child: Column(
                  children: <Widget>[
                    if (snapshot['type'] == 'text')
                      Text(
                        snapshot['message'],
                        style: TextStyle(
                            color: isSentByMe ? Colors.black : Colors.black),
                      )
                    else
                      Image.network(
                          snapshot['photoUrl'], width: 200.0, height: 200.0),
                  ],
                ),
              ),
            ),
              SizedBox(height: 10,),
                Text(
                  _formatTimestamp(snapshot['timestamp']),
                  style: TextStyle(fontSize: 12.0, color: Colors.black87),
                ),
            ],
          ),

      ],
    );
  }
}