import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'create_account.dart';
import 'examunivboard.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAutoLogin = false; // 체크박스 상태를 저장할 변수
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
                ),
                SizedBox(height: 20), // 필드 사이에 간격 추가
                TextFormField(
                  // 비밀번호를 입력받는 필드
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: '비밀번호:', // 레이블 텍스트 설정
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.orange), // 경계 색상 설정
                    ),
                  ),
                  obscureText: true, // 비밀번호를 별표로 표시
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
                    onPressed: () async {

                      final FirebaseAuth _auth = FirebaseAuth.instance;
                      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
                        email: emailController.text,
                        password: passwordController.text,
                      );

                      // 로그인 성공
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => BoardPage()),
                      );

                      // 로그인 성공 메시지 표시
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('로그인이 완료되었습니다.')),
                      );

                      // 사용자에게 에러 메시지를 표시
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('이메일과 비밀번호를 확인해주세요.')),
                      );

                  },

                    style: TextButton.styleFrom(
                      primary: Colors.white, // 글자 색상
                      backgroundColor: Colors.orange, // 버튼 색상
                      onSurface: Colors.grey, // 버튼 disabled일 때의 색상
                      side: BorderSide(color: Colors.orange, width: 2), // 경계선 설정
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
}
