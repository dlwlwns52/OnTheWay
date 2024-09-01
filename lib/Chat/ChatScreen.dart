import 'dart:io';

import 'package:OnTheWay/Chat/FullScreenImage.dart';
import 'package:OnTheWay/Chat/message.dart';
import 'package:OnTheWay/Map/Navigation/OwnerTMapView.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../Map/Navigation/HelperTMapView.dart';
import '../Ranking/SchoolRanking.dart';

class ChatScreen extends StatefulWidget {
  final String receiverName;
  final String senderName;
  final String receiverUid;
  final String documentName;  // 채팅방의 문서 이름
  final String? photoUrl;

  ChatScreen({
    required this.receiverName,
    required this.senderName,
    required this.receiverUid,
    required this.documentName,  // 생성자에 documentName 추가
    required this.photoUrl,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
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

  //채팅방에 있는 동안 메시지 확인 체크
  late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> _messageSubscription;

  //채팅방 나가면 채팅 못하게 하게
  late bool _isUserDeleted;
  late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> _userDeleteSubscription;

  // 가져온 닉네임값(길찾기 기능때 다른 아이콘 및 다른 지도로 이동)
  Map<String, String>? nicknames;

  //자동 스크롤 차단
  bool _shouldAutoScroll = false; // 자동 스크롤을 제어하는 플래그
  int _previousMessageCount = 0;


  @override
  void initState() {
    super.initState();
    _shouldAutoScroll = true;
    _isUserDeleted = false;
    WidgetsBinding.instance.addObserver(this); // 생명주기 이벤트 옵저버 추가
    _messageController = TextEditingController();
    _messageController.addListener(_checkFieldsFilled);
    _initializeChatDetails();
    _updateUserStatusInChatRoom(true); // 채팅방에 들어갔음을 업데이트
    _startListeningToMessages(); // 메시지 변경 사항을 실시간으로 듣기
    _startListeningToUserDelete();
    _fetchNicknames();

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 생명주기 이벤트 옵저버 제거
    _scrollController.dispose(); // 스크롤 컨트롤러 해제
    _messageSubscription?.cancel(); // Firestore Listener 해제
    _userDeleteSubscription?.cancel();
    _updateUserStatusInChatRoom(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:

        _updateUserStatusInChatRoom(true); // 앱이 다시 활성화될 때 업데이트
        break;
      case AppLifecycleState.inactive:

        // 앱이 비활성화될 때 수행할 작업
        break;
      case AppLifecycleState.paused:

        _updateUserStatusInChatRoom(false); // 앱이 백그라운드로 가거나 종료될 때 업데이트
        break;
      case AppLifecycleState.detached:

        _updateUserStatusInChatRoom(false); // 앱이 백그라운드로 가거나 종료될 때 업데이트
        break;
      case AppLifecycleState.hidden:

        _updateUserStatusInChatRoom(false); // 앱이 숨겨졌을 때 업데이트
        break;
    }
  }


 //빈 칸이면 채팅 안보내짐
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
    if (widget.documentName != null) {
      await FirebaseFirestore.instance
          .collection('userStatus')
          .doc(widget.senderName)
          .collection('chatRooms')
          .doc(widget.documentName) // 채팅방 ID를 문서 ID로 사용
          .set({
        'isInChatRoom': isInChatRoom,
        'timestamp': DateTime.now()
      });
    }
  }

//상대방이 채팅방 나가면 해당 데이터 가져오는 함수
  void _startListeningToUserDelete() {
    _userDeleteSubscription = FirebaseFirestore.instance
        .collection('ChatActions')
        .doc(widget.documentName)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            var data = snapshot.data();
            setState(() {
              _isUserDeleted = data?['isDeleted_${widget.receiverName}'] ?? false;
            });
          } else {
            setState(() {
              _isUserDeleted = false;
            });
          }
        });
  }


  // //채팅방에 있는 동안 count 0 설정하는 함수
  void _startListeningToMessages() {
    // 상대방의 userStatus를 실시간으로 감지합니다.
    _messageSubscription = FirebaseFirestore.instance
        .collection('userStatus')
        .doc(widget.receiverName)
        .collection('chatRooms')
        .doc(widget.documentName)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data();
        if (data != null && data['isInChatRoom'] == true) {
          // 상대방이 채팅방에 있을 때 메시지 카운트를 0으로 설정
          FirebaseFirestore.instance
              .collection('ChatActions')
              .doc(widget.documentName)
              .update({'messageCount_${widget.senderName}': 0});

          // 읽지 않은 메시지를 읽음으로 표시
          FirebaseFirestore.instance
              .collection('ChatActions')
              .doc(widget.documentName)
              .collection('messages')
              .where('read', isEqualTo: false)
              .get()
              .then((unreadMessages) {
            for (var message in unreadMessages.docs) {
              message.reference.update({'read': true});
            }
          });
        }
      }
    });
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
      List<File> imageFiles = selectedImages.map((xFile) => File(xFile.path)).toList();

      // 선택된 이미지를 보여주고 업로드를 진행할지 결정하는 UI
      bool shouldUpload = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          title: Text(
            '사진 확인',
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
                    borderRadius: BorderRadius.circular(25.0),
                    child: Image.file(file, fit: BoxFit.cover),
                  ),
                )).toList(),
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: <Widget>[
            ElevatedButton.icon(
              icon: Icon(Icons.send),
              label: Text('보내기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1D4786),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop(true);
              },
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.cancel),
              label: Text('취소'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop(false);
              },
            ),
          ],
        ),
      );

      // 사용자가 업로드를 선택한 경우
      if (shouldUpload) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("이미지 업로드 중입니다. \n잠시만 기다려 주시면 감사하겠습니다.", textAlign: TextAlign.center,),
            duration: Duration(seconds: 3),
          ),
        );


        // 이미지 업로드 비동기 처리
        for (var imageFile in imageFiles) {
          Reference storageReference = FirebaseStorage.instance
              .ref()
              .child('images/${DateTime.now().millisecondsSinceEpoch}');
          UploadTask uploadTask = storageReference.putFile(imageFile);
          TaskSnapshot taskSnapshot = await uploadTask;
          String downloadUrl = await taskSnapshot.ref.getDownloadURL();
          uploadImageUrls.add(downloadUrl);
        }


        // 모든 이미지 업로드 후 사용자에게 알림
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("이미지 업로드 완료!", textAlign: TextAlign.center,),
            duration: Duration(seconds: 2),
          ),
        );
      }
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
    messages.add(messageMap).whenComplete(() async {
      await FirebaseFirestore.instance.collection('ChatActions').doc(widget.documentName).update({
        'lastMessage': message.message,
      });

      // 상대방의 userStatus를 확인하고 messageCount를 업데이트합니다.
      DocumentReference userStatusRef = FirebaseFirestore.instance
          .collection('userStatus')
          .doc(widget.receiverName)
          .collection('chatRooms')
          .doc(widget.documentName);

      // 메시지 온 횟수 추적
      DocumentReference userMessageCount = FirebaseFirestore.instance
          .collection('ChatActions')
          .doc(widget.documentName);

      DocumentSnapshot userStatusSnapshot = await userStatusRef.get();
      DocumentSnapshot userCountSnapshot = await userMessageCount.get();

      if (userStatusSnapshot.exists) {
        var statusData = userStatusSnapshot.data() as Map<String, dynamic>; // 타입 캐스팅
        var countData = userCountSnapshot.data() as Map<String, dynamic>; // 타입 캐스팅

        bool isInChatRoom = statusData['isInChatRoom'] ?? false;

        if (isInChatRoom) {
          // 상대방이 채팅방에 있는 경우 messageCount를 0으로 설정
          await userMessageCount.update({'messageCount_${widget.receiverName}': 0});
          QuerySnapshot<Map<String, dynamic>> unreadMessages = await FirebaseFirestore.instance
              .collection('ChatActions')
              .doc(widget.documentName)
              .collection('messages')
              .where('read', isEqualTo: false)
              .get();
          for (var message in unreadMessages.docs) {
            await message.reference.update({'read': true});
          }

        } else {
          // 상대방이 채팅방에 없는 경우 messageCount 증가
          int messageCount = countData['messageCount_${widget.receiverName}'] ?? 0;
          await userMessageCount.update({'messageCount_${widget.receiverName}': messageCount + 1});
        }
      } else {
        // userStatus 문서가 존재하지 않는 경우 (초기 상태)
        await userMessageCount.update({'messageCount_${widget.receiverName}': 1});
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

  //메시지 복사

  void _copyMessage(String message){
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "메시지가 복사되었습니다.",
          textAlign: TextAlign.center,
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void showMessageOptionsBottomSheet(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> snapshot, bool text, bool isSentMy) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFFFFFFFF),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 15, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(1, 0, 0, 43),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFE3E3E3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  width: 44,
                  height: 4,
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(0, 0, 0, 37),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    //복사
                    if(text)
                      GestureDetector(
                        onTap: (){
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop("copy");
                        },
                        child: Container(
                          margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xFFFFFFFF),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x0A000000),
                                offset: Offset(0, 4),
                                blurRadius: 7.5,
                              ),
                            ],
                          ),
                          padding: EdgeInsets.fromLTRB(1, 17, 0, 17),
                          child: Center(
                            child:
                            Row(
                              mainAxisSize: MainAxisSize.min, // Row의 크기를 자식 크기에 맞추도록 설정
                              children: [
                                Icon(
                                  Icons.copy, // 원하는 아이콘 설정
                                  color: Color(0xFF222222), // 아이콘 색상
                                  size: 20, // 아이콘 크기
                                ),
                                SizedBox(width: 8), // 아이콘과 텍스트 사이의 간격 조정
                                Text(
                                  '복사',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 17,
                                    height: 1,
                                    letterSpacing: -0.4,
                                    color: Color(0xFF222222),
                                  ),
                                ),
                              ],
                            )

                          ),
                        ),
                      ),

                    //삭제
                    if(isSentMy)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop("delete");
                        },
                        child: Container(
                          margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xFFFFFFFF),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x0A000000),
                                offset: Offset(0, 4),
                                blurRadius: 7.5,
                              ),
                            ],
                          ),
                          padding: EdgeInsets.fromLTRB(1, 17, 0, 17),
                          child: Center(
                            child:
                            Row(
                              mainAxisSize: MainAxisSize.min, // Row의 크기를 자식 크기에 맞추도록 설정
                              children: [
                                Icon(
                                  Icons.delete, // 원하는 아이콘 설정
                                  color: Color(0xFF222222), // 아이콘 색상
                                  size: 20, // 아이콘 크기
                                ),
                                SizedBox(width: 8), // 아이콘과 텍스트 사이의 간격 조정
                                Text(
                                  '삭제',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 17,
                                    height: 1,
                                    letterSpacing: -0.4,
                                    color: Color(0xFF222222),
                                  ),
                                ),
                              ],
                            )

                          ),
                        ),
                      ),


                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop(); // 취소 버튼 클릭 시 모달 닫기
                      },
                      child: Container(
                        margin: EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color(0xFFFFFFFF),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0D000000),
                              offset: Offset(0, 4),
                              blurRadius: 7.5,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(1, 17, 0, 17),
                        child: Center(
                          child: Text(
                            '취소',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              fontSize: 17,
                              height: 1,
                              letterSpacing: -0.4,
                              color: Color(0xFF222222),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if(action == 'copy'){
      _copyMessage(snapshot['message']);
    }
    if (action == "delete") {
      _deleteMessageImage(snapshot.id);
    }
  }


  // 현재 사용자 UID 가져오기
  Future<User?> _getUID() async {
    User? user = _firebaseAuth.currentUser;
    return user;
  }


  // helper 와 owner 닉네임 가져오기
  Future<Map<String, String>> getNicknames() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('ChatActions')
        .doc(widget.documentName)
        .get();

    String ownerNickname = snapshot.get('owner_email_nickname');
    String helperNickname = snapshot.get('helper_email_nickname');

    return {
      'ownerNickname': ownerNickname,
      'helperNickname': helperNickname,
    };
  }


  Future<void> _fetchNicknames() async {
    Map<String, String> fetchedNicknames = await getNicknames();
    setState(() {
      nicknames = fetchedNicknames;
    });
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
        child: Column(
          children: [
            Expanded(
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

                  List<QueryDocumentSnapshot<Map<String, dynamic>>> messages = snapshot.data!.docs;


                  // 새로운 메시지가 추가되었는지 확인
                  if (messages.length > _previousMessageCount) {
                    _shouldAutoScroll = true;
                  } else {
                    _shouldAutoScroll = false;
                  }
                  _previousMessageCount = messages.length;

                  // 자동 스크롤 실행
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients && _shouldAutoScroll) {
                      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                    }
                  });

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
                        Align(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.35,  // 원하는 너비로 설정
                            margin: EdgeInsets.fromLTRB(0, 20, 1.2, 0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(100),
                              color: Colors.grey.shade200,
                            ),
                            padding: EdgeInsets.fromLTRB(0, 7, 0, 7),
                            child: Text(
                              DateFormat('yyyy년 M월 d일').format(messageDate),
                              textAlign: TextAlign.center,  // 텍스트를 중앙 정렬
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                height: 1,
                                letterSpacing: -0.4,
                                color: Color(0xFF767676),
                              ),
                            ),
                          ),
                        ),

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

                  //채팅방 나가는 ui
                  if (_isUserDeleted) {
                    messageWidgets.add(
                      Align(
                        child: Container(
                          // width: MediaQuery.of(context).size.width * 0.55,  // 원하는 너비로 설정
                          margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(100),
                            color: Colors.grey.shade200,
                          ),
                          padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                          child:
                          Text(
                            "${widget.receiverName}님이 채팅방을 나갔습니다.",
                            textAlign: TextAlign.center,  // 텍스트를 중앙 정렬
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              height: 1,
                              letterSpacing: -0.4,
                              color: Color(0xFF767676),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView(
                    controller: _scrollController,
                    padding: EdgeInsets.all(10.0),
                    children: messageWidgets,
                  );
                },
              ),
            ),
          ],
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
            onPressed: _isUserDeleted ? null : () {
              _pickImageAndUpload(); // 이미지 선택
            },

          ),
          Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.0), // 좌우 여백 추가
              child: TextFormField(
                controller: _messageController,
                onFieldSubmitted: (value){
                  if (!_isUserDeleted) {
                    _sendMessage();
                  }
                },
                decoration: InputDecoration(
                  hintText: _isUserDeleted ?"메시지를 보낼 수 없습니다." :' ' ,
                  contentPadding: EdgeInsets.symmetric(vertical: 9.0, horizontal: 15.0), // 패딩 조정
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0), // 둥근 모서리 적용
                    borderSide: BorderSide.none, // 외곽선 제거
                  ),
                  filled: true,
                  fillColor: Colors.grey[200], // 배경색 적용
                ),
                enabled: !_isUserDeleted,
              ),
            ),
          ),

          IconButton(
            icon: Icon(Icons.send,  color: isFilled ? Color(0xFF1D4786) :Colors.grey[600], size: 35,), // 아이콘 색상 조정
            onPressed: () {
              HapticFeedback.lightImpact();
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



        Column(
          crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, // Alignment 조정
          children: <Widget>[

            SizedBox(height: 10),


            //텍스트 전송 삭제 x
            if (snapshot['type'] == 'text' && snapshot['message'].toString().isNotEmpty && snapshot['isDeleted'] == false) ...{
              GestureDetector(
                onLongPress: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _shouldAutoScroll = false; // 롱프레스 시 자동 스크롤을 비활성화
                  });
                  if (isSentByMe) {
                    showMessageOptionsBottomSheet(context, snapshot, true, true);
                  } else if (!isSentByMe) {
                    showMessageOptionsBottomSheet(context, snapshot, true, false);
                  }
                },

                child: isSentByMe
                // 본인이 보냄
                    ?
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end, // 메시지와 프로필 사진이 수직으로 정렬되도록 설정
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end, // Row의 모든 자식을 하단 정렬
                      children: [
                        if (isSentByMe && !isMessageRead) ...[
                          Text(
                            '1',
                            style: TextStyle(
                              color: Color(0xFF1D4786),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        SizedBox(width: 5),
                        Container(
                          margin: EdgeInsets.only(top: 10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF1D4786),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.6,
                            ),
                            child: Container(
                              padding: EdgeInsets.fromLTRB(16, 14, 12.2, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  if (snapshot['type'] == 'text')
                                    Text(
                                      snapshot['message'],
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 15,
                                        height: 1.2,
                                        letterSpacing: -0.4,
                                        color: Color(0xFFFFFFFF),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.bottomRight, // 우측 하단 정렬
                      child: Text(
                        _formatTimestamp(snapshot['timestamp']),
                        style: TextStyle(fontSize: 12.0, color: Colors.black87),
                      ),
                    ),
                  ],
                )

                // 상대방이 보냄
                    :
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _shouldAutoScroll = false; // 롱프레스 시 자동 스크롤을 비활성화
                        });
                        if (widget.photoUrl!.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImage(photoUrl: widget.photoUrl!),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '기본 프로필 사진입니다.',
                                textAlign: TextAlign.center,
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF1D4786), Color(0xFF1D4786)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                                  ? BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 1,
                                offset: Offset(0, 1), // 그림자 위치 조정
                              )
                                  : BoxShadow(),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 20, // 반지름 설정 (32 / 2)
                            backgroundColor: Colors.grey[200],
                            child: (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                                ? null
                                : Icon(
                              Icons.account_circle,
                              size: 40, // 원래 코드에서 width와 height가 32였으므로 여기에 맞춤
                              color: Color(0xFF1D4786),
                            ),
                            backgroundImage: widget.photoUrl != null && widget.photoUrl!.isNotEmpty
                                ? NetworkImage(widget.photoUrl!)
                                : null,
                          ),
                        ),
                    ),
                    SizedBox(width: 10.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // 메시지와 프로필 사진이 수직으로 정렬되도록 설정
                      children: <Widget>[
                        Text(
                          '${widget.receiverName}',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            height: 1,
                            letterSpacing: -0.4,
                            color: Color(0xFF222222),
                          ),
                        ),
                        SizedBox(height: 10,),
                        Container(
                          margin: EdgeInsets.fromLTRB(0, 0, 0, 8),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFE8EFF8),
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.6,
                              ),
                              child: Container(
                                padding: EdgeInsets.fromLTRB(16, 14, 11.9, 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    if (snapshot['type'] == 'text')
                                      Text(
                                        snapshot['message'],
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 15,
                                          height: 1.2,
                                          letterSpacing: -0.4,
                                          color: Color(0xFF222222),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight, // 우측 하단 정렬
                          child: Text(
                            _formatTimestamp(snapshot['timestamp']),
                            style: TextStyle(fontSize: 12.0, color: Colors.black87),
                          ),
                        ),
                        SizedBox(height: 10,),
                      ],
                    ),
                  ],
                ),
              ),
            },




              // 이미지 전송, 사용자가 삭제 안했을때
            if (snapshot['type'] == 'image' && snapshot['isDeleted'] == false) ...{
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // 이미지 클릭 시 FullScreenImage 보여주기
                  setState(() {
                    _shouldAutoScroll = false; // 롱프레스 시 자동 스크롤을 비활성화
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImage(photoUrl: snapshot['photoUrl']),
                    ),
                  );
                },
                onLongPress: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _shouldAutoScroll = false; // 롱프레스 시 자동 스크롤을 비활성화
                  });
                  if (isSentByMe) {
                    showMessageOptionsBottomSheet(context, snapshot, false, true);
                  } else if (!isSentByMe) {
                    showMessageOptionsBottomSheet(context, snapshot, false, false);
                  }
                },
                child: isSentByMe
                // 본인이 보냄
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end, // Row의 모든 자식을 하단 정렬
                      children: [
                        if (isSentByMe && !isMessageRead) ...[
                          Text(
                            '1',
                            style: TextStyle(
                              color: Colors.indigo,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        SizedBox(width: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            snapshot['photoUrl'],
                            width: 200.0,
                            height: 200.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 7),
                    Text(
                      _formatTimestamp(snapshot['timestamp']),
                      style: TextStyle(fontSize: 12.0, color: Colors.black87),
                    ),
                  ],
                )
                // 상대방이 보냄
                    : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF1D4786), Color(0xFF1D4786)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                              ? BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 1,
                            offset: Offset(0, 1), // 그림자 위치 조정
                          )
                              : BoxShadow(),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 20, // 반지름 설정 (32 / 2)
                        backgroundColor: Colors.grey[200],
                        child: (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                            ? null
                            : Icon(
                          Icons.account_circle,
                          size: 40, // 원래 코드에서 width와 height가 32였으므로 여기에 맞춤
                          color: Color(0xFF1D4786),
                        ),
                        backgroundImage: widget.photoUrl != null && widget.photoUrl!.isNotEmpty
                            ? NetworkImage(widget.photoUrl!)
                            : null,
                      ),
                    ),
                    SizedBox(width: 10.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // 메시지와 프로필 사진이 수직으로 정렬되도록 설정
                      children: <Widget>[
                        Text(
                          '${widget.receiverName}',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            height: 1,
                            letterSpacing: -0.4,
                            color: Color(0xFF222222),
                          ),
                        ),
                        SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            snapshot['photoUrl'],
                            width: 200.0,
                            height: 200.0,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight, // 우측 하단 정렬
                          child: Text(
                            _formatTimestamp(snapshot['timestamp']),
                            style: TextStyle(fontSize: 12.0, color: Colors.black87),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ],
                ),
              ),
            },





              // 이미지 전송 삭제!
            if (snapshot['type'] == 'image' && snapshot['isDeleted'] == true) ...{
              isSentByMe
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.end, // 메시지와 프로필 사진이 수직으로 정렬되도록 설정
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end, // Row의 모든 자식을 하단 정렬
                    children: [
                      if (isSentByMe && !isMessageRead) ...[
                        Text(
                          '1',
                          style: TextStyle(
                            color: Color(0xFF1D4786),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      SizedBox(width: 5),
                      Container(
                        margin: EdgeInsets.only(top: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF1D4786),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(16, 14, 12.2, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.error,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      '삭제된 메시지입니다.',
                                      style: TextStyle(color: Color(0xFFFFFFFF)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomRight, // 우측 하단 정렬
                    child: Text(
                      _formatTimestamp(snapshot['timestamp']),
                      style: TextStyle(fontSize: 12.0, color: Colors.black87),
                    ),
                  ),
                ],
              )
              // 상대방이 보냄
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF1D4786), Color(0xFF1D4786)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                            ? BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 1,
                          offset: Offset(0, 1), // 그림자 위치 조정
                        )
                            : BoxShadow(),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 20, // 반지름 설정 (32 / 2)
                      backgroundColor: Colors.grey[200],
                      child: (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                          ? null
                          : Icon(
                        Icons.account_circle,
                        size: 40, // 원래 코드에서 width와 height가 32였으므로 여기에 맞춤
                        color: Color(0xFF1D4786),
                      ),
                      backgroundImage: widget.photoUrl != null && widget.photoUrl!.isNotEmpty
                          ? NetworkImage(widget.photoUrl!)
                          : null,
                    ),
                  ),
                  SizedBox(width: 10.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // 메시지와 프로필 사진이 수직으로 정렬되도록 설정
                    children: <Widget>[
                      Text(
                        '${widget.receiverName}',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          height: 1,
                          letterSpacing: -0.4,
                          color: Color(0xFF222222),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 0, 0, 8),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFE8EFF8),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                            child: Container(
                              padding: EdgeInsets.fromLTRB(16, 14, 12.2, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.error,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        '삭제된 메시지입니다.',
                                        style: TextStyle(color: Color(0xFF222222)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight, // 우측 하단 정렬
                        child: Text(
                          _formatTimestamp(snapshot['timestamp']),
                          style: TextStyle(fontSize: 12.0, color: Colors.black87),
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ],
              ),
            },






            if (snapshot['type'] == 'text' && snapshot['message'].toString().isNotEmpty && snapshot['isDeleted'] == true) ...{
              isSentByMe
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.end, // 메시지와 프로필 사진이 수직으로 정렬되도록 설정
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end, // Row의 모든 자식을 하단 정렬
                    children: [
                      if (isSentByMe && !isMessageRead) ...[
                        Text(
                          '1',
                          style: TextStyle(
                            color: Color(0xFF1D4786),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                      SizedBox(width: 5),
                      Container(
                        margin: EdgeInsets.only(top: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF1D4786),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(16, 14, 12.2, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.error,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      '삭제된 메시지입니다.',
                                      style: TextStyle(color: Color(0xFFFFFFFF)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Align(
                    alignment: Alignment.bottomRight, // 우측 하단 정렬
                    child: Text(
                      _formatTimestamp(snapshot['timestamp']),
                      style: TextStyle(fontSize: 12.0, color: Colors.black87),
                    ),
                  ),
                ],
              )
              // 상대방이 보냄
                  : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF1D4786), Color(0xFF1D4786)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                            ? BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 1,
                          offset: Offset(0, 1), // 그림자 위치 조정
                        )
                            : BoxShadow(),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 20, // 반지름 설정 (32 / 2)
                      backgroundColor: Colors.grey[200],
                      child: (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                          ? null
                          : Icon(
                        Icons.account_circle,
                        size: 40, // 원래 코드에서 width와 height가 32였으므로 여기에 맞춤
                        color: Color(0xFF1D4786),
                      ),
                      backgroundImage: widget.photoUrl != null && widget.photoUrl!.isNotEmpty
                          ? NetworkImage(widget.photoUrl!)
                          : null,
                    ),
                  ),
                  SizedBox(width: 10.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // 메시지와 프로필 사진이 수직으로 정렬되도록 설정
                    children: <Widget>[
                      Text(
                        '${widget.receiverName}',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          height: 1,
                          letterSpacing: -0.4,
                          color: Color(0xFF222222),
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 0, 0, 8),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFE8EFF8),
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                            child: Container(
                              padding: EdgeInsets.fromLTRB(16, 14, 12.2, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.error,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        '삭제된 메시지입니다.',
                                        style: TextStyle(color: Color(0xFF222222)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight, // 우측 하단 정렬
                        child: Text(
                          _formatTimestamp(snapshot['timestamp']),
                          style: TextStyle(fontSize: 12.0, color: Colors.black87),
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ],
              ),

            }
          ],
        ),
      ],
    );
  }




  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async{
        return true;
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details){
          if (details.primaryVelocity! >  0){
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          }
        },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
          child: AppBar(
            title: Text(
              '${widget.receiverName}',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 19,
                height: 1.0,
                // letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
            centerTitle: true,
            backgroundColor: Color(0xFF1D4786),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_outlined), // '<' 모양의 뒤로가기 버튼 아이콘
              color: Colors.white, // 아이콘 색상
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context); // 뒤로가기 기능
              },
            ),
            actions: [

                    IconButton(
                      icon:  nicknames != null && widget.senderName == nicknames!['ownerNickname']
                     ? Container(
                        margin: EdgeInsets.only(bottom: 5),
                         child: SvgPicture.asset(
                              'assets/pigma/map.svg',
                              width: 27,
                              height: 27,
                            ),
                          )
                      :Container(
                        margin: EdgeInsets.only(bottom: 5),
                        child: SvgPicture.asset(
                        'assets/pigma/compass.svg',
                            width: 27,
                            height: 27,
                          ),
                        ),


                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await _tmapDirections(); // 위치 데이터를 가져옵니다.

                        if (nicknames!['helperNickname'] == widget.senderName) {
                          if (tmapDirections.length >= 2) {
                            // tmapDirections 리스트에서 위치 정보 사용
                            String currentLocation = tmapDirections[0];
                            String storeLocation = tmapDirections[1];
                            // Navigator를 사용하여 새 페이지로 이동
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  HelperTMapView(
                                    currentLocation: currentLocation,
                                    storeLocation: storeLocation,
                                  ),
                            ));
                          }
                        }

                        else if (nicknames!['ownerNickname'] == widget.senderName) {
                          if (tmapDirections.length >= 2) {
                            // tmapDirections 리스트에서 위치 정보 사용
                            String currentLocation = tmapDirections[0];
                            String storeLocation = tmapDirections[1];
                            // 여기에 헬퍼 위치 보이게 하기
                            String? helperNickname = nicknames!['helperNickname'] ?? 'defaultHelperId';
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  OwnerTMapView(
                                    currentLocation: currentLocation,
                                    storeLocation: storeLocation,
                                    helperId: helperNickname,
                                    documentName: widget.documentName,
                                  ),
                            ));
                          }
                        }
                      },
                    ),

            ],
          ),
        ),
          body: Stack(
            children:[
              Column(
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

           ],
          ),
        ),
    ),
    );
  }

}
