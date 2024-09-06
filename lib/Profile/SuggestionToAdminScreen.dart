import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'Profile.dart';

class SuggestionToAdminScreen extends StatefulWidget {
  final String nickname;
  final String email;
  // final String oldAccountNumber;
  SuggestionToAdminScreen({required this.nickname, required this.email,});

  @override
  _SuggestionToAdminScreenState createState() => _SuggestionToAdminScreenState();
}

class _SuggestionToAdminScreenState extends State<SuggestionToAdminScreen> {
  final TextEditingController subjectFeedbackController = TextEditingController();
  final TextEditingController contentFeedbackController = TextEditingController();

  // 보더 색상 관리 변수
  bool _subjectFeedbacHasText = false;
  bool _contentFeedbackHasText = false;


  @override
  void initState() {
    super.initState();
    print(widget.nickname);
    print(widget.email);
    subjectFeedbackController.addListener(() {
      setState(() {
        _subjectFeedbacHasText = subjectFeedbackController.text.isNotEmpty;
      });
    });

    contentFeedbackController.addListener(() {
      setState(() {
        _contentFeedbackHasText = contentFeedbackController.text.isNotEmpty;
      });
    });

  }

  @override
  void dispose() {
    subjectFeedbackController.dispose();
    contentFeedbackController.dispose();
    super.dispose();
  }

  // 개발자에게 건의사항 전송
  Future<void> _submitFeedback(String subjectFeedback, String contentFeedback) async {
    if (widget.email != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(widget.nickname);
      final userData = await userRef.get();

      int feedbackCount = userData.exists && userData.data()?.containsKey('feedbackCount') == true
          ? userData['feedbackCount']
          : 0;
      DateTime? lastFeedbackTime = userData.exists && userData.data()?.containsKey('lastFeedbackTime') == true
          ? (userData['lastFeedbackTime'] as Timestamp?)?.toDate()
          : null;

      if (lastFeedbackTime != null && DateTime.now().difference(lastFeedbackTime).inDays >= 1){
        feedbackCount = 0;
      }

      if (feedbackCount >= 3){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('의견을 보내주셔서 대단히 감사합니다.\n건의사항은 하루에 최대 3번까지 \n접수할 수 있음을 알려드립니다.'
            , textAlign: TextAlign.center,),
            duration: Duration(seconds: 2),),
        );
        return; // 피드백 전송을 중단하고 함수 종료
      }

      // 피드백 카운트를 증가
      feedbackCount += 1;

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final documentName = '${widget.nickname}_${widget.email}_$timestamp';

      await FirebaseFirestore.instance.collection('feedback').doc(documentName).set({
        'nickname': widget.nickname,
        'email': widget.email,
        'subject': subjectFeedback,
        'content' : contentFeedback,
        'timestamp': DateTime.now(),
      });
      // 사용자 데이터에 피드백 카운트와 마지막 피드백 시간을 업데이트
      await userRef.update({
        'feedbackCount': feedbackCount,
        'lastFeedbackTime': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '문의가 성공적으로 접수되었습니다. \n소중한 의견에 대한 답변은 이메일을 통해 보내드리도록 하겠습니다. 감사합니다.',
            style: TextStyle(fontSize: 13),
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 3),
        ),
      );

    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
            child: AppBar(
              title: Text(
                '문의하기',
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
                icon: Icon(Icons.arrow_back_ios_new_outlined),
                // '<' 모양의 뒤로가기 버튼 아이콘
                color: Colors.white,
                // 아이콘 색상
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context); // 뒤로가기 기능
                },
              ),
              actions: [],
            ),
          ),
          body: GestureDetector(
            onTap: () {
              // 화면의 다른 부분을 터치했을 때 포커스 해제
              FocusScope.of(context).unfocus();
            },
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05, // 화면의 5%만큼 좌우 패딩
                  vertical: MediaQuery.of(context).size.height * 0.02, // 화면의 2%만큼 상하 패딩
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.height * 0.015, // 하단 마진
                      ),
                      child: Text(
                        '개발자에게 하고 싶은 말을 작성해주세요.\n앱의 발전에 매우 큰 도움이 됩니다!',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          fontSize: MediaQuery.of(context).size.width * 0.045, // 화면 너비의 4.5%만큼 글자 크기
                          height: 1.4,
                          letterSpacing: -0.5,
                          color: Color(0xFF1D4786),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        '제목',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1,
                          letterSpacing: -0.4,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    TextField(
                      controller: subjectFeedbackController,
                      maxLength: 20, // 제목 글자 제한
                      decoration: InputDecoration(
                        hintText: '제목을 입력해주세요.',
                        hintStyle: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          fontSize: MediaQuery.of(context).size.width * 0.04, // 화면 너비의 4%만큼 글자 크기
                          color: Color(0xFF767676),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.02, // 상하 패딩
                          horizontal: MediaQuery.of(context).size.width * 0.04, // 좌우 패딩
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _subjectFeedbacHasText ? Color(0xFF1D4786) : Color(0xFFD0D0D0),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color(0xFF1D4786)),
                          // 포커스 시 색상 변경
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        '내용',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1,
                          letterSpacing: -0.4,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    TextField(
                      controller: contentFeedbackController,
                      maxLength: 200, // 내용 글자 제한
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top, // 텍스트를 상단에 정렬
                      decoration: InputDecoration(
                        hintText: '내용을 입력해주세요.',
                        hintStyle: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          fontSize: MediaQuery.of(context).size.width * 0.04, // 화면 너비의 4%만큼 글자 크기
                          color: Color(0xFF767676),
                        ),
                        contentPadding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.02, // 상단에 여유 공간 추가
                          left: MediaQuery.of(context).size.width * 0.04,
                          right: MediaQuery.of(context).size.width * 0.04,
                          bottom: MediaQuery.of(context).size.height * 0.20, // 하단에 더 큰 여유 공간 추가
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _contentFeedbackHasText ? Color(0xFF1D4786) : Color(0xFFD0D0D0),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color(0xFF1D4786)),
                          // 포커스 시 색상 변경
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                height: Platform.isAndroid
                    ? MediaQuery.of(context).size.width * 0.15
                    : MediaQuery.of(context).size.width * 0.21,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (subjectFeedbackController.text.isNotEmpty && contentFeedbackController.text.isNotEmpty) {
                      _submitFeedback(subjectFeedbackController.text, contentFeedbackController.text);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserProfileScreen()),
                      );
                    }
                    else if  (subjectFeedbackController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('제목을 입력해주세요.'
                          , textAlign: TextAlign.center,),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    else if  (contentFeedbackController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('건의사항을 입력해주세요.'
                          , textAlign: TextAlign.center,),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    primary: Color(0xFF1D4786), // 배경색
                    onPrimary: Colors.white, // 텍스트 색상
                    padding: EdgeInsets.symmetric(vertical: 13), // 내부 패딩 (높이 조정)
                    minimumSize: Size(double.infinity, kBottomNavigationBarHeight), // 버튼 크기 설정
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // 둥근 모서리를 제거하고 직사각형 모양으로 설정
                      side: BorderSide(color: Color(0xFF1D4786)), // 테두리 색상 설정
                    ),
                  ),
                  child: Text(
                    '문의완료',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
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
      ),
    );
  }
}
