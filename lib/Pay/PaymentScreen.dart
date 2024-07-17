import 'dart:async';
import 'dart:io';

import 'package:OnTheWay/Pay/KaKaoPay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:rxdart/rxdart.dart';

import '../Board/UiBoard.dart';
import '../Chat/AllUsersScreen.dart';
import '../Chat/ChatScreen.dart';
import '../Chat/Message.dart';
import '../HanbatSchoolBoard/HanbatUiBoard.dart';
import '../Profile/Profile.dart';
import '../Ranking/SchoolRanking.dart';

class PaymentStatusScreen extends StatefulWidget {
  @override
  _PaymentStatusScreenState createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 바텀 네비게이션 인덱스
  int _selectedIndex = 1; // 기본 선택된 항목을 '게시판'으로 설정
  String botton_email = ""; // 사용자의 이메일을 저장할 변수
  String botton_domain = ""; // 사용자의 도메인을 저장할 변수

  //ui 변수
  List<DocumentSnapshot> acceptedPayments = [];
  late StreamSubscription<dynamic> _paymentsSubscription; // Firestore 스트림 구독을 위한 변수

  //오더용 페이 선택 변수
  String selectedPayment = "";

  //사진 전송 변수
  bool isPhotoSent = false;

  @override
  void initState() {
    super.initState();
    // 로그인 시 설정된 이메일 및 도메인 가져오기 -> 바텀 네비게이션 이용시 사용
    final FirebaseAuth _auth = FirebaseAuth.instance;
    botton_email = _auth.currentUser?.email ?? "";
    botton_domain = botton_email
        .split('@')
        .last
        .toLowerCase();


    _fetchPayments(); // 정보가져
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
      var combinedDocs = {...helperSnapshot.docs, ...ownerSnapshot.docs}.toList();


      // 위젯이 화면에 여전히 존재하는 경우에만 상태를 업데이트합니다.
      if (mounted) {
        setState(() {
          acceptedPayments = combinedDocs;
        });
      }
    }
    ).listen(
          (data) {},
      onError: (error) {
        // 스트림에서 오류가 발생한 경우 로그를 출력합니다.
        print("An error occurred: $error");
      },
    );
  }






  // 페이 다이어로그 - 오더용
  void _showOrdererPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Center(
                child:Text(
                    '결제 수단 선택',
                    style: TextStyle(
                      fontFamily: 'NanumSquareRound',
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
                        '다른 학생에게 도움을 주셔서 감사드립니다.\n덕분에 자영업자분들도 배달 수수료 \n부담을 덜 수 있었습니다.\n '
                            '마지막으로 결제를 완료하면 \n거래가 종료됩니다. 감사합니다!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'NanumSquareRound',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: 15,),
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Image.asset('assets/images/payment_icon_yellow_large.png', height: 25),
                          SizedBox(width: 10),
                          Text('카카오페이',
                            style: TextStyle(
                            fontFamily: 'NanumSquareRound',
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Colors.black87,
                          ),
                        ),
                        ],
                      ),
                      value: 'kakaopay',
                      groupValue: selectedPayment,
                      onChanged: (String? value) {
                        setState(() {
                          HapticFeedback.lightImpact();
                          selectedPayment = value!;
                        });
                      },
                      activeColor: Colors.indigo,
                    ),
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Image.asset('assets/images/Toss_Symbol_Primary.png', height: 25),
                          SizedBox(width: 10),
                          Text('토스페이',
                            style: TextStyle(
                            fontFamily: 'NanumSquareRound',
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: Colors.black87,
                          ),),
                        ],
                      ),
                      value: 'tosspay',
                      groupValue: selectedPayment,
                      onChanged: (String? value) {
                        setState(() {
                          HapticFeedback.lightImpact();
                          selectedPayment = value!;
                        });
                      },
                      activeColor: Colors.indigo,
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      backgroundColor: Colors.indigo[600],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      '선택',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRound',
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      if (selectedPayment == 'kakaopay') {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => KaKaoPay(),
                        ));
                        print('카카오페이');

                      } else if (selectedPayment == 'tosspay') {
                        HapticFeedback.lightImpact();
                        // Navigator.push(
                        //     context,
                        //     MaterialPageRoute(builder: (context) => KaKaoPay(),
                        //     ));
                        Navigator.of(context).pop();
                      }

                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      '닫기',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRound',
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ],
            );
          },
        );
      },
    );
  }


  //메시지 객체 생성 후(사진) 메시지 전송에 보냄
  void _sendMessage(String documentName, String senderName, String receiverName, String senderUid, String receiverUid) {
    DateTime now = DateTime.now();
    Timestamp timestamp = Timestamp.fromDate(now); // DateTime을 Timestamp로 변환

    // 텍스트 메시지 객체 생성
    Message message = Message(
      receiverName : receiverName,
      senderName : senderName,
      receiverUid: receiverUid,
      senderUid: senderUid,
      message: '사진',
      timestamp: timestamp,
      read : false,
      type : 'text',
      isDeleted : false,
    );

    // _addMessageToDb 함수를 사용하여 메시지 추가
    _addMessageToDb(message, documentName);

  }

  //채팅 목록에 1 표시 및 미리보기 메시지를 위해 설정
  void _addMessageToDb(Message message, String documentName) async {
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
  void _showHelperPaymentDialog(BuildContext context, String documentName, String senderName, String receiverName, String senderUid, String receiverUid) {
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
                            icon: Icon(Icons.send),
                            label: Text('보내기'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
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
                      content: Text("이미지 업로드 중입니다. \n알림창을 닫지 마시고 잠시만 기다려 주세요.",
                          textAlign: TextAlign.center),
                      duration: Duration(seconds: 3),
                    ),
                  );

                  //메시지 저장(채팅 목록)
                  _sendMessage(documentName, senderName, receiverName, senderUid, receiverUid);

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
                    'senderName': senderName,
                    'photoUrl': downloadUrl,
                    'senderUid': FirebaseAuth.instance.currentUser?.uid,
                    'timestamp': FieldValue.serverTimestamp(),
                    'type': 'image',
                    'read': false,
                    'isDeleted': false,
                    'type': 'request',
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("이미지 업로드 완료!", textAlign: TextAlign.center),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Center(
                child: Text(
                  '사진 전송 및 정산',
                  style: TextStyle(
                    fontFamily: 'NanumSquareRound',
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
                        '다른 학생에게 도움을 주셔서 감사드립니다.\n덕분에 자영업자분들도 배달 수수료 \n부담을 덜 수 있었습니다.\n '
                            '마지막으로 전달 완료한 사진을 \n전달해주시면 정산 요청이 가능합니다.\n감사합니다!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'NanumSquareRound',
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
                        backgroundColor: isPhotoSent ? Colors.grey : Colors
                            .indigo[500],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        '완료 사진 전송',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      onPressed: isPhotoSent
                          ? null
                          : () async {
                        HapticFeedback.lightImpact();
                        await _pickImageAndShowPreview();
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPhotoSent
                            ? Colors.indigo[500]
                            : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(
                        '정산 요청하기',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      onPressed: isPhotoSent
                          ? () { //사진을 보냈을 않을 경우 클릭 o
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('정산이 요청이 완료되었습니다.',
                                textAlign: TextAlign.center),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                          : null, //사진을 보내지 않을 경우 클릭 x

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
                      '닫기', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildPaymentCard(Map<String, dynamic> paymentData, bool isHelper) {
    int intCost = _extractCostAsInt('${paymentData['cost']}');
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 7,
      margin: EdgeInsets.fromLTRB(0,0,0,20), // 카드 위아래에 간격 추가
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '오더: ',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRound',
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: isHelper ? Colors.black :Colors.indigo[900] //salmon색
                      ),
                    ),
                    TextSpan(
                      text: '${paymentData['owner_email_nickname']}',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRound',
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: isHelper ? Colors.black : Colors.indigo[900]
                      ),
                    ),
                    TextSpan(
                      text: '   ⇢   ',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRound',
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: Colors.black
                      ),
                    ),
                    TextSpan(
                      text: '헬퍼: ',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRound',
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: isHelper ? Colors.indigo[900] : Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: '${paymentData['helper_email_nickname']}',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRound',
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: isHelper ? Colors.indigo[900] : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Divider(thickness: 2),
            SizedBox(height: 10),
            Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${paymentData['post_store']}',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRound',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Colors.indigo[900],
                      ),
                    ),
                    TextSpan(
                      text: '  ⇢  ',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRound',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: '${paymentData['orderer_location']}',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRound',
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Colors.indigo[900],
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 7),
            Divider(thickness: 2),
            SizedBox(height: 7),
            Center(
              child: Text(
                '금액 : $intCost원',
                style: TextStyle(
                  fontFamily: 'NanumSquareRound',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Color(0xFFF84A38)
                  // Color(0xFFF52613)
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 10),
            Divider(thickness: 3),
            SizedBox(height: 10),
            Center(
              child: SizedBox(
                width: double.infinity, // 너비를 부모의 너비로 설정
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                        isHelper ? _showHelperPaymentDialog(context, paymentData['docName'],
                                    isHelper ? paymentData['helper_email_nickname'] :paymentData['owner_email_nickname'],
                                    isHelper ? paymentData['owner_email_nickname'] :paymentData['helper_email_nickname'],
                                    isHelper ? paymentData['helperUid'] :paymentData['ownerUid'],
                                    isHelper ? paymentData['ownerUid'] :paymentData['helperUid']
                    )
                             : _showOrdererPaymentDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    backgroundColor: Colors.indigo[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                  ),
                  icon: Icon(Icons.payment), // 버튼 아이콘
                  label: Text(
                    isHelper ? '결제 요청하기' : '결제하기',
                    style: TextStyle(
                      fontFamily: 'NanumSquareRound',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Stack(
          children: [
            Positioned.fill(
              child: Lottie.asset(
                'assets/lottie/login.json',
                fit: BoxFit.fill,
              ),
            ),
            AppBar(
              backgroundColor: Colors.transparent,
              title: Text(
                "진행 상황",
                style: TextStyle(
                  fontFamily: 'NanumSquareRound',
                  fontWeight: FontWeight.w600,
                  fontSize: 25,
                ),
              ),
              centerTitle: true,
              automaticallyImplyLeading: false, // '<' 이 뒤로가기 버튼 삭제
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child:ListView.builder(
        itemCount: acceptedPayments.length,
        itemBuilder: (context, index) {
          var paymentData = acceptedPayments[index].data() as Map<String, dynamic>;
          bool isHelper = paymentData['helper_email'] == botton_email;
          return _buildPaymentCard(paymentData, isHelper);
        },
      ),
      ),



      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_rounded,
                color: _selectedIndex == 0 ? Colors.indigo : Colors.black),
            label: '채팅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hourglass_empty_rounded,
                color: _selectedIndex == 1 ? Colors.indigo : Colors.black),
            //search
            label: '진행 상황',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined,
                color: _selectedIndex == 2 ? Colors.indigo : Colors.black),
            label: '게시판',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school,
                color: _selectedIndex == 3 ? Colors.indigo : Colors.black),
            label: '학교 랭킹',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person,
                color: _selectedIndex == 4 ? Colors.indigo : Colors.black),
            label: '프로필',
          ),
        ],
        selectedLabelStyle: TextStyle(
          fontFamily: 'NanumSquareRound',
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'NanumSquareRound',
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        selectedItemColor: Colors.indigo,
        // 선택된 항목의 텍스트 색상
        unselectedItemColor: Colors.black,
        // 선택되지 않은 항목의 텍스트 색상

        currentIndex: _selectedIndex,

        onTap: (index) {
          if (_selectedIndex == index) {
            // 현재 선택된 탭을 다시 눌렀을 때 아무 동작도 하지 않음
            return;
          }

          setState(() {
            _selectedIndex = index;
          });

          // 채팅방으로 이동
          if (index == 0) {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AllUsersScreen()),
            );
          }
          //진행 상황
          else if (index == 1) {
            HapticFeedback.lightImpact();

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PaymentStatusScreen()),
            );
          }


          //새 게시글 만드는 곳으로 이동
          else if (index == 2) {
            HapticFeedback.lightImpact();
            switch (botton_domain) {
              case 'naver.com':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HanbatBoardPage()),
                );
                break;
            // case 'hanbat.ac.kr':
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (context) => HanbaBoardPage()),
            //   );
            //   break;
              default:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BoardPage()),
                );
                break;
            }
          }

          // 학교 랭킹
          else if (index == 3) {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SchoolRankingScreen()),
            );
          }
          // 프로필
          else if (index == 4) {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserProfileScreen()),
            );
          }
        },
      ),
    );
  }
}
