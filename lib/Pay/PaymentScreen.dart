import 'dart:async';
import 'dart:io';

import 'package:OnTheWay/Pay/KaKaoPay.dart';
import 'package:OnTheWay/Pay/TossPay.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:rxdart/rxdart.dart';

import '../Board/UiBoard.dart';
import '../Chat/AllUsersScreen.dart';
import '../Chat/ChatScreen.dart';
import '../Chat/Message.dart';
import '../HanbatSchoolBoard/HanbatSchoolBoard.dart';
import '../Profile/Profile.dart';
import '../Ranking/DepartmentRanking.dart';

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
  void _showOrdererPaymentDialog(BuildContext context, String documentId, String ownerNickname) {
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
                        '상대방이 결제를 요청할 시 채팅방을 통해\n 계좌이체를 진행해 주시면 됩니다.\n카카오페이와 토스페이 결제는 \n빠른 시일 내에 출시 될 예정입니다.\n감사합니다.',
                        // '다른 학생에게 도움을 주셔서 감사드립니다.\n덕분에 자영업자분들도 배달 수수료 \n부담을 덜 수 있었습니다.\n '
                        //     '마지막으로 결제를 완료하면 \n거래가 종료됩니다. 감사합니다',
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
                          Icon(Icons.account_balance_outlined),
                          SizedBox(width: 10),
                          Text('계좌 이체',
                            style: TextStyle(
                              fontFamily: 'NanumSquareRound',
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      value: 'Transfer',
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
                          Image.asset('assets/images/payment_icon_yellow_large.png', height: 25),
                          SizedBox(width: 10),
                          Text('카카오페이',
                            style: TextStyle(
                            fontFamily: 'NanumSquareRound',
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Colors.grey,
                          ),
                        ),
                        ],
                      ),
                      value: 'kakaopay',
                      groupValue: selectedPayment,
                      onChanged: null,  // 비활성화 상태로 설정
                      activeColor: Colors.grey,  // 비활성화 색상
                      // onChanged: (String? value) {
                      //   setState(() {
                      //     HapticFeedback.lightImpact();
                      //     selectedPayment = value!;
                      //   });
                      // },
                      // activeColor: Colors.indigo,
                    ),
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Image.asset('assets/images/Toss_Symbol_Primary.png', height: 25),
                          SizedBox(width: 10),
                          Text('토스페이',
                            style: TextStyle(
                            fontFamily: 'NanumSquareRound',
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Colors.grey,
                          ),),
                        ],
                      ),
                      value: 'tosspay',
                      groupValue: selectedPayment,
                      onChanged: null,  // 비활성화 상태로 설정
                      activeColor: Colors.grey,  // 비활성화 색상
                      //아직 미출시
                      // onChanged: (String? value) {
                      //   setState(() {
                      //     HapticFeedback.lightImpact();
                      //     selectedPayment = value!;
                      //   });
                      // },
                      // activeColor: Colors.indigo,
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
                      if(selectedPayment == 'Transfer'){
                        //결제내역 삭제
                        ownerDeletePayment(documentId, ownerNickname);
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AllUsersScreen(),
                            ));
                      }
                      // if (selectedPayment == 'kakaopay') {
                      //   HapticFeedback.lightImpact();
                      //   Navigator.of(context).pop();
                      //   // Navigator.push(
                      //   //   context,
                      //   //   MaterialPageRoute(builder: (context) => KaKaoPay(),
                      //   // ));

                      //
                      // } else if (selectedPayment == 'tosspay') {
                      //   HapticFeedback.lightImpact();
                      //   Navigator.of(context).pop();
                      //   // Navigator.push(
                      //   //     context,
                      //   //     MaterialPageRoute(builder: (context) => TossPay(),
                      //   //     ));

                      // }

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
  void _showHelperPaymentDialog(BuildContext context, String documentName, String helperNickname, String ownerNickname, String helperUid, String ownerUid
      ,String helperBank, String helperAccount, String cost) {
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
//메시지 저장(채팅 목록)
                await _sendMessage(documentName, helperNickname, ownerNickname, helperUid, ownerUid, helperBank, helperAccount, cost);

                if (shouldUpload) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("이미지 업로드 중입니다. \n알림창을 닫지 마시고 잠시만 기다려 주세요.",
                          textAlign: TextAlign.center),
                      duration: Duration(seconds: 3),
                    ),
                  );


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
                            '마지막으로 전달 완료한 사진을 \n전달하시면 정산 요청도 함께 보내집니다.\n감사합니다.',
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
                        backgroundColor: isPhotoSent ? Colors.indigo[500] : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: Text(isPhotoSent ? '정산 요청 완료' : '정산 요청하기',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      onPressed: () async { //사진을 보냈을 경우 클릭 o
                        HapticFeedback.lightImpact();
                        if (isPhotoSent) {// true 가 사진 보냈을때
                          helperDeletePayment(documentName, helperNickname);
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AllUsersScreen()),
                              );
                            }
                        else {
                              await _pickImageAndShowPreview();}
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

  // 결제 내역  삭제하기 dialog
  void showDeletePaymentDialog(BuildContext context, String documentId, String nickname, bool isHelper) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            '결제내역 삭제하기',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'NanumSquareRound',
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          content: Text(
            '정산 요청이 완료되면 자동으로 삭제됩니다. \n직접 결제 내역을 삭제 하실 거면 \'삭제\' 버튼을 눌러주세요.',
            style: TextStyle(
              fontFamily: 'NanumSquareRound',
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                '삭제',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                // 헬퍼와 오너에 따라 다른 함수 호출
                if (isHelper) {
                  helperDeletePayment(documentId, nickname);
                } else {
                  ownerDeletePayment(documentId, nickname);
                }
                Navigator.of(context).pop();
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "결제 내역이 삭제되었습니다.",
                      textAlign: TextAlign.center,
                    ),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                '취소',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> paymentData, bool isHelper) {
    int intCost = _extractCostAsInt('${paymentData['cost']}');
    //나가기 버튼 사용시 상대방 대화 안보이게 하기
    User? currentUser = FirebaseAuth.instance.currentUser;
    String? currentUserEmail = currentUser?.email;
    if (paymentData['helper_email'] == currentUserEmail && paymentData['isDeleted_${paymentData['helper_email_nickname']}'] == true) {
      return Container(); // 또는 적절한 '삭제됨' UI를 표시
    }
    if (paymentData['owner_email'] == currentUserEmail && paymentData['isDeleted_${paymentData['owner_email_nickname']}'] == true) {
      return Container(); // 또는 적절한 '삭제됨' UI를 표시
    }

    return GestureDetector(
        onLongPress: (){
          if (paymentData['helper_email'] == currentUserEmail){
            showDeletePaymentDialog(context, paymentData['docName'], paymentData['helper_email_nickname'], true);
          }
          if(paymentData['owner_email'] == currentUserEmail){
            showDeletePaymentDialog(context, paymentData['docName'], paymentData['owner_email_nickname'], false);
          }
        },
        child : Card(
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
                      //헬퍼일 경우
                          isHelper ? _showHelperPaymentDialog(context,
                                      paymentData['docName'], paymentData['helper_email_nickname'],
                                      paymentData['owner_email_nickname'], paymentData['helperUid'],
                                      paymentData['ownerUid'], paymentData['helperBank'],
                                      paymentData['helperAccount'], paymentData['cost'],)
                          //오더일 경우
                               : _showOrdererPaymentDialog(context, paymentData['docName'], paymentData['owner_email_nickname']);
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
      )
    );
  }

  //바텀바 구조
  Widget _buildBottomNavItem({
    required String iconPath,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: isActive ? 26 : 24,
              height: isActive ? 26 : 24,
              color: isActive ? Colors.indigo : Colors.black,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                fontSize: isActive ? 14 : 12,
                color: isActive ? Colors.indigo : Colors.black,
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

      bottomNavigationBar: Padding(
        padding: Platform.isAndroid ?  EdgeInsets.only(bottom: 8, top: 8): const EdgeInsets.only(bottom: 30, top: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(
                  iconPath: 'assets/pigma/chatbubbles.svg',
                  label: '채팅',
                  isActive: _selectedIndex == 0,
                  onTap: () {
                    if (_selectedIndex != 0) {
                      setState(() {
                        _selectedIndex = 0;
                      });
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AllUsersScreen()),
                      );
                    }
                  },
                ),
                _buildBottomNavItem(
                  iconPath: 'assets/pigma/footsteps.svg',
                  label: '진행상황',
                  isActive: _selectedIndex == 1,
                  onTap: () {
                    if (_selectedIndex != 1) {
                      setState(() {
                        _selectedIndex = 1;
                      });
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PaymentStatusScreen()),
                      );
                    }
                  },
                ),
                _buildBottomNavItem(
                  iconPath: 'assets/pigma/book.svg',
                  label: '게시판',
                  isActive: _selectedIndex == 2,
                  onTap: () {
                    if (_selectedIndex != 2) {
                      setState(() {
                        _selectedIndex = 2;
                      });
                      HapticFeedback.lightImpact();
                      switch (botton_domain) {
                        case 'naver.com':
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HanbatBoardPage()),
                          );
                          break;
                        default:
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => BoardPage()),
                          );
                          break;
                      }
                    }
                  },
                ),
                _buildBottomNavItem(
                  iconPath: 'assets/pigma/school.svg',
                  label: '학과랭킹',
                  isActive: _selectedIndex == 3,
                  onTap: () {
                    if (_selectedIndex != 3) {
                      setState(() {
                        _selectedIndex = 3;
                      });
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DepartmentRankingScreen()),
                      );
                    }
                  },
                ),
                _buildBottomNavItem(
                  iconPath: 'assets/pigma/person.svg',
                  label: '프로필',
                  isActive: _selectedIndex == 4,
                  onTap: () {
                    if (_selectedIndex != 4) {
                      setState(() {
                        _selectedIndex = 4;
                      });
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserProfileScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
