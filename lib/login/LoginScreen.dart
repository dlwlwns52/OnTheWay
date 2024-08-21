import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:OnTheWay/CreateAccount/CreateAccount.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../Board/UiBoard.dart';
import '../HanbatSchoolBoard/HanbatSchoolBoard.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../CreateAccount/SchoolEmailDialog.dart';
import '../test/LocationTest.dart';

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
          await getTokenAndSave(userCredential.user!.email); // 사용자의 이메일을 인자로 넘겨 토큰 저장
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
          // 자동로그인 체크 안하면
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

          switch (domain.toLowerCase()) {
            case 'naver.com':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HanbatBoardPage()),
              );
              break;
            // case 'pusan.ac.kr': // 임시!!!!!!!!!!!!!!!!1!!!!!!!!!!1!!!!!!!!!!1!!!!!!!!!!1!!!!!!!!!!1!!!!!!!!!!1
            //   Navigator.pushReplacement(
            //     context,
            //     MaterialPageRoute(builder: (context) => BoardPage()),
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
          SnackBar(content: Text('알 수 없는 오류가 발생했습니다. 잠시 뒤에 다시 시도해주세요.', textAlign: TextAlign.center,),
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
    if (email == null) return; // 이메일이 null인 경우 함수 종료

    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Firestore의 'users' 컬렉션에서 이메일로 사용자 문서를 조회합니다.
    QuerySnapshot querySnapshot = await firestore.collection('users')
        .where('email', isEqualTo: email)
        .get();

    User? currentUser = FirebaseAuth.instance.currentUser; //임시!!!!!!!!!
    String userUid = currentUser?.uid ?? ''; // 사용자 UID 얻기  //임시!!!!!!!

    if (querySnapshot.docs.isNotEmpty) {
      // 해당 이메일을 가진 사용자 문서가 존재하는 경우
      String userId = querySnapshot.docs.first.id;

      // 해당 사용자 문서에 토큰을 저장합니다.
      await firestore.collection('users').doc(userId).set({
        'uid': userUid, //임시!!!!!!!!!!!
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




  //비밀번호 찾기
  void showResetPasswordDialog(BuildContext context) {
    final TextEditingController resetEmailController = TextEditingController(text: emailController.text); // 초기값 설정
    showDialog(
      context: context,
      barrierDismissible: false, // 바깥을 눌러도 다이어로그가 닫히지 않게 설정
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
             
                Text(
                  '비밀번호 재설정',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'NanumSquareRound',
                    fontWeight: FontWeight.w800,
                    fontSize: 25,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 1, // 다이얼로그 너비 설정

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    '이메일 주소를 입력하신 후 \n전송 버튼을 누르시면\n비밀번호 재설정 링크가 발송됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'NanumSquareRound',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ),

                SizedBox(height: 20),

                TextField(
                  controller: resetEmailController,
                  decoration: InputDecoration(
                    labelText: '이메일 입력',
                    labelStyle: TextStyle(color: Colors.indigo[400]),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.indigo), // 포커스 시 색상 변경
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.email, color: Colors.indigo,),
                    filled: true,
                    fillColor: Colors.indigo[50],
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),

          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                '전송',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                _resetPassword(resetEmailController.text.trim());
                Navigator.of(context).pop();
              },
            ),

            SizedBox(),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                '닫기',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // 대화 상자 닫기
              },
            ),
          ],
        );
      },
    );
  }

//비밀번호 재전송
  Future<void> _resetPassword(String email) async {
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

  //이메일 선택 메소드
  void _showSchoolEmailDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SchoolEmailDialog(
          onSelected : (String domain) {
            setState(() {
              _dropdownValue = domain;
            });
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          Lottie.asset(
            'assets/lottie/blue2.json',
            fit: BoxFit.fill,
            width: double.infinity,
            height: double.infinity,
          ),

          Center(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // 이메일 입력
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: '이메일 :',
                        labelStyle: TextStyle(
                            fontFamily: 'NanumSquareRound',
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: Colors.grey
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.indigo),
                        ),
                      ),
                      onFieldSubmitted: (value) {
                        FocusScope.of(context).requestFocus(_EmailToPasswordFocusNode);
                      },
                    ),

                    SizedBox(height: 20),
                    TextFormField(
                      focusNode: _EmailToPasswordFocusNode,
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: '비밀번호 :',
                        labelStyle: TextStyle(
                            fontFamily: 'NanumSquareRound',
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: Colors.grey
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.indigo),
                        ),
                      ),
                      obscureText: true,
                      onFieldSubmitted: (value) => _login(),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Switch(
                          value: _isAutoLogin,
                          onChanged: (bool value) {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _isAutoLogin = value;
                            });
                          },
                          activeColor: Colors.indigoAccent,
                        ),

                        Text(
                          '자동 로그인',
                          style:
                          TextStyle(
                            fontFamily: 'NanumSquareRound',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),

                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        ElevatedButton(
                          child: Text('비밀번호 찾기'),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            showResetPasswordDialog(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            // shadowColor: Colors.black,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          child: Text('회원가입'),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CreateAccount())
                                // MaterialPageRoute(builder: (context) => Iso입lateExample())
                            // CreateAccount
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.orangeAccent,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    Container(
                      height: 50,
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 4),
                            blurRadius: 5.0,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isEmailFilled && isPasswordFilled
                                  ? [Colors.indigoAccent, Colors.blueAccent, Colors.indigoAccent]
                                  : [Colors.grey, Colors.grey],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: _login,
                            borderRadius: BorderRadius.circular(12),
                            splashColor: Colors.indigo.withOpacity(0.2),
                            highlightColor: Colors.indigo.withOpacity(0.2),
                            child: Center(
                              child: Text(
                                "로그인",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),


                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


