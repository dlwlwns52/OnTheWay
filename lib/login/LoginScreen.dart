import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:OnTheWay/CreateAccount/CreateAccount.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../CreateAccount/KakaoAuthention.dart';
import '../SchoolBoard/SchoolBoard.dart';
import 'PasswordFind.dart';

class LoginScreen extends StatefulWidget {

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAutoLogin = true; // 체크박스 상태를 저장할 변수
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode _EmailToPasswordFocusNode = FocusNode(); // 엔터 눌렀을 때 이메일 -> 비밀번호
  final FocusNode _PasswordToLoginFocusNode = FocusNode(); // 엔터 눌렀을 때 비밀번호 -> 로그인
  bool isLoginPressed = false; // 엔터키로 넘어갈 때 로그인 버튼이 눌렸는지 여부
  //이메일, 비밀번호 텍스트 유무에 따라 로그인 버튼 색상 변하는 변수
  bool isEmailFilled = false;
  bool isPasswordFilled = false;
  bool congraturation = true;
  String? _dropdownValue = '학교 메일 선택';


  //텍스트 차있으면 보더 색상 관리하는 변수
  bool _emailHasText = false;
  bool _passwordHasText = false;

  //비밀번호 별표
  bool _obscureText = true;

  void _checkFieldsFilled() {
    setState(() {
      isEmailFilled = emailController.text.isNotEmpty;
      isPasswordFilled = passwordController.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    emailController.addListener(_checkFieldsFilled);
    passwordController.addListener(_checkFieldsFilled);

    // 보더 색상 변환 리스너 추가
    emailController.addListener(() {
      setState(() {
        _emailHasText = emailController.text.isNotEmpty;
      });
    });

    passwordController.addListener(() {
      setState(() {
        _passwordHasText = passwordController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose(){
    emailController.dispose();
    passwordController.dispose();
    _EmailToPasswordFocusNode.dispose();
    _PasswordToLoginFocusNode.dispose();
    super.dispose();
  }


//로그인 버튼 클릭시 발동
  void _login() async{

    HapticFeedback.lightImpact();
    final FirebaseAuth _auth = FirebaseAuth.instance;
    if(emailController.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일을 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      setState(() {
        isLoginPressed = false;
      });
      return;
    }

    if(passwordController.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("비밀번호를 입력해주세요", textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      setState(() {
        isLoginPressed = false;
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("계정 인증 중 입니다. \n잠시만 기다려주세요.",textAlign: TextAlign.center,),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,

      );

      // 로그인 성공
      if (userCredential.user != null) {

        // await getTokenAndSave(userCredential.user!.email); // 사용자의 이메일을 인자로 넘겨 토큰 저장

        String email = userCredential.user!.email!;
        String domain = email.split('@').last; // 이메일에서 도메인 추출


        //자동 로그인 기이능
        if(_isAutoLogin == true){

          final FirebaseFirestore firestore = FirebaseFirestore.instance;
          QuerySnapshot querySnapshot = await firestore.collection('users')
              .where('email', isEqualTo: email)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            // 해당 이메일을 가진 사용자 문서가 존재하는 경우
            DocumentSnapshot userDoc = querySnapshot.docs.first;
            // 해당 이메일을 가진 사용자 문서가 존재하는 경우
            String userId = userDoc.id;

            // // 해당 사용자 문서에 토큰을 저장합니다.
            await firestore.collection('users').doc(userId).set({
              'isAutoLogin' : true,
              'domain' : domain,
            }, SetOptions(merge: true));
          }
          else {
            print('No user found with email: $email');
          }
        }
        // 인 체크 안하면
        else if(_isAutoLogin == false) {
          final FirebaseFirestore firestore = FirebaseFirestore.instance;
          QuerySnapshot querySnapshot = await firestore.collection('users')
              .where('email', isEqualTo: email)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            // 해당 이메일을 가진 사용자 문서가 존재하는 경우
            DocumentSnapshot userDoc = querySnapshot.docs.first;
            // 해당 이메일을 가진 사용자 문서가 존재하는 경우
            String userId = userDoc.id;

            // // 해당 사용자 문서에 토큰을 저장합니다.
            await firestore.collection('users').doc(userId).set({
              'isAutoLogin': false,
            }, SetOptions(merge: true));
          }
          else {
            print('No user found with email: $email');
          }
        }
        if (!mounted) return; // 위젯이 언마운트된 경우 종료합니다.

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BoardPage()),
        );

        // 로그인 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인이 완료되었습니다.', textAlign: TextAlign.center,),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
    catch (e) { //스낵바로 이메일 또는 비밀번호 계정 확인
      if (e is FirebaseAuthException) {
        print("FirebaseAuthException 코드: ${e.code}"); // 에러 코드 출력
        switch (e.code) {
          case 'invalid-email':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("유효하지 않은 이메일 형식입니다.", textAlign: TextAlign.center,),
                duration: Duration(seconds: 1),
              ),
            );

          case "INVALID_LOGIN_CREDENTIALS":
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('로그인 정보가 정확하지 않습니다. \n 이메일과 비밀번호를 확인해주세요.', textAlign: TextAlign.center,),
                duration: Duration(seconds: 2),
              ),
            );

          case "invalid-credential":
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('로그인 정보가 정확하지 않습니다. \n 이메일과 비밀번호를 확인해주세요.', textAlign: TextAlign.center,),
                duration: Duration(seconds: 2),
              ),
            );

          case "user-not-found":
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('등록되지 않은 계정입니다. \n회원가입을 진행해주세요.', textAlign: TextAlign.center),
                duration: Duration(seconds: 2),
              ),
            );

          case "wrong-password":
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('비밀번호가 일치하지 않습니다. 다시 시도해 주세요.', textAlign: TextAlign.center,),
                duration: Duration(seconds: 2),
              ),
            );

          case "network-request-failed":
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('네트워크 오류가 발생했습니다. \n연결 상태를 확인 후 다시 시도해주세요.', textAlign: TextAlign.center,),
                duration: Duration(seconds: 2),
              ),
            );

          case "too-many-requests":
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('잠시 동안 요청이 많아 처리가 지연되고 있습니다. \n잠시 후 다시 시도해 주세요.', textAlign: TextAlign.center,),
                duration: Duration(seconds: 2),
              ),
            );
            break;

        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${e}\n알 수 없는 오류가 발생했습니다. 잠시 뒤에 다시 시도해주세요.', textAlign: TextAlign.center,),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
    finally {
      if (mounted) {
        setState(() {
          isLoginPressed = false; // 로그인 시도 종료시 다시 상태를 false로 바꿈
        });
      }
    }
  }



  //토큰 저장
  Future<void> saveTokenToDatabase(String? token, String? email) async {
    print(1);
    if (email == null) return; // 이메일이 null인 경우 함수 종료

    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Firestore의 'users' 컬렉션에서 이메일로 사용자 문서를 조회합니다.
    QuerySnapshot querySnapshot = await firestore.collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // 해당 이메일을 가진 사용자 문서가 존재하는 경우
      String userId = querySnapshot.docs.first.id;
      // 해당 사용자 문서에 토큰을 저장합니다.
      await firestore.collection('users').doc(userId).set({
        'token': token,

      }, SetOptions(merge: true));
    } else {
      print('No user found with email: $email');
    }

  }
  Future<void> getTokenAndSave(String? email) async {
    String? token = await FirebaseMessaging.instance.getToken();
    await saveTokenToDatabase(token, email);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
        // 화면의 다른 부분을 터치했을 때 포커스 해제
          FocusScope.of(context).unfocus();
        },
        child: Stack(
            children: [
              Center(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(0, 0, 0, 40),
                          child: Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                fit: BoxFit.contain,
                                image: AssetImage(
                                  'assets/images/LoginLogo.png',
                                ),
                              ),
                            ),
                            child: Container(
                              width: 155,
                              height: 155,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              margin: EdgeInsets.fromLTRB(0, 0, 0, 16), //아직 회원이 아니신가요? 와 나머지의 padding
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.fromLTRB(0, 0, 0, 24), // 로그인과 나머지의 padding
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [

                                        Container(
                                          margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFFFFFFF),
                                          ),
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: TextFormField(
                                              controller: emailController,
                                              textInputAction: TextInputAction.next,
                                              cursorColor: Color(0xFF1D4786),
                                              onTap: () {
                                                HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                                              },
                                              onFieldSubmitted: (value) {
                                                HapticFeedback.lightImpact();
                                                FocusScope.of(context).requestFocus(_EmailToPasswordFocusNode);
                                              },
                                              decoration: InputDecoration(
                                                hintText: '이메일',
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
                                                    color: _emailHasText ?  Color(0xFF4B7CC5): Color(0xFFD0D0D0),
                                                  ), // 텍스트가 있으면 인디고, 없으면 회색
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(color: Color(0xFF4B7CC5)), // 포커스 시 색상 변경
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),





                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [

                                            //비밀번호
                                            // Container(
                                            //   margin: EdgeInsets.fromLTRB(0, 0, 0, 10),//비밀번호 아래패딩
                                            //   decoration: BoxDecoration(
                                            //     border: Border.all(color: Color(0xFF4B7CC5)),
                                            //     borderRadius: BorderRadius.circular(8),
                                            //     color: Color(0xFFFFFFFF),
                                            //   ),
                                            //   child: Container(
                                            //     padding: EdgeInsets.fromLTRB(15, 11, 15, 11),
                                            //     child: Row(
                                            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            //       crossAxisAlignment: CrossAxisAlignment.start,
                                            //       children: [
                                            //         Container(
                                            //           margin: EdgeInsets.fromLTRB(0, 4, 0, 4),
                                            //           child: Text(
                                            //             '123456!!',
                                            //             style: TextStyle(
                                            //               fontFamily: 'Pretendard',
                                            //               fontWeight: FontWeight.w400,
                                            //               fontSize: 16,
                                            //               height: 1,
                                            //               letterSpacing: -0.4,
                                            //               color: Color(0xFF222222),
                                            //             ),
                                            //           ),
                                            //         ),
                                            //         Container(
                                            //           width: 24,
                                            //           height: 24,
                                            //           child: SvgPicture.asset(
                                            //             'assets/pigma/close_eye.svg',
                                            //           ),
                                            //         ),
                                            //       ],
                                            //     ),
                                            //   ),
                                            // ),

                                            Container(
                                              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                              decoration: BoxDecoration(
                                                color: Color(0xFFFFFFFF),
                                              ),
                                              child: Align(
                                                alignment: Alignment.topLeft,
                                                child: TextFormField(
                                                  focusNode: _EmailToPasswordFocusNode,
                                                  onTap: () {
                                                    HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                                                  },
                                                  controller: passwordController,
                                                  obscureText: _obscureText,
                                                  textInputAction: TextInputAction.done,
                                                  cursorColor: Color(0xFF1D4786),
                                                  onFieldSubmitted: (value) {
                                                    HapticFeedback.lightImpact(); // 다음 필드로 이동할 때 햅틱 피드백

                                                  },
                                                  decoration: InputDecoration(
                                                    hintText: '비밀번호',
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
                                                        color: _passwordHasText ?  Color(0xFF4B7CC5): Color(0xFFD0D0D0),
                                                      ), // 텍스트가 있으면 인디고, 없으면 회색
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderSide: BorderSide(color: Color(0xFF4B7CC5)), // 포커스 시 색상 변경
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                      suffixIcon: GestureDetector(
                                                        onTap: () {
                                                          HapticFeedback.lightImpact();
                                                          setState(() {
                                                            _obscureText = !_obscureText;
                                                          });
                                                        },
                                                        child: Container(
                                                          padding: EdgeInsets.fromLTRB(9, 9, 9, 9),
                                                          child: SvgPicture.asset(
                                                            _obscureText
                                                                ? 'assets/pigma/close_eye.svg'  // 숨김 상태 아이콘
                                                                : 'assets/pigma/open_eye.svg',   // 표시 상태 아이콘
                                                            // fit: BoxFit.contain,  // 크기 조정 방식을 명시적으로 설정
                                                          ),
                                                        ),
                                                      )

                                                  ),
                                                ),
                                              ),
                                            ),

                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.start,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    //자동 로그인 표시

                                                  GestureDetector(
                                                    onTap: (){
                                                      HapticFeedback.lightImpact();
                                                      setState(() {
                                                        _isAutoLogin = !_isAutoLogin;
                                                      });
                                                    },
                                                    child: Container(
                                                      margin: EdgeInsets.fromLTRB(0, 0, 6, 0),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: _isAutoLogin ? Color(0xFF1D4786) :  Color(0xFFEEEEEE),
                                                          borderRadius: BorderRadius.circular(100),
                                                        ),
                                                        child: Container(
                                                          width: 20,
                                                          height: 20,
                                                          padding: EdgeInsets.fromLTRB(3, 3, 3, 3),
                                                          child: SvgPicture.asset(
                                                            'assets/pigma/check_autologin.svg',
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                    //텍스트
                                                    Container(
                                                      margin: EdgeInsets.fromLTRB(0, 3, 0, 3),
                                                      child: Text(
                                                        '자동 로그인',
                                                        style: TextStyle(
                                                          fontFamily: 'Pretendard',
                                                          fontWeight: FontWeight.w400,
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
                                                  margin: EdgeInsets.fromLTRB(0, 2, 0, 2),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.start,
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: EdgeInsets.fromLTRB(0, 2.5, 0, 1.5),
                                                          child: Text(
                                                            '비밀번호가 기억 안나시나요?',
                                                            style: TextStyle(
                                                              fontFamily: 'Pretendard',
                                                              fontWeight: FontWeight.w400,
                                                              fontSize: 13,
                                                              height: 1,
                                                              letterSpacing: -0.3,
                                                              color: Color(0xFF767676),
                                                            ),
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          onTap: (){
                                                            HapticFeedback.lightImpact();
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder: (context) => PassWordFind(email: emailController.text.trim())),
                                                            );
                                                          },
                                                            child: Container(
                                                              width: 16,
                                                              height: 16,
                                                              child: SvgPicture.asset(
                                                                'assets/pigma/arrow.svg',
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),

                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),



                                  InkWell(
                                    onTap:(){
                                     if( _emailHasText &&_passwordHasText ){
                                       HapticFeedback.lightImpact();
                                       _login();
                                     }
                                    },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: _emailHasText &&_passwordHasText ? Color(0xFF1D4786) :Color(0xFFE8EFF8) ,),// 비활성화 일때 Color(0xFFE8EFF8)
                                      borderRadius: BorderRadius.circular(8),
                                      color: _emailHasText &&_passwordHasText ? Color(0xFF1D4786) :Color(0xFFE8EFF8) , // 비활성화 일때 Color(0xFFE8EFF8)
                                    ),
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.fromLTRB(2.8, 14, 0, 14),
                                      child: Text(
                                        '로그인',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                          height: 1,
                                          letterSpacing: -0.5,
                                          color: Color(0xFFFFFFFF),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  ),
                                ],
                              ),
                            ),


                            Container(
                              child: Text.rich(
                                TextSpan(
                                  text: '아직 회원이 아니신가요? ',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 13,
                                    height: 1,
                                    letterSpacing: -0.3,
                                    color: Color(0xFF767676),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '회원가입',
                                      style: TextStyle(
                                        color: Color(0xFF1D4786),
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        height: 1.3,
                                        letterSpacing: -0.3,
                                      ),
                                      recognizer: TapGestureRecognizer()..onTap = () {
                                        // 회원가입 클릭 시 실행될 코드
                                        HapticFeedback.lightImpact();
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => KakaoLoginScreen()),

                                        );
                                      },
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          ],
                        ),
                      ],
                    ),
                  )
              ),
            ],
          ),
        ),
    );
  }
}


