import 'dart:io';

import 'package:OnTheWay/Chat/SuccessChatReport.dart';
import 'package:OnTheWay/SchoolBoard/SuccessReport.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 데이터베이스를 사용하기 위한 임포트입니다.


class ReportChatUserService extends StatefulWidget {
  final String senderEmail;
  final String receiverEmail;
  final String docName;

  ReportChatUserService({required this.senderEmail, required this.receiverEmail, required this.docName});

  @override
  _ReportChatUserServiceState createState() => _ReportChatUserServiceState();
}

class _ReportChatUserServiceState extends State<ReportChatUserService> {
  late TextEditingController reportController;
  bool isEmailFilled = false;
  //텍스트 차있으면 보더 색상 관리하는 변수
  bool _reportHasText = false;
  bool _snackBarShown = false;

  int _currentTextLength = 0;


  @override
  void initState() {
    super.initState();

    reportController = TextEditingController();

    reportController.addListener(_checkFieldsFilled);
    // 보더 색상 변환 리스너 추가
    reportController.addListener(() {
      setState(() {
        _reportHasText = reportController.text.isNotEmpty;
      });
    });

  }

  @override
  void dispose(){
    reportController.dispose();
    super.dispose();
  }


  void _checkFieldsFilled() {
    setState(() {
      isEmailFilled = reportController.text.isNotEmpty;
    });
  }




  void _checkMaxLength(TextEditingController controller, int maxLength) {
    setState(() {
      if (controller.text.length > maxLength) {
        controller.text = controller.text.substring(0, maxLength);
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: maxLength),
        );
      }
      _currentTextLength = controller.text.length;
    });
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async{
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
          child: AppBar(
            title: Text(
              '신고하기',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 19,
                height: 1.0,
                letterSpacing: -0.5,
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
            actions: [],
          ),
        ),
        body: SingleChildScrollView(
            child: Center(
              child: Container(
                margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  children: [
                    SizedBox(height : 30),
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                            child: Text(
                              '사용자를 신고하시면, 해당 사용자와 본인이 나눈 내용을 관리자가 24시간 내에 확인하고, 신고 내역을 토대로 적절한 조치를 취하게 됩니다. 조치 결과는 이메일로 안내해 드리겠습니다.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                height: 1.4,
                                letterSpacing: -0.4,
                                color: Color(0xFF424242),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: MediaQuery.of(context).size.width * 0.7,
                                margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFFFFFF),
                                ),
                                child: TextFormField(
                                  controller: reportController,
                                  textInputAction: TextInputAction.done,
                                  expands: true,
                                  maxLines: null, // 여러 줄 입력 가능
                                  minLines: null, // 줄 수 제한을 제거항
                                  cursorColor: Color(0xFF1D4786),
                                  onChanged: (value) => _checkMaxLength(reportController, 500),
                                  decoration: InputDecoration(
                                    hintText: '신고 내역을 입력해주세요.',
                                    hintStyle: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                      height: 1.4,
                                      letterSpacing: -0.4,
                                      color: Color(0xFF767676),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _reportHasText ? Colors.indigo : Color(0xFFD0D0D0),
                                      ), // 텍스트가 있으면 인디고, 없으면 회색
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.indigo), // 포커스 시 색상 변경
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),

                              // 현재 텍스트 길이 표시
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '$_currentTextLength / 500',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _currentTextLength == 500 ? Colors.red : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

        ),

        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: Platform.isAndroid ? MediaQuery.of(context).size.width * 0.0 : MediaQuery.of(context).size.width * 0.20,
              child: ElevatedButton(
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  FirebaseFirestore firestore = FirebaseFirestore.instance;
                  await firestore.collection('chatReport')
                      .doc(widget.senderEmail)
                      .set({
                    'reportEmail': widget.receiverEmail,
                    'reportContent' : reportController.text,
                    'docName' : widget.docName,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SuccessChatReportScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1D4786), // 배경색
                  foregroundColor: Colors.white, // 텍스트 색상
                  padding: EdgeInsets.symmetric(vertical: 13), // 내부 패딩 (높이 조정)
                  minimumSize: Size(double.infinity, kBottomNavigationBarHeight), // 버튼 크기 설정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // 둥근 모서리를 제거하고 직사각형 모양으로 설정
                    side: BorderSide(color: Color(0xFF1D4786)), // 테두리 색상 설정
                  ),
                ),
                child: Text(
                  '신고내역 전송',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 21,
                    height: 1,
                    letterSpacing: -0.5,
                    color: Colors.white, // 텍스트 색상
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
