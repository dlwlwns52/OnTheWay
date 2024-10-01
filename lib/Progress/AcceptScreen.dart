import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';

import '../Chat/AllUsersScreen.dart';
import '../Chat/Message.dart';
import 'RateUserScreen.dart';

class AcceptScreen extends StatefulWidget {
  @override
  _AcceptScreenState createState() => _AcceptScreenState();
}

class _AcceptScreenState extends State<AcceptScreen> {
  // Firestore 인스턴스를 생성하여 데이터베이스에 접근할 수락 있게 합니다.
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  // 초기 게시글 개수
  int postCount = 0;
  String email = ""; // 사용자의 이메일을 저장할 변수
  late Stream<QuerySnapshot> postStream;

  List<DocumentSnapshot> acceptedPayments = [];
  late StreamSubscription<dynamic> _paymentsSubscription; // Firestore 스트림 구독을 위한 변수
  bool requestSend = false;


  // ScrollController 추가
  ScrollController _scrollController = ScrollController();
  bool _isNearBottom = false;


  //사진 전송 변수
  bool isPhotoSent = false;

  //오더용 페이 선택 변수
  String selectedMethod = "bankTransfer";

  //내 닉네임
  String myNickname = '';

  @override
  void initState() {
    super.initState();

    final FirebaseAuth _auth = FirebaseAuth.instance;
    email = _auth.currentUser?.email ?? "";

    _getNickname(email);
    _fetchPayments();


    // 스크롤 위치 변경 감지
    _scrollController.addListener(() {
      if (_scrollController.position.atEdge) {
        bool isBottom = _scrollController.position.pixels != 0;
        _isNearBottom = isBottom;
      }
    });
  }


  @override
  void dispose() {
    _paymentsSubscription.cancel();
    _scrollController.dispose();  // ScrollController 해제
    super.dispose();
  }





  // 이 함수는 현재 로그인한 사용자의 채팅방 목록을 가져오고, 각 채팅방의 최신 메시지 시간에 따라 목록을 정렬합니다.
  Future<void> _fetchPayments() async {
    // 현재 로그인한 사용자 정보를 가져옵니다.
    User? currentUser = FirebaseAuth.instance.currentUser;
    // 사용자가 로그인하지 않았거나 이메일 정보가 없다면 함수를 종료합니다.
    if (currentUser == null || currentUser.email == null) {
      return;
    }

    // 현재 사용자의 이메일 주소를 가져옵니다.
    String currentUserEmail = currentUser.email!;
    // 'helper_email' 필드가 현재 사용자의 이메일과 일치하는 'Payments' 컬렉션의 문서 스트림을 가져옵니다.
    var helperEmailStream = FirebaseFirestore.instance
        .collection('Payments')
        .where('response', isEqualTo: 'accepted')
        .where('helper_email', isEqualTo: currentUserEmail)
        .snapshots();

    // 'owner_email' 필드가 현재 사용자의 이메일과 일치하는 'Payments' 컬렉션의 문서 스트림을 가져옵니다.
    var ownerEmailStream = FirebaseFirestore.instance
        .collection('Payments')
        .where('response', isEqualTo: 'accepted')
        .where('owner_email', isEqualTo: currentUserEmail)
        .snapshots();

    // 두 스트림을 결합하여 채팅방 목록을 생성합니다.
    _paymentsSubscription = Rx.combineLatest2(
        helperEmailStream, ownerEmailStream, (QuerySnapshot helperSnapshot, QuerySnapshot ownerSnapshot) async {
      // helperEmailStream과 ownerEmailStream에서 받은 문서들을 결합합니다.
      var combinedDocs = {...helperSnapshot.docs, ...ownerSnapshot.docs}
          .toList();


      // 문서들을 최신 순으로 정렬합니다.
      combinedDocs.sort((a, b) {
        Timestamp timeA = a['timestamp'] as Timestamp;
        Timestamp timeB = b['timestamp'] as Timestamp;
        return timeB.compareTo(timeA); // 최신 순으로 정렬
      });


      // 스크롤이 최하단에 있지 않으면 화면 갱신
      if (mounted && !_isNearBottom) {
        setState(() {
          acceptedPayments = combinedDocs;
        });
      }
    }).listen((data) {},
      onError: (error) {
        // 스트림에서 오류가 발생한 경우 로그를 출력합니다.
        print("An error occurred: $error");
      },
    );
  }


  //닉네임 가져오기
  Future<void> _getNickname(String email) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    QuerySnapshot nicknameSnapshot = await db
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (nicknameSnapshot.docs.isNotEmpty) {
      DocumentSnapshot document = nicknameSnapshot.docs.first;
      String? myNickname = document.get('nickname');

      // 닉네임 값을 업데이트
      setState(() {
        this.myNickname = myNickname!;
      });
    } else {
      print("해당 이메일을 가진 사용자가 없습니다.");
    }
  }


  //이미지 링크 가져오기
  Future<String?> _getProfileImage(String email) async{
    FirebaseFirestore db = FirebaseFirestore.instance;
    QuerySnapshot nicknameSnapshot = await db
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if(nicknameSnapshot.docs.isNotEmpty){
      DocumentSnapshot document = nicknameSnapshot.docs.first;
      String? profilePhotoURL = document.get('profilePhotoURL');
      return profilePhotoURL;
    }

    else {
      print("해당 이메일을 가진 사용자가 없습니다.");
      return null;
    }
  }


  // 현재 로그인한 사용자의 이메일을 반환하는 메서드
  String? currentUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email;
  }

  //현재 시간
  String formatTimeAgo(Timestamp timestamp) {
    // Timestamp를 DateTime으로 변환
    DateTime dateTime = timestamp.toDate();
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes <= 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      // 날짜를 '2024.10.12 17:30' 형식으로 변환
      DateFormat dateFormat = DateFormat('yyyy.MM.dd HH:mm');
      return dateFormat.format(dateTime);  // 형식화된 날짜 반환
    }
  }

  //비용을 숫자만 가져온다.
  String _extractCost(String cost) {
    final RegExp regex = RegExp(r'\d+');
    final match = regex.firstMatch(cost);
    return match != null ? match.group(0)! : '0';
  }

  //비용을 int형으로 바꾼다.
  int _extractCostAsInt(String cost) {
    String costString = _extractCost(cost);
    return int.parse(costString);
  }

  //상대가 요청하기 안 한 경우 false 로 설정 아닌경우 그냥 진행
  Future<String> checkRequestPayment(String docName) async {
    DocumentSnapshot paymentDoc = await FirebaseFirestore.instance.collection('Payments').doc(docName).get();
    Map<String, dynamic> paymentData = paymentDoc.data() as Map<String, dynamic>;
    if (paymentData['isPaymentRequested'] == null){
      return 'not requested'; // 상대방이 '결제 요청하기' 안함
    }

    else if (paymentData['isPaymentRequested'] == false){
      return 'updated'; // 상대방이 '결제 요청하기' 안하고 이미 푸시알림 보냄
    }

    else if (paymentData['isPaymentRequested'] == true){
      return 'already requested'; // 상대방이 '결제 요청하기 함.
    }
    return '';
  }

  Future<void> updateRequestTrue(String docName) async {
    DocumentSnapshot paymentDoc = await FirebaseFirestore.instance.collection('Payments').doc(docName).get();
    if (paymentDoc.exists){
      Map<String, dynamic> paymentData = paymentDoc.data() as Map<String, dynamic>;

      if (paymentData['isPaymentRequested'] == null || paymentData['isPaymentRequested'] == false){
        await FirebaseFirestore.instance.collection('Payments').doc(docName).update(
            {
              'isPaymentRequested': true,
            });
      }
    }
  }



  //결제 요청하기 사진 보내는 로직 부분

  //메시지 객체 생성 후(사진) 메시지 전송에 보냄
  Future<void> _sendMessage(String documentName, String senderName, String receiverName, String senderUid, String receiverUid, String helperBank, String helperAccount
      ,String cost) async{
    DateTime now = DateTime.now();
    Timestamp timestamp = Timestamp.fromDate(now); // DateTime을 Timestamp로 변환


    // 텍스트 메시지 객체 생성
    Message firstMessage = Message(
      receiverName : receiverName,
      senderName : senderName,
      receiverUid: receiverUid,
      senderUid: senderUid,
      message: '완료 사진을 전송해 드립니다.\n확인 후 정산해주세요! \n은행명 : ${helperBank}\n계좌번호 : ${helperAccount}\n가격 : ${cost}',
      timestamp: timestamp,
      read : false,
      type : 'text',
      isDeleted : false,
    );

    // _addMessageToDb 함수를 사용하여 메시지 추가
    await _addMessageToDb(firstMessage, documentName);

    Message secondMessage = Message(
      receiverName : receiverName,
      senderName : senderName,
      receiverUid: receiverUid,
      senderUid: senderUid,
      message: '${helperBank} ${helperAccount}',
      timestamp: timestamp,
      read : false,
      type : 'text',
      isDeleted : false,
    );

    // _addMessageToDb 함수를 사용하여 메시지 추가
    await _addMessageToDb(secondMessage, documentName);


  }

  //채팅 목록에 1 표시 및 미리보기 메시지를 위해 설정
  Future<void> _addMessageToDb(Message message, String documentName) async {
    Map<String, dynamic> messageMap = message.toMap();

    // 해당 채팅방의 messages 서브컬렉션 참조
    CollectionReference messages = FirebaseFirestore.instance
        .collection('ChatActions')
        .doc(documentName)
        .collection('messages');

    // 메시지를 messages 서브컬렉션에 추가
    messages.add(messageMap).whenComplete(() async {
      await FirebaseFirestore.instance.collection('ChatActions').doc(documentName).update({
        'lastMessage': message.message,
      });

      // 상대방의 userStatus를 확인하고 messageCount를 업데이트합니다.
      DocumentReference userStatusRef = FirebaseFirestore.instance
          .collection('userStatus')
          .doc(message.receiverName)
          .collection('chatRooms')
          .doc(documentName);

      // 메시지 온 횟수 추적
      DocumentReference userMessageCount = FirebaseFirestore.instance
          .collection('ChatActions')
          .doc(documentName);

      DocumentSnapshot userStatusSnapshot = await userStatusRef.get();
      DocumentSnapshot userCountSnapshot = await userMessageCount.get();

      if (userStatusSnapshot.exists) {
        var statusData = userStatusSnapshot.data() as Map<String, dynamic>; // 타입 캐스팅
        var countData = userCountSnapshot.data() as Map<String, dynamic>; // 타입 캐스팅

        bool isInChatRoom = statusData['isInChatRoom'] ?? false;

        if (isInChatRoom) {
          // 상대방이 채팅방에 있는 경우 messageCount를 0으로 설정
          await userMessageCount.update({'messageCount_${message.receiverName}': 0});
          QuerySnapshot<Map<String, dynamic>> unreadMessages = await FirebaseFirestore.instance
              .collection('ChatActions')
              .doc(documentName)
              .collection('messages')
              .where('read', isEqualTo: false)
              .get();
          for (var message in unreadMessages.docs) {
            await message.reference.update({'read': true});
          }

        } else {
          // 상대방이 채팅방에 없는 경우 messageCount 증가
          int messageCount = countData['messageCount_${message.receiverName}'] ?? 0;
          await userMessageCount.update({'messageCount_${message.receiverName}': messageCount + 1});
        }
      } else {
        // userStatus 문서가 존재하지 않는 경우 (초기 상태)
        await userMessageCount.update({'messageCount_${message.receiverName}': 1});
      }
    });
  }



  //헬퍼용 완성 다이어로그
  Future<void> _showHelperPaymentDialog(BuildContext context, String documentName) async {
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance.collection('Payments').doc(documentName).get();
    // 문서가 존재하는지 확인
    if (docSnapshot.exists) {
      // 문서의 필드 값을 가져옴 (예: 'amount', 'paymentStatus' 등 필드 이름에 맞게 사용)
      Map<String, dynamic> paymentData = docSnapshot.data() as Map<String, dynamic>;


      String helperNickname = paymentData['helper_email_nickname'] ?? '헬퍼 닉네임 없음';
      String ownerNickname = paymentData['owner_email_nickname'] ?? '오더 닉네임 없음';
      String helperUid = paymentData['helperUid'] ?? '헬퍼 UID 없음';
      String ownerUid = paymentData['ownerUid'] ?? '오더 UID 없음';
      String helperBank = paymentData['helperBank'] ?? '도우미 은행 없음';
      String helperAccount = paymentData['helperAccount'] ?? '도우미 계좌 없음';
      String cost = paymentData['cost'] ?? '0'; // 비용은 문자열로 저장되므로 필요에 따라 변환 가능



      showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              File? imageFile;

              Future<void> _pickImageAndShowPreview() async {
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(
                    source: ImageSource.camera);
                if (pickedFile != null) {
                  setState(() {
                    imageFile = File(pickedFile.path);
                  });

                  bool shouldUpload = await showDialog(
                    context: context,
                    builder: (context) =>
                        AlertDialog(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          title: Text(
                            '사진 확인',
                            style: TextStyle(fontWeight: FontWeight.bold,
                                fontSize: 24,
                                color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                          content: Container(
                            height: 350,
                            width: double.infinity,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25.0),
                              child: Image.file(imageFile!, fit: BoxFit.cover),
                            ),
                          ),
                          actionsAlignment: MainAxisAlignment.spaceEvenly,
                          actions: <Widget>[
                            ElevatedButton.icon(
                              icon: Icon(Icons.send, color: Colors.white,),
                              label: Text('보내기', style: TextStyle(color: Colors.white),),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1D4786),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                              onPressed: () async {
                                HapticFeedback.lightImpact();

                                //메시지 저장(채팅 메시지)
                                Reference storageReference = FirebaseStorage.instance
                                    .ref()
                                    .child('images/$documentName/${DateTime
                                    .now()
                                    .millisecondsSinceEpoch}');
                                UploadTask uploadTask = storageReference.putFile(imageFile!);
                                TaskSnapshot taskSnapshot = await uploadTask;
                                String downloadUrl = await taskSnapshot.ref.getDownloadURL();
                                await FirebaseFirestore.instance
                                    .collection('ChatActions')
                                    .doc(documentName)
                                    .collection('messages')
                                    .add({
                                  'senderName': helperNickname,
                                  'photoUrl': downloadUrl,
                                  'senderUid': FirebaseAuth.instance.currentUser?.uid,
                                  'timestamp': FieldValue.serverTimestamp(),
                                  'type': 'image',
                                  'message': '사진',
                                  'read': false,
                                  'isDeleted': false,
                                });

                                //메시지 저장(채팅 목록)
                                await _sendMessage(documentName, helperNickname, ownerNickname, helperUid,
                                    ownerUid, helperBank, helperAccount, cost);

                                Navigator.of(context).pop(true);
                              },
                            ),
                            ElevatedButton.icon(
                              icon: Icon(Icons.cancel, color: Colors.white,),
                              label: Text('취소', style: TextStyle(color: Colors.white),),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop(false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("사진 전송이 취소되었습니다.",
                                        textAlign: TextAlign.center),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                  );


                  if (shouldUpload) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            "이미지 업로드 중입니다. \n알림창을 닫지 마시고 잠시만 기다려 주세요.",
                            textAlign: TextAlign.center),
                        duration: Duration(seconds: 3),
                      ),
                    );
                    await FirebaseFirestore.instance.collection('ChatActions').doc(documentName).update(
                        {
                          'success_trade': true,
                        });


                    if (paymentData['isPaymentRequested'] == null || paymentData['isPaymentRequested'] == false){
                      await FirebaseFirestore.instance.collection('Payments').doc(documentName).update(
                          {
                            'isPaymentRequested': true,
                          });
                    }


                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('정산 요청이 완료되었습니다. \n정산 요청 완료 버튼을 눌러주세요.',
                            textAlign: TextAlign.center),
                        duration: Duration(seconds: 2),
                      ),
                    );

                    setState(() {
                      isPhotoSent = true;
                    });
                  }
                }
              }

              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: Center(
                  child: Text(
                    '사진 전송 및 정산',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      Center(
                        child: Text(
                          '도움을 주셔서 감사합니다! \n사진 전송 시 정산 요청이 진행됩니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.black54,
                            height: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF1D4786),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(isPhotoSent ? '정산 요청 완료' : '사진 촬영하기',
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                          onPressed: () async { //사진을 보냈을 경우 클릭 o
                            HapticFeedback.lightImpact();
                            if (isPhotoSent) { // true 가 사진 보냈을때
                              Navigator.of(context).pop();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AllUsersScreen()),
                              );
                            }
                            else {
                              await _pickImageAndShowPreview();
                            }
                          }
                      ),
                    ],
                  ),
                ),
                actions: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey, // 버튼 색상 변경
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), // 버튼 모서리 둥글게
                      ),
                    ),
                    child: Text(
                        '닫기', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop(); // 대화 상자 닫기
                    },
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }



  //삭제하는 부분
  // helper의 isDeleted_ 활성화
  Future<void> helperDeletePayment(String documentId, String helperNickname) async {
    await FirebaseFirestore.instance.collection('Payments').doc(documentId).update({
      'isDeleted_$helperNickname': true
    });
  }

  //owner의 isDeleted_ 활성화
  Future<void> ownerDeletePayment(String documentId, String ownerNickname) async {
    await FirebaseFirestore.instance.collection('Payments').doc(documentId).update({
      'isDeleted_$ownerNickname' : true

    });
  }



  //게시글 내용
  Widget _buildPostCard({
    required String docName,
    required String owner_email_nickname,
    required String timeAgo,
    required String storeName,
    required String location,
    required String cost,
    required String helper_email_nickname,
    required bool isHelper,
    required String orderPhotoUrl,
    required String helperPhotoUrl,
    required bool isRequested,
    required bool nicknameColorIsOwner,

  }) {

    return Container(
      margin: EdgeInsets.fromLTRB(
          0,
          0,
          0,
          MediaQuery.of(context).size.height * 0.02),
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFD0D0D0)),
        borderRadius: BorderRadius.circular(12),
        color: Color(0xFFFFFFFF),
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(15, 15, 15, 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 0, 7, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF1D4786), Color(0xFF1D4786)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              (orderPhotoUrl != null && orderPhotoUrl.isNotEmpty)
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
                            radius: 16, // 반지름 설정 (32 / 2)
                            backgroundColor: Colors.grey[200],
                            child: ((nicknameColorIsOwner ? orderPhotoUrl : helperPhotoUrl) != null && (nicknameColorIsOwner ? orderPhotoUrl : helperPhotoUrl).isNotEmpty)
                                ? null
                                : Icon(
                              Icons.account_circle,
                              size: 32, // 원래 코드에서 width와 height가 32였으므로 여기에 맞춤
                              color: Color(0xFF1D4786),
                            ),
                            backgroundImage: nicknameColorIsOwner
                                ? (orderPhotoUrl != null && orderPhotoUrl.isNotEmpty)
                                  ? NetworkImage(orderPhotoUrl)
                                  : null
                                : (helperPhotoUrl != null && helperPhotoUrl.isNotEmpty)
                                  ? NetworkImage(helperPhotoUrl)
                                  : null
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 8, 0, 8),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text : nicknameColorIsOwner ? '${owner_email_nickname}' : '${helper_email_nickname}',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  height: 1,
                                  letterSpacing: -0.5,
                                  color: Color(0xFF1D4786),
                                ),
                              ),
                              TextSpan(
                                text : nicknameColorIsOwner ? ' (오더)' : ' (헬퍼)',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w600,// 작은 글씨는 일반적인 가중치로 설정
                                  fontSize: 13, // 작은 글씨 크기 설정
                                  color: Colors.grey, // 회색으로 설정
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 10, 0, 9),
                    child: Text(
                      timeAgo,
                      style: TextStyle(
                        fontFamily: 'Pretendard', // Pretendard 폰트 지정
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height: 1,
                        letterSpacing: -0.5,
                        color: Color(0xFFAAAAAA),
                      ),

                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              width: double.infinity,
              height: 1,
              color: Color(0xFFF6F6F6),
            ),
            _buildInfoRow(
              iconPath: 'assets/pigma/vuesaxbulkhouse.svg',
              label: '픽업 장소',
              value: storeName,
            ),
            _buildInfoRow(
              iconPath: 'assets/pigma/location.svg',
              label: '드랍 장소',
              value: location,
            ),
            _buildInfoRow(
              iconPath: 'assets/pigma/dollar_circle.svg',
              label: '헬퍼비',
              value: cost,
            ),
            //헬퍼는 프로필 사진도 넣야해서 따로
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 0, 7, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF1D4786), Color(0xFF1D4786)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              (helperPhotoUrl != null && helperPhotoUrl.isNotEmpty)
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
                            radius: 12, // 반지름 설정 (32 / 2)
                            backgroundColor: Colors.grey[200],
                            child: ((nicknameColorIsOwner ? helperPhotoUrl : orderPhotoUrl) != null && (nicknameColorIsOwner ? helperPhotoUrl : orderPhotoUrl).isNotEmpty)
                                ? null
                                : Icon(
                              Icons.account_circle,
                              size: 24, // 원래 코드에서 width와 height가 32였으므로 여기에 맞춤
                              color: Color(0xFF1D4786),
                            ),
                            backgroundImage: nicknameColorIsOwner
                                ? (helperPhotoUrl != null && helperPhotoUrl.isNotEmpty)
                                  ? NetworkImage(helperPhotoUrl)
                                : null
                                : (orderPhotoUrl != null && orderPhotoUrl.isNotEmpty)
                                  ? NetworkImage(orderPhotoUrl)
                                : null

                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                        child: Text(
                          nicknameColorIsOwner ? '헬퍼' :'오더',
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
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                    child: Text(
                      nicknameColorIsOwner ? '${helper_email_nickname}' : '${owner_email_nickname}',
                      style:TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1,
                        letterSpacing: -0.1,
                        color: Color(0xFF222222),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              width: double.infinity,
              height: 1,
              color: Color(0xFFF6F6F6),
            ),
            GestureDetector(

              onTap: () async {
                HapticFeedback.lightImpact();
                if (isHelper) // 헬퍼일 경우
                {
                  requestAndPayDialog(context, true, docName, true, orderPhotoUrl, helperPhotoUrl);
                }
                else //오더일 경우
                {
                  String result = await checkRequestPayment(docName);
                  if (result == 'not requested') { // 상대방이 결제요청 안한 상황 -> 푸시알림 보낼거냐는 다이어로그 & 스낵바
                    requestAndPayDialog(context, false, docName, false, orderPhotoUrl, helperPhotoUrl);


                  } else if (result == 'updated') { // 상대방이 결제요청 안하고 이미 푸시알림 전송한 상황 - 스낵바
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "상대방에게 결제 요청이 이미 전송된 상태입니다.",
                          textAlign: TextAlign.center,
                        ),
                        duration: Duration(seconds: 1),
                      ),
                    );

                  } else if (result == 'already requested'){ // 상대방이 결제요청한 상황 -> 별점 매기는 스크린
                    requestAndPayDialog(context, false, docName, true, orderPhotoUrl, helperPhotoUrl);

                  }
                }
              },
              child: Container(
                margin: EdgeInsets.fromLTRB(0, 10, 0, 15),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFFE8EFF8)),
                  borderRadius: BorderRadius.circular(8),
                  color: Color(0xFFE8EFF8),
                ),
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.06,
                  child: Center(child:
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('Payments').doc(docName).snapshots(),
                    builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator(); // 로딩 상태 표시
                      }

                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (snapshot.hasData) {
                        var paymentData = snapshot.data!.data() as Map<String, dynamic>;
                        bool? isPaymentRequested = paymentData['isPaymentRequested'] ?? null;

                        return Text(
                          isHelper
                              ? (isPaymentRequested == true
                                ? '결제 대기중'
                                : (isPaymentRequested == false ? '결제 요청하기' : '결제 요청하기'))
                              : (isPaymentRequested == true
                                ? '결제하기'
                                : (isPaymentRequested == false ? '결제요청 완료' : '결제하기')),


                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            height: 1,
                            letterSpacing: -0.4,
                            color: Color(0xFF1D4786),
                          ),
                        );
                      }

                      return Text('결제 정보 없음');
                    },
                  ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //게시글 구조
  Widget _buildInfoRow({
    required String iconPath,
    required String label,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(0, 0, 6, 0),
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                child: Text(
                  label,
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
            ],
          ),
          Container(
            margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
            child: Text(
              value,
              style:TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1,
                letterSpacing: -0.1,
                color: Color(0xFF222222),
              ),
            ),
          ),
        ],
      ),
    );
  }


  //결제 수단 고르기 - 오너
  void _selectPaymentMethod(BuildContext context,String docName,String ownerEmail, String helperEmail,
      String helperNickname, String ownerNickname, String storeName, String location, String cost, String ownerPhotoUrl, String helperPhotoUrl) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      builder: (BuildContext context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              decoration: BoxDecoration(
                color: Color(0xFFFFFFFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: screenHeight * 0.015),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFE3E3E3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      width: screenWidth * 0.12,
                      height: screenHeight * 0.005,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.045,
                          vertical: screenHeight * 0.04,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                              child: Text(
                                '결제 수단 선택',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w600,
                                  fontSize: screenWidth * 0.045,
                                  height: 1,
                                  letterSpacing: -0.5,
                                  color: Color(0xFF1D4786),
                                ),
                              ),
                            ),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '상대방이 결제를 요청할 시 채팅방을 통해 \n계좌이체를 진행해주시면 됩니다.',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w600,
                                      fontSize: screenWidth * 0.04,
                                      height: 1.4,
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                  TextSpan(
                                    text: '\n\n⚠️카카오페이와 토스페이 결제는 빠른 시일 내에 출시 될 예정입니다.',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.normal,
                                      fontSize: screenWidth * 0.03,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  selectedMethod = 'bankTransfer';
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(
                                  left: screenWidth * 0.04,
                                  right: screenWidth * 0.02,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: selectedMethod == 'bankTransfer'
                                        ? Color(0xFF1D4786)
                                        : Color(0xFFE3E3E3),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Color(0xFFFFFFFF),
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.025,
                                  ),
                                  child: Text(
                                    '계좌이체',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w500,
                                      fontSize: screenWidth * 0.04,
                                      height: 1,
                                      letterSpacing: -0.4,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: selectedMethod == 'kakaoPay'
                                        ? Color(0xFF1D4786)
                                        : Color(0xFFE3E3E3),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Color(0xFFFFFFFF),
                                ),
                                child: Container(
                                  height: screenHeight * 0.068,
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.021,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        fit: BoxFit.contain,
                                        image: AssetImage(
                                          'assets/images/payment_icon_yellow_medium.png',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                margin: EdgeInsets.only(
                                  left: screenWidth * 0.02,
                                  right: screenWidth * 0.04,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: selectedMethod == 'tossPay'
                                        ? Color(0xFF1D4786)
                                        : Color(0xFFE3E3E3),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Color(0xFFFFFFFF),
                                ),
                                child: Container(
                                  height: screenHeight * 0.068,
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.025,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        fit: BoxFit.contain,
                                        image: AssetImage(
                                          'assets/images/logo-toss-pay.png',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFF6F7F8),
                                  border: Border.all(color: Color(0xFFF6F7F8)),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.02,
                                ),
                                child: Text(
                                  '취소',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w600,
                                    fontSize: screenWidth * 0.045,
                                    letterSpacing: -0.5,
                                    color: Color(0xFF222222),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                if (selectedMethod == 'bankTransfer') {
                                  // Navigator.pop(context);
                                  // 새 화면으로 이동
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) =>
                                        RateUserScreen(docName,ownerEmail, helperEmail, helperNickname, ownerNickname, storeName, location, cost, ownerPhotoUrl, helperPhotoUrl)),
                                  );

                                  print(1);
                                }
                                else if (selectedMethod == 'kakaoPay') {
                                  // 카카오페이 처리 로직
                                  print('카카오페이 선택됨');
                                } else if (selectedMethod == 'tossPay') {
                                  // 토스페이 처리 로직
                                  print('토스페이 선택됨');
                                }

                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFF1D4786),
                                  border: Border.all(color: Color(0xFF1D4786)),
                                ),
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.02,
                                ),
                                child: Text(
                                  '확인',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w600,
                                    fontSize: screenWidth * 0.045,
                                    letterSpacing: -0.5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.045),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  // 요청 or 결제 -> request true일 경우 요청 false일 경우 결제
  Future<void> requestAndPayDialog(BuildContext context, bool isHelper, String docName, bool isRequested, String orderPhotoUrl, String helperPhotoUrl) async {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance.collection('Payments').doc(docName).get();
    Map<String, dynamic> paymentData = documentSnapshot.data() as Map<String, dynamic>;
    String ownerEmail = paymentData['owner_email'] ?? '오너 이메일 없음';
    String helperEmail = paymentData['helper_email'] ?? '헬퍼 이메일 없음';
    String helperNickname = paymentData['helper_email_nickname'] ?? '헬퍼 닉네임 없음';
    String ownerNickname = paymentData['owner_email_nickname'] ?? '오너 닉네임 없음';
    String storeName = paymentData['post_store'] ?? '가게 이름 없음';
    String location = paymentData['orderer_location'] ?? '위치 정보 없음';
    String cost = paymentData['cost'] ?? '비용 정보 없음';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              SizedBox(height: MediaQuery.of(context).size.height*0.07),
               Text(
                 isHelper
                     ? '결제를 요청하시겠어요?'
                     : (isRequested
                          ? '결제를 하시겠어요?'
                          : '상대방이 결제요청을 해야 \n결제를 진행할 수 있습니다.\n결제 요청 알림을 보내시겠어요?'),
                 textAlign: TextAlign.center,
                 style: TextStyle(
                     fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: isRequested ? 17 : 16,
                      height: isRequested ?1 : 1.3,
                      letterSpacing: -0.1,
                      color: Color(0xFF222222),
                    ),
                  ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.055),
                Divider(color: Colors.grey, height: 1),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                        ),
                        child: Center(
                          child: Text(
                            '취소',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF636666),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1.0, // 구분선의 두께
                      height: 55, // 구분선의 높이
                      color: Colors.grey, // 구분선의 색상
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          if (isHelper) {
                            _showHelperPaymentDialog(context, docName);
                            Navigator.of(context).pop();
                          }
                          else {
                            if(isRequested){
                              //상대방이 결제요청 o 평점스크린으로 이동
                              _selectPaymentMethod(context,docName,ownerEmail, helperEmail, helperNickname, ownerNickname, storeName, location,  cost, orderPhotoUrl, helperPhotoUrl);
                            }
                            else{
                              // 결제요청 x 결제해달라는 알림
                              await FirebaseFirestore.instance.collection('Payments').doc(docName).update(
                                  {
                                    'isPaymentRequested': false,
                                  });
                              Navigator.of(context).pop(); // 다이얼로그 닫기
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "상대방에게 결제 요청 알림이 전송되었습니다.",
                                    textAlign: TextAlign.center,
                                  ),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }

                          }
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                        ),
                        child: Center(
                          child: Text(
                            '확인',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1D4786),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: RichText(
              text: TextSpan(
                text: '총 ',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  height: 1,
                  letterSpacing: -0.5,
                  color: Color(0xFF222222),
                ),
                children: [
                  TextSpan(
                    text: '${acceptedPayments.length}건',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      height: 1.3,
                      letterSpacing: -0.5,
                      color: Color(0xFF1D4786),
                    ),
                  ),
                  TextSpan(
                    text: '의 수락건이 있어요!',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      height: 1,
                      letterSpacing: -0.5,
                      color: Color(0xFF222222),
                    ),
                  ),
                ],
              ),
            ),
          ),


          // ListView.builder를 Expanded로 감싸기
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: acceptedPayments.isEmpty
                  ? Align(
                alignment: Alignment.center,
                child: Container(
                  width: 300,
                  height: 200,
                  child: Text(
                    '현재 수락된 요청이 없습니다. \n새로운 요청을 수락하시면\n이곳에서 확인하실 수 있습니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'NanumSquareRound',
                      color: Color(0xFF1D4786),
                    ),
                  ),
                ),
              )
                  : ListView.builder(
                controller: _scrollController,
                itemCount: acceptedPayments.length,
                itemBuilder: (context, index) {
                  var paymentData = acceptedPayments[index].data() as Map<String, dynamic>;
                  bool isHelper = paymentData['helper_email'] == email;
                  bool isRequested = paymentData['isPaymentRequested'] == true;

                  // 두 개의 Future를 동시에 처리
                  return FutureBuilder<List<String?>>(
                    future: Future.wait([
                      _getProfileImage(paymentData['owner_email']),  // 첫 번째 Future
                      _getProfileImage(paymentData['helper_email']), // 두 번째 Future
                    ]),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());  // 로딩 중 표시
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text("Error occurred: ${snapshot.error}"));
                      }
                      else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            '수락된 데이터가 아직 없습니다! \n거래를 진행해 주세요!',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      if (snapshot.hasData) {
                        List<String?> profileUrls = snapshot.data!;
                        String? orderPhotoUrl = profileUrls[0];  // 주문자 프로필 이미지
                        String? helperPhotoUrl = profileUrls[1]; // 헬퍼 프로필 이미지
                        bool nicknameColorIsOwner = false;
                        if(myNickname == paymentData['owner_email_nickname']){
                          nicknameColorIsOwner = true;
                        }
                        else if(myNickname ==paymentData['helper_email_nickname']){
                          nicknameColorIsOwner = false;
                        }



                        if (paymentData['helper_email'] == email && paymentData['isDeleted_${paymentData['helper_email_nickname']}'] == true) {
                          return Container(); // 삭제된 경우 빈 컨테이너 반환
                        }
                        if (paymentData['owner_email'] == email && paymentData['isDeleted_${paymentData['owner_email_nickname']}'] == true) {
                          return Container(); // 삭제된 경우 빈 컨테이너 반환
                        }

                        return _buildPostCard(
                          docName: paymentData['docName'],
                          owner_email_nickname: paymentData['owner_email_nickname'] ?? '사용자 이름 없음',
                          timeAgo: DateFormat('yyyy-MM-dd HH:mm').format(paymentData['timestamp'].toDate()),
                          storeName: paymentData['post_store'] ?? '가게 이름 없음',
                          location: paymentData['orderer_location'] ?? '위치 정보 없음',
                          cost: paymentData['cost'] ?? '비용 정보 없음',
                          helper_email_nickname: paymentData['helper_email_nickname'] ?? '사용자 이름 없음',
                          isHelper: isHelper,
                          orderPhotoUrl: orderPhotoUrl ?? '사용자 사진 없음',
                          helperPhotoUrl: helperPhotoUrl ?? '사용자 사진 없음',
                          isRequested: isRequested,
                          nicknameColorIsOwner: nicknameColorIsOwner,
                        );
                      }

                      return SizedBox();  // 데이터가 없을 경우
                    },
                  );
                },
              ),
            ),
          ),

        ],
      ),
    );
  }


  }
