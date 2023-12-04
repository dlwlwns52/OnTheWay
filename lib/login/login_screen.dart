import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'create_account.dart';
import '../Board/UiBoard.dart';

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

  @override
  void dispose(){
    _EmailToPasswordFocusNode.dispose();
    _PasswordToLoginFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.orange,
      body: Center(  // Center 위젯 추가
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
                SizedBox(height: 20), // 필드 사이에 간격 추가정
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
                  // onFieldSubmitted: (value) => _login(), // 비밀번호 필드 -> 로그인
                  onFieldSubmitted: (value){
                    setState(() {
                      isLoginPressed = true; // 엔터키로 로그인 시도
                    });
                    _login();
                  },
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
                      child: Text('이메일 찾기'),
                      onPressed: () {},
                    ),
                    TextButton(
                      child: Text('비밀번호 찾기'),
                      onPressed: () {},
                    ),
                    TextButton(
                      child: Text('회원가입'),
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
                    child: Text("로그인"),
                    onPressed: _login,
                    style: TextButton.styleFrom(
                      primary: Colors.white, // 글자 색상
                      backgroundColor: Colors.grey, // 버튼 색상
                      onSurface: Colors.grey, // 버튼 disabled일 때의 색상
                      side: BorderSide(color: Colors.grey, width: 2), // 경계선 설정
                    ).copyWith(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states){
                            if (isLoginPressed || states.contains(MaterialState.pressed)){
                              return Colors.orange;
                            }
                            return Colors.grey;
                          }
                      ),
                      side:  MaterialStateProperty.resolveWith<BorderSide>(
                          (Set<MaterialState> states) {
                            if (isLoginPressed || states.contains(MaterialState.pressed)) {
                              return BorderSide(color: Colors.orange, width: 2);
                            }
                            return BorderSide(color: Colors.grey, width: 2);
                          }
                      )
                    )
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

      if (userCredential.user != null) {
        // 로그인 성공
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
    } catch (e) { //스낵바로 이메일 또는 비밀번호 계정 확인
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-email':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("유효하지 않은 이메일 형식입니다.", textAlign: TextAlign.center,),
                duration: Duration(seconds: 1),
              ),
            );

          case 'user-not-found':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('해당 이메일의 계정이 존재하지 않습니다.', textAlign: TextAlign.center,),
                duration: Duration(seconds: 1),
              ),
            );
            break;
          case 'wrong-password':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("비밀번호가 틀렸습니다.", textAlign: TextAlign.center,),
                duration: Duration(seconds: 1),
              ),
            );
            break;
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

}
