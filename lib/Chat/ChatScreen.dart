import 'dart:io';

import 'package:OnTheWay/Chat/FullScreenImage.dart';
import 'package:OnTheWay/Chat/message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

import '../Map/TMapView.dart';

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
  late DocumentSnapshot<Map<String, dynamic>> documentSnapshot; // 문서 스냅샷
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance; // FirebaseAuth 인스턴스
  String? _senderUid; // 발신자 UID
  late File imageFile; // 이미지 파일
  List<File> imageFiles = [];
  List<String> tmapDirections = [];

  late TextEditingController _messageController; // 메시지 입력 필드 컨트롤러

  // 추가된 변수 선언
  late String senderPhotoUrl; // 발신자 사진 URL
  late String senderName; // 발신자 이름
  late String receiverPhotoUrl; // 수신자 사진 URL
  late String receiverName; // 수신자 이름

  //색상 변환
  bool isFilled = false;
  final ScrollController _scrollController = ScrollController();





  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _messageController.addListener(_checkFieldsFilled);
    _initializeChatDetails();
    _checkAndUpdateMessageReadStatus();
    _updateUserStatusInChatRoom(true); // 채팅방에 들어갔음을 업데이트
  }

  @override
  void dispose() {
    _updateUserStatusInChatRoom(false); // 채팅방에서 나갔음을 업데이트
    _scrollController.dispose(); // 스크롤 컨트롤러 해제
    super.dispose();
    // subscription?.cancel(); // 스트림 구독 취소
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


  //채팅방 들어오는 여부에 따라 true 또는 false로 업데이트
  Future<void> _updateUserStatusInChatRoom(bool isInChatRoom) async {
    if (widget.receiverName != null) {
      await FirebaseFirestore.instance
          .collection('userStatus') // 별도의 'userStatus' 컬렉션 사용
          .doc(widget.senderName) // 사용자의 UID를 문서 ID로 사용
          .set({
          'isInChatRoom': isInChatRoom,
          'timestamp': DateTime.timestamp()
          });
    }
  }


//
// 상대방의 채팅방 상태를 확인하는 함수
  Future<void> _checkAndUpdateMessageReadStatus() async {
    // 파이어스토어에서 상대방의 사용자 상태 문서를 가져옵니다.
    DocumentSnapshot userStatusSnapshot = await FirebaseFirestore.instance
        .collection('userStatus')
        .doc(widget.receiverName)
        .get();

    // 문서가 존재하는지 확인합니다.
    if (userStatusSnapshot.exists) {
      // 문서 데이터를 Map<String, dynamic>으로 캐스팅합니다.
      Map<String, dynamic> userStatusData = userStatusSnapshot.data() as Map<String, dynamic>;
      // 사용자가 채팅방에 있는지 여부를 확인합니다.
      bool isInChatRoom = userStatusData['isInChatRoom'] ?? false;
      // 상대방이 채팅방에 있으면, 아직 읽지 않은 모든 메시지를 '읽음'으로 표시합니다.
      if (isInChatRoom) {
        print(widget.receiverName);
        _markUnreadMessagesAsRead();
      }
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

      // read로 바뀌면 안읽은 메시지 0으로 초기화
      await FirebaseFirestore.instance
          .collection('ChatActions')
          .doc(widget.documentName)
          .update({'messageCount_$senderName': 0});

    } catch (error) {
      print("Error marking messages as read: $error");
    }
  }


  // 채팅방 길찾기 기능
  Future<void> _tmapDirections() async {
    try {
      DocumentSnapshot tmapDirectionsSnapshot = await FirebaseFirestore.instance
          .collection('ChatActions')
          .doc(widget.documentName)
          .get();

      String currenLocation = tmapDirectionsSnapshot.get('currentLocation');
      String storeLocation = tmapDirectionsSnapshot.get('storeLocation');
      tmapDirections.add(currenLocation);
      tmapDirections.add(storeLocation);

    } catch (error) {
      print("Error marking messages as read: $error");
    }
  }



/*
사진 설정
* */
// // 사용자가 이미지를 선택하고 업로드하는 함수
  Future<void> _pickImageAndUpload() async {
    List<String> downloadUrls = (await _pickImage()) as List<String>; // 이미지를 선택하고 업로드한 후, 업로드된 이미지의 URL 리스트를 받아옵니다.
    for (String downloadUrl in downloadUrls) {
      _uploadImageToDb(downloadUrl); // 각 이미지 URL을 Firestore 데이터베이스에 업로드합니다.
    }
  }


// 비동기 함수로 이미지를 선택하고 업로드하는 과정을 처리합니다.
  Future<List<String>> _pickImage() async {
    final ImagePicker _picker = ImagePicker(); // ImagePicker 객체를 생성합니다.
    final List<XFile>? selectedImages = await _picker.pickMultiImage(); // 사용자가 여러 이미지를 선택할 수 있게 합니다.
    List<String> uploadImageUrls = []; // 업로드된 이미지의 URL들을 저장할 리스트입니다.

    // 선택된 이미지들이 있는지 확인합니다.
    if (selectedImages != null && selectedImages.isNotEmpty) {
      // 선택된 이미지 파일들을 File 타입으로 변환합니다.
      List<File> imageFiles = selectedImages.map((xFile) => File(xFile.path)).toList();

      // 선택된 이미지를 보여주고 업로드를 진행할지 결정하는 UI
      List<String>? result = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0), // 대화상자 모서리를 둥글게 합니다.
          ),
          title: Text('사진 확인',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87),
            textAlign: TextAlign.center,),
          content: Container(
            height: 300,
            width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                children: imageFiles.map((file) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25.0), // 이미지 모서리를 둥글게 합니다.
                    child: Image.file(file, fit: BoxFit.cover), // 이미지를 화면에 맞춰 표시합니다.
                  ),
                )).toList(),
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            ElevatedButton.icon(
              icon: Icon(Icons.send, color: Colors.white),
              label: Text('보내기'),
              style: ElevatedButton.styleFrom(
                primary: Colors.orangeAccent, // 버튼 색상을 오렌지색으로 설정합니다.
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // 버튼 모서리를 둥글게 합니다.
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                for (var imageFile in imageFiles) {
                  // Firebase Storage에 이미지를 업로드합니다.
                  Reference storageReference = FirebaseStorage.instance
                      .ref()
                      .child('images/${DateTime.now().millisecondsSinceEpoch}');
                  UploadTask uploadTask = storageReference.putFile(imageFile);
                  TaskSnapshot taskSnapshot = await uploadTask;
                  String downloadUrl = await taskSnapshot.ref.getDownloadURL(); // 업로드된 이미지의 URL을 가져옵니다.
                  uploadImageUrls.add(downloadUrl); // 가져온 URL을 리스트에 추가합니다.
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(
                      "이미지가 전송되고 있습니다. 잠시만 기다려 주세요.",
                      textAlign: TextAlign.center,
                    ),
                    duration: Duration(seconds: 1),
                  ),
                );
                Navigator.of(context).pop(uploadImageUrls); // 업로드된 이미지 URL 리스트를 반환합니다.
              },
            ),

            ElevatedButton.icon(
              icon: Icon(Icons.cancel, color: Colors.white),
              label: Text('취소'),
              style: ElevatedButton.styleFrom(
                primary: Colors.grey, // 버튼 색상을 회색으로 설정합니다.
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // 버튼 모서리를 둥글게 합니다.
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () => Navigator.of(context).pop(), // 대화상자를 닫습니다.
            ),

          ],
        ),
      );
      return result ?? []; // 대화상자로부터 반환된 결과를 반환하거나, 결과가 없으면 빈 리스트를 반환합니다.
    }
    return uploadImageUrls; // 선택된 이미지가 없으면 빈 리스트를 반환합니다.
  }




  //이미지 파이어스토어에 저장
  void _uploadImageToDb(String downloadUrl) {
    DateTime now = DateTime.now();
    Timestamp timestamp = Timestamp.fromDate(now); // DateTime을 Timestamp로 변환

    if (_senderUid != null) {
      Message message = Message.withoutMessage(
        receiverName : widget.receiverName,
        senderName : widget.senderName,
        receiverUid: widget.receiverUid,
        senderUid: _senderUid!,
        photoUrl: downloadUrl,
        timestamp: timestamp,
        message: '사진',
        read: false,
        isDeleted: false,
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
    messages.add(messageMap).whenComplete(() async{
      FirebaseFirestore.instance.collection('ChatActions').doc(widget.documentName).update({
        'lastMessage': message.message,
      });


      //상대방의 userStatus를 확인하고 messageCount를 업데이트합니다.
      DocumentReference userStatusRef = FirebaseFirestore.instance
        .collection('userStatus')
        .doc(widget.receiverName);

      //메시지 온 횟수 추적
      DocumentReference userMessageCount = FirebaseFirestore.instance
          .collection('ChatActions')
          .doc(widget.documentName);

      DocumentSnapshot userStatusSnapshot = await userStatusRef.get();
      DocumentSnapshot userCountSnapshot = await userMessageCount.get();

      if (userStatusSnapshot.exists){
        var statusData = userStatusSnapshot.data() as Map<String, dynamic>; //타입캐스팅
        var countData = userCountSnapshot.data() as Map<String, dynamic>; //타입캐스팅
        bool isRead = statusData['read'] ?? false;
        if(!isRead){//false인 경우 즉 상대방이 채팅에 없을 경우 messageCount 증가
          int messageCount = countData['messageCount_$receiverName'] ?? 0;
          userMessageCount.update({'messageCount_$receiverName': messageCount + 1});
        }
      }
    });
  }


  void _sendMessage() {
    // 입력된 텍스트 가져오기
    var text = _messageController.text.trim(); // 공백 제거
    DateTime now = DateTime.now();
    Timestamp timestamp = Timestamp.fromDate(now); // DateTime을 Timestamp로 변환

    // 공백일시 안보내짐
    if (text.isEmpty){
      return;
    }
    // 발신자 UID가 null이 아닌지 확인
    if (_senderUid != null) {
      // 텍스트 메시지 객체 생성
      Message message = Message(
        receiverName : widget.receiverName,
        senderName : widget.senderName,
        receiverUid: widget.receiverUid,
        senderUid: _senderUid!,
        message: text,
        timestamp: timestamp,
        read : false,
        type : 'text',
        isDeleted : false,
      );

      _checkAndUpdateMessageReadStatus();
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


  // 날짜 표시를 위한 위젯
  Widget buildDateSeparator(String dateString) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          dateString,
          style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  //메시지 및 이미지 삭제
  void _deleteMessageImage(String messageId) async {
    try{
      await FirebaseFirestore.instance
          .collection('ChatActions')
          .doc(widget.documentName)
          .collection('messages')
          .doc(messageId)
          .update({
            'isDeleted' : true
      });
    }
    catch(e){
      print("메시지 및 이미지 삭제 요류 : $e");
    }
  }



  //메시지 삭제 및 수정 바텀 시트(직접 적어보기!!!!!!!!!!!!!!!!)
  Future<void> showMessageOptionsBottomSheet(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> snapshot) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.delete),
                title: Text('삭제'),
                onTap: () {
                  Navigator.of(context).pop("delete");
                },
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('수정'),
                onTap: () {
                  Navigator.of(context).pop("edit");
                },
              ),
            ],
          ),
        );
      },
    );

    if (action == "delete") {
      _deleteMessageImage(snapshot.id);
    } else if (action == "edit") {
      // 수정할 메시지의 새로운 내용을 입력받는 과정 필요
      // 예시에서는 바로 _editMessage 메서드를 호출하고 있으나, 실제로는 사용자 입력을 받는 단계를 추가해야 할 수 있습니다.
      // _editMessage(snapshot.id, snapshot['message']);
    }
  }

  // 현재 사용자 UID 가져오기
  Future<User?> _getUID() async {
    User? user = _firebaseAuth.currentUser;
    return user;
  }


  // Timestamp 객체를 입력받아 문자열로 변환하는 함수를 정의합니다.
  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate(); // Firebase의 Timestamp 객체를 Dart의 DateTime 객체로 변환합니다.
    // DateFormat을 사용하여 시간을 '오전/오후 h:mm' 형식으로 포매팅합니다.
    // 'ko' 로케일을 사용하여 한국어 형식(예: 오전 10:30)으로 출력합니다.
    String formattedTime = DateFormat('a h:mm', 'ko').format(dateTime);

    return formattedTime; // 포매팅된 시간 문자열을 반환합니다.
  }


  Widget ChatMessagesListWidget() {
    return Flexible(
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('ChatActions')
              .doc(widget.documentName)
              .collection('messages')
              .orderBy('timestamp', descending: false)
              .snapshots(),

          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
              }
            });

            List<QueryDocumentSnapshot<Map<String, dynamic>>> messages = snapshot.data!.docs;
            // 날짜 구분을 위한 로직 추가
            List<Widget> messageWidgets = [];
            DateTime? lastDate;
            for (int i = 0; i < messages.length; i++) {
              final message = messages[i];
              final messageDate = (message['timestamp'] as Timestamp).toDate();

              if (lastDate == null || messageDate.day != lastDate.day) {
                if (i > 0) { // 메시지가 있으면 바로 위, 없으면 상단 중앙에 표시
                  messageWidgets.add(SizedBox(height: 20)); // 메시지 간격 조정용
                }
                messageWidgets.add(
                    Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0), // 내부 여백 조정
                        decoration: BoxDecoration(
                          color: Colors.white, // 배경색
                          border: Border.all(color: Colors.black, width: 1), // 오렌지색 테두리
                          borderRadius: BorderRadius.circular(20.0), // 둥근 모서리
                        ),
                        child: Text(
                          DateFormat('yyyy년 M월 d일').format(messageDate),
                          style: TextStyle(
                            color: Colors.black, // 텍스트 색상
                            fontWeight: FontWeight.bold, // 글자 굵기
                          ),
                        ),
                      ),
                    )

                );
                if (i > 0) {
                  messageWidgets.add(SizedBox(height: 10)); // 날짜와 메시지 사이 간격 조정용
                }
              }
              lastDate = messageDate;

              // 메시지 위젯 추가
              bool shouldDisplayAvatar = i == 0 || messages[i - 1]['senderUid'] != messages[i]['senderUid'];
              bool isRead = messages[i]['read'] as bool;
              messageWidgets.add(chatMessageItem(message, shouldDisplayAvatar, isRead));
            }

            return ListView(
              controller: _scrollController,
              padding: EdgeInsets.all(10.0),
              children: messageWidgets,
            );
          },
        ),
      ),
    );
  }

  Widget chatMessageItem(
      QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot,
      bool shouldDisplayAvatar, bool isRead) {
    return buildChatLayout(documentSnapshot, shouldDisplayAvatar, isRead);
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
              _pickImageAndUpload(); // 이미지 선택
            },
          ),
          Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0), // 좌우 여백 추가
              child: TextFormField(
                controller: _messageController,
                onFieldSubmitted: (value){
                  _sendMessage();
                },
                decoration: InputDecoration(
                  // hintText: "메시지 입력...",
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
          CircleAvatar(
            backgroundImage: AssetImage('assets/ava.png'),
            backgroundColor: Colors.grey,
            radius: 18.0,
          ),


        SizedBox(width: 10.0),
        Column(
          crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, // Alignment 조정
          children: <Widget>[
            //사진 전송
            SizedBox(height: 10),

              // 이미지 전송, 사용자가 삭제 안했을때
              if (snapshot['type'] == 'image' && snapshot['isDeleted'] == false) ...{
                GestureDetector(
                  onTap: () {
                    // 이미지 클릭 시 FullScreenImage 보여주기
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FullScreenImage(photoUrl: snapshot['photoUrl']),
                      ),
                    );
                  },

                  onLongPress: () {
                    print(snapshot.data());
                    if (isSentByMe) {
                      showMessageOptionsBottomSheet(context, snapshot);
                    }
                  },

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      snapshot['photoUrl'],
                      width: 200.0,
                      height: 200.0,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              },

              // 이미지 전송, 사용자가 삭제 했을때
              if (snapshot['type'] == 'image' && snapshot['isDeleted'] == true) ...{
                Container(
                  // alignment: isSentByMe ? Alignment.topRight : Alignment.topLeft,
                  margin: EdgeInsets.only(top: 10),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSentByMe ? Colors.orangeAccent : Colors.grey[300],
                    borderRadius: BorderRadius.circular(15), // 둥근 모서리 설정
                  ),
                  child: Row(
                    children: <Widget>[
                        Icon(
                          Icons.error, color: Colors.white
                        ),
                        SizedBox(width: 10,),
                        Text(
                          '삭제된 메시지입니다.',
                          style: TextStyle(
                              color: isSentByMe ? Colors.black54 : Colors.grey),
                        )
                    ],
                  ),
                ),
                Column(
                  children: [
                    SizedBox(height: 7),
                    Text(
                      _formatTimestamp(snapshot['timestamp']),
                      style: TextStyle(fontSize: 12.0, color: Colors.black87),
                    ),
                  ],
                )
              },



            //텍스트 전송
            if (snapshot['type'] == 'text' && snapshot['message'].toString().isNotEmpty && snapshot['isDeleted'] == false) ...{
              GestureDetector(
                onLongPress: () {
                  if (isSentByMe) {
                    showMessageOptionsBottomSheet(context, snapshot);
                  }
                },
                child: Container(
                  // alignment: isSentByMe ? Alignment.topRight : Alignment.topLeft,
                  margin: EdgeInsets.only(top: 10),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSentByMe ? Colors.orangeAccent : Colors.grey[300],
                    borderRadius: BorderRadius.circular(15), // 둥근 모서리 설정
                  ),
                  // constraints: BoxConstraints(
                  //   maxWidth: MediaQuery.of(context).size.width * 0.7,
                  // ),
                  child: Column(
                    children: <Widget>[
                      if (snapshot['type'] == 'text')
                        Text(
                          snapshot['message'],
                          style: TextStyle(
                              color: isSentByMe ? Colors.black : Colors.black),
                        )
                    ],
                  ),
                ),
              ),
              SizedBox(height: 7),
              Text(
                _formatTimestamp(snapshot['timestamp']),
                style: TextStyle(fontSize: 12.0, color: Colors.black87),
              ),
            },

            if (snapshot['type'] == 'text' && snapshot['message'].toString().isNotEmpty && snapshot['isDeleted'] == true) ...{
              Container(
                // alignment: isSentByMe ? Alignment.topRight : Alignment.topLeft,
                margin: EdgeInsets.only(top: 10),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isSentByMe ? Colors.orangeAccent : Colors.grey[300],
                  borderRadius: BorderRadius.circular(15), // 둥근 모서리 설정
                ),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.error, color: Colors.white
                         ),
                        SizedBox(width: 10,),
                        Text(
                          '삭제된 메시지입니다.',
                          style: TextStyle(
                              color: isSentByMe ? Colors.black54 : Colors.grey),
                        ),
                      ],
                    ),

                  ],
                ),
              ),
              Column(
                children: [
                  SizedBox(height: 7),
                  Text(
                    _formatTimestamp(snapshot['timestamp']),
                    style: TextStyle(fontSize: 12.0, color: Colors.black87),
                  ),
                ],
              )
            }
          ],
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),),
        // 채팅방 이름 표시
        // backgroundColor: Color(0XFF98ABEE),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.black, // 여기에서 원하는 색상을 설정합니다.
        ),
        actions: <Widget>[

          IconButton(
            icon: Icon(Icons.navigation_rounded, color: Colors.deepOrangeAccent,),
            onPressed: () async {
              await _tmapDirections(); // 위치 데이터를 가져옵니다.
              if (tmapDirections.length >= 2) {
                // tmapDirections 리스트에서 위치 정보 사용
                String currentLocation = tmapDirections[0];
                String storeLocation = tmapDirections[1];
                // Navigator를 사용하여 새 페이지로 이동
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => TMapView(
                    currentLocation: currentLocation,
                    storeLocation: storeLocation,
                  ),
                ));
              }
            },
          ),
        ],
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

}
