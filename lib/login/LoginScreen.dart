import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:OnTheWay/CreateAccount/CreateAccount.dart';
import '../Board/UiBoard.dart';
import '../NaverBoard/NaverUiBoard.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAutoLogin = false; // 체크박스 상태를 저장할 변수
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode _EmailToPasswordFocusNode = FocusNode(); // 엔터 눌렀을 때 이메일 -> 비밀번호
  final FocusNode _PasswordToLoginFocusNode = FocusNode(); // 엔터 눌렀을 때 비밀번호 -> 로그인
  bool isLoginPressed = false; // 엔터키로 넘어갈 때 로그인 버튼이 눌렸는지 여부
  //이메일, 비밀번호 텍스트 유무에 따라 로그인 버튼 색상 변하는 변수
  bool isEmailFilled = false;
  bool isPasswordFilled = false;

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
  }

  @override
  void dispose(){
    emailController.dispose();
    passwordController.dispose();
    _EmailToPasswordFocusNode.dispose();
    _PasswordToLoginFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Color(0xFFFF8B13),
      body: Center(  // Center 위젯 추가
        //로그인 창 크기설정
        child: Container(
          padding: const EdgeInsets.all(20.0),
          width: MediaQuery.of(context).size.width * 0.95, // 가로길이 설정
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),

          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // 이메일 입력
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: '이메일:', // 레이블 텍스트 설정
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange), // 경계 색상 설정
                    ),
                  ),
                  onFieldSubmitted: (value) { // 'next' 버튼이 클릭되면
                    FocusScope.of(context).requestFocus(_EmailToPasswordFocusNode); // 이메일 필드 -> 비밀번호 필드
                  },
                ),

                SizedBox(height: 20), // 필드 사이에 간격

                TextFormField(
                  // 비밀번호를 입력받는 필드
                  focusNode: _EmailToPasswordFocusNode,
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: '비밀번호:', // 레이블 텍스트 설정
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange), // 경계 색상 설정
                    ),
                  ),
                  // obscureText: true, // 비밀번호를 별표로 표시
                  onFieldSubmitted: (value) => _login(), // 비밀번호 필드 -> 로그인
                  // onFieldSubmitted: (value){
                  //   setState(() {
                  //     isLoginPressed = true; // 엔터키로 로그인 시도
                  //   });
                  //   _login();
                  // },
                ),

                SizedBox(height: 10),

                Row(
                  children: <Widget>[
                    Checkbox(
                      value: _isAutoLogin, // 체크박스 상태 값
                      onChanged: (bool? value) {
                        setState(() {
                          _isAutoLogin = value ?? false; // 상태 변경
                        });
                      },
                      activeColor: Colors.orange, // 체크된 상태의 색깔
                    ),
                    Text(
                      '자동 로그인',
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    TextButton(
                      child: Text('이메일 찾기',style: TextStyle(color: Colors.black),),
                      onPressed: () {},
                    ),
                    TextButton(
                      child: Text('비밀번호 찾기',style: TextStyle(color: Colors.black),),
                      onPressed: () {},
                    ),
                    TextButton(
                      child: Text('회원가입',style: TextStyle(color: Colors.black),),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CreateAccount())
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),

                Container(
                  width: double.infinity, // 버튼의 가로 길이를 최대로 설정
                  child: TextButton(
                    child: Text("로그인", style: TextStyle(color: Colors.white)),
                    onPressed:  _login,
                    style: TextButton.styleFrom(
                      backgroundColor: isEmailFilled && isPasswordFilled ? Colors.orange : Colors.grey,
                      side: BorderSide(color: isEmailFilled && isPasswordFilled ? Colors.orange : Colors.grey, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _login() async{
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

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      // if (userCredential.user != null) {
      //   // 로그인 성공
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (context) => BoardPage()),
      //   );

        if (userCredential.user != null) {
          // 로그인 성공
          await getTokenAndSave(userCredential.user!.email); // 사용자의 이메일을 인자로 넘겨 토큰 저장
          String email = userCredential.user!.email!;
          String domain = email.split('@').last; // 이메일에서 도메인 추출

          switch (domain.toLowerCase()) {
            case 'naver.com':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => NaverBoardPage()),
              );
              break;
            // case 'hanbat.ac.kr':
            //   Navigator.pushReplacement(
            //     context,
            //     MaterialPageRoute(builder: (context) => HanbatBoardPage()),
            //   );
            //   break;
          // 다른 도메인에 대한 처리...
            default:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => BoardPage()),
              );
              break;
        }

      // 로그인 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인이 완료되었습니다.', textAlign: TextAlign.center,),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) { //스낵바로 이메일 또는 비밀번호 계정 확인
      if (e is FirebaseAuthException) {
        print("FirebaseAuthException 코드: ${e.code}"); // 에러 코드 출력
        switch (e.code) {
          case 'invalid-email':
            print(1);
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

        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알 수 없는 오류가 발생했습니다. 잠시 뒤에 다시 시도해주세요.', textAlign: TextAlign.center,),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
    setState(() {
      isLoginPressed = false; // 로그인 시도 종료시 다시 상태를 false로 바꿈
    });
  }

  Future<void> saveTokenToDatabase(String? token, String? email) async {
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
}


