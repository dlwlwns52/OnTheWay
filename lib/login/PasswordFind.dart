import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PassWordFind extends StatefulWidget {
  final String email;

  PassWordFind({required this.email});

  @override
  _PassWordFindState createState() => _PassWordFindState();
}

class _PassWordFindState extends State<PassWordFind> {
  late TextEditingController emailController;
  bool isEmailFilled = false;
  //텍스트 차있으면 보더 색상 관리하는 변수
  bool _emailHasText = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.email);

    emailController.addListener(_checkFieldsFilled);
    // 보더 색상 변환 리스너 추가
    emailController.addListener(() {
      setState(() {
        _emailHasText = emailController.text.isNotEmpty;
      });
    });

  }

  @override
  void dispose(){
    emailController.dispose();
    super.dispose();
  }

  void _checkFieldsFilled() {
    setState(() {
      isEmailFilled = emailController.text.isNotEmpty;
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }


  //비밀번호 재전송
  Future<void> _resetPassword(String email) async {
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("유효하지 않은 이메일 형식입니다.", textAlign: TextAlign.center,),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    try {

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호 재설정 이메일을 전송했습니다. \n새 비밀번호로 변경 후 접속이 안 될 경우 \n앱을 재시작해 주시길 바랍니다.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호 재설정 이메일 전송에 실패했습니다. \n다시 시도해 주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
              Navigator.pop(context);
            }
          },
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
              child: AppBar(
                title: Text(
                  '비밀번호 재설정',
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
            body: Stack(
              children: [
                Center(
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
                                  '이메일 주소를 입력 후 전송 버튼을 누르면 \n비밀번호 재설정 링크가 발송됩니다.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17,
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
                                    margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        '이메일',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                          height: 1,
                                          letterSpacing: -0.4,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),

                                  Container(
                                    margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFFFFFF),
                                    ),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: TextFormField(
                                        controller: emailController,
                                        textInputAction: TextInputAction.done,
                                        onTap: () {
                                          HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                                        },
                                        onFieldSubmitted: (value) {
                                          HapticFeedback.lightImpact();
                                        },
                                        decoration: InputDecoration(
                                          hintText: '이메일 입력',
                                          hintStyle: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                            height: 1,
                                            letterSpacing: -0.4,
                                            color: Color(0xFF767676),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 12), // 내부 여백 조정
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: _emailHasText ?  Color(0xFF1D4786): Color(0xFFD0D0D0),
                                            ), // 텍스트가 있으면 인디고, 없으면 회색
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Color(0xFF1D4786)), // 포커스 시 색상 변경
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 20,),

                                  GestureDetector(
                                    onTap: (){
                                      if(_emailHasText) {
                                        HapticFeedback.lightImpact();
                                        _resetPassword(
                                            emailController.text.trim());
                                      }
                                    },
                                      child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: _emailHasText ?  Color(0xFF1D4786): Color(0xFFE8EFF8),),
                                        borderRadius: BorderRadius.circular(8),
                                        color: _emailHasText ?  Color(0xFF1D4786):Color(0xFFE8EFF8),
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.fromLTRB(5.2, 15, 0, 15),
                                        child:
                                        Text(
                                          '재설정 링크 전송',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w400,
                                            fontSize: 16,
                                            height: 1,
                                            letterSpacing: -0.4,
                                            color: Color(0xFFFFFFFF),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
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
              ],
            ),
          ),
        )
    );
  }
}
