import'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../Board/UiBoard.dart';
import '../login/LoginScreen.dart';


class CreateAccount extends StatefulWidget {

  @override
  _CreateAccountState createState() => _CreateAccountState();

}

class _CreateAccountState extends State<CreateAccount> with WidgetsBindingObserver{
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nicknameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();  // 비밀번호 컨트롤러 추가
  TextEditingController _confirmPasswordController = TextEditingController();  // 비밀번호 확인 컨트롤러 추가
  TextEditingController _emailUserController = TextEditingController();
  final FocusNode _buttonFocusNode = FocusNode();// 게시하기 버튼을 위한 FocusNode 추가

  bool _isNicknameAvailable = false; // 입력 필드 활성화 여부 설정
  String _buttonText = '중복확인';
  Color _buttonColor = Colors.white70;
  String? _usernicknameErrorText; // 닉네임 제한 ( 영문 대소문자 알파벳, 한글 음절, 일반적인 하이픈 기호, 그리고 숫자를 모두 허용)
  String? _userpasswordErrorText; // password 제한 (비밀번호는 8~16자의 영문 대/소문자, 숫자, 특수문자를 사용 가능)
  String? _confirmPasswordErrorText; // password 와 동일한가 확인
  String? _userEmailErrorText; // 이메일 에러 텍스트 확인
  final FocusNode _passwordFocusNode = FocusNode(); // 엔터눌렀을때 아이디 -> 비밀번호
  final FocusNode _confirmPasswordFocusNode = FocusNode(); // 엔터눌렀을때 비밀번호 -> 비밀번호확인
  final FocusNode _emailFocusNode = FocusNode(); // 엔터눌렀을때 비밀번호확인 -> 이메일
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _dropdownValue = '학교 메일 선택';
  bool isEmailVerified = false;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_onNicknameChanged);
    _passwordController.addListener(_onpasswordChanged);
    _confirmPasswordController.addListener(_confirmPasswordChanged);
    _emailUserController.addListener(_onEmaildChanged);
    // WidgetsBinding.instance?.addObserver(this); // 생명 주기 관찰자 추가
    // checkEmailVerification();
  }


  @override
  void dispose() {
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    // WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  Future<void> checkEmailVerification() async {
    User? currentUser = _auth.currentUser;
    await currentUser?.reload();
    if (currentUser != null && currentUser.emailVerified) {
      setState(() {
        isEmailVerified = true;
      });
    }
  }


  // 생명 주기 상태 변경 시 호출되는 메서드
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      checkEmailVerification();
    }
  }

  _onNicknameChanged() {
    RegExp onlyConsonants = new RegExp(r'^[ㄱ-ㅎ]+$');
    RegExp onlyVowels = new RegExp(r'^[ㅏ-ㅣ]+$');
    RegExp onlyNumbers = new RegExp(r'^[0-9]+$');
    String pattern = r'^[a-zA-Zㄱ-ㅎ가-힣0-9]+$';
    RegExp regex = new RegExp(pattern);
    String value = _nicknameController.text;
    setState(() {
      if (value == null || value.trim().isEmpty) {
        _usernicknameErrorText = '닉네임을 입력해주세요.';
      } else if (!regex.hasMatch(value)) {
        _usernicknameErrorText = '닉네임은 영문, 한글, 숫자만 사용 가능합니다.';
      } else if(onlyConsonants.hasMatch(_nicknameController.text) || onlyVowels.hasMatch(_nicknameController.text) || onlyNumbers.hasMatch(_nicknameController.text)){
        _usernicknameErrorText = '자음, 모음, 숫자 만으로는 구성될 수 없습니다.';
      }else {
        _usernicknameErrorText = null;
      }
    });
  }


  _onpasswordChanged() {
    String pattern = r'^(?=.*[@$!%*#?&_-])[A-Za-z\d@$!%*#?&_-]{8,16}$';
    RegExp regex = new RegExp(pattern);
    String value = _passwordController.text;
    setState(() {
      if (value == null || value.trim().isEmpty) {
        _userpasswordErrorText = '비밀번호를 입력해주세요.';
      } else if (!regex.hasMatch(value)) {
        _userpasswordErrorText = '8~16자의 영문 대/소문자, 숫자, 적어도 한개의 특수문자만 사용 가능합니다.';
      } else {
        _userpasswordErrorText = null;
      }
    });
  }

  _confirmPasswordChanged() {
    String value = _confirmPasswordController.text;
    setState(() {
      if (value == null || value.trim().isEmpty) {
        _confirmPasswordErrorText = '비밀번호를 입력해주세요.';
      }
      else if (  _confirmPasswordController.text != _passwordController.text) {
        _confirmPasswordErrorText =  '비밀번호가 일치하지 않습니다.';
      }
      else {
        _confirmPasswordErrorText = null;
      }
    });
  }

  _onEmaildChanged() {
    String pattern = r"^(?=.*[a-zA-Z])[a-zA-Z0-9]+$";
    RegExp regex = new RegExp(pattern);
    String value = _emailUserController.text;
    setState(() {
      if (value == null || value.trim().isEmpty) {
        _userEmailErrorText = '아이디를 입력해주세요.';
      }
      else if (!regex.hasMatch(value)) {
        _userEmailErrorText = "영문/숫자만 가능합니다.";
      } else {
        _userEmailErrorText = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text("회원가입"),
      ),
      body: SingleChildScrollView(
        child : Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 10, 1),
                      child: Container(
                        height: 80, // 이 값을 조절하여 더 많은 공간을 확보하거나 줄일 수 있습니다.
                        child: TextFormField(
                          controller: _nicknameController,
                          style: TextStyle(
                            color: Colors.black,
                          ),
                          cursorColor: Colors.orange,
                          cursorWidth: 3,
                          showCursor: true,
                          decoration: InputDecoration(
                            labelText: '닉네임',
                            labelStyle: TextStyle(color: Colors.black54),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.orange,
                              ),
                            ),
                            errorText: _usernicknameErrorText,
                          ),
                          validator: (value) {
                            String pattern = r'[a-zA-Zㄱ-ㅎ가-힣-0-9]';
                            RegExp regex = new RegExp(pattern);
                            if (value == null || value.trim().isEmpty) {
                              return '닉네임을 입력해주세요.';
                            }
                            return null;
                          },
                          onChanged: (value){
                            setState(() {
                              _isNicknameAvailable = false;
                              _buttonText = '중복확인';
                              _buttonColor = Colors.white70;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(1, 1, 10, 25), // 다른 에뮬레이터(기기)에 사용했을때 위치 변하면 수정 필요
                    child: ElevatedButton(
                      style: ButtonStyle(
                        alignment: Alignment.center,
                        backgroundColor: MaterialStateProperty.all(_buttonColor),
                      ),
                      child: Text(
                        _buttonText,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black87),
                      ),
                      onPressed: _checkNicknameAvailabilityAndValidate,
                    ),
                  ),
                ],
              ),



              SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 1),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        focusNode: _emailFocusNode,
                        decoration: InputDecoration(
                          labelText: '이메일',
                          border: OutlineInputBorder(),
                          enabled: _isNicknameAvailable,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.orange,
                            ),
                          ),
                          errorText: _userEmailErrorText,
                        ),
                        controller: _emailUserController,
                      ),
                    ),

                    SizedBox(width: 10),
                    Text('@'),
                    SizedBox(width: 10),

                    GestureDetector(
                      onTap: () async {
                        String? newValue = await showDialog<String>(
                          context: context,
                          builder: (BuildContext context) {
                            return SimpleDialog(
                              title: Text('본인 학교 웹메일을 선택해주세요.'),
                              children: <String>[
                                //학교 웹메일 넣기
                                '학교 메일 선택',
                                'naver.com',
                                'edu.hanbat.ac.kr',
                                'yahoo.com',
                                // Add more domains here
                              ]
                                  .map((String domain) => SimpleDialogOption(
                                child: Text(domain),
                                onPressed: () {
                                  Navigator.pop(context, domain);
                                },
                              ))
                                  .toList(),
                            );
                          },
                        );

                        if (newValue != null) {
                          setState(() {
                            _dropdownValue = newValue;
                          });
                        }
                      },

                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 19),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(_dropdownValue ??'학교 메일 선택'),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 1),
                child: TextFormField(
                  // obscureText: true, 비밀번호 별표표시 - 현재는 테스트로 비활성화
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  style: TextStyle(
                    color: Colors.black,
                  ),
                  cursorColor: Colors.orange,
                  cursorWidth: 3,
                  showCursor: true,
                  enabled: _isNicknameAvailable,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    labelStyle: TextStyle(color: Colors.black54),
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.orange,
                      ),
                    ),
                    errorText: _userpasswordErrorText,
                  ),

                  validator: (value) {
                    String pattern = r'^[[A-Za-z\d@$!%*#?&_-]{8,16}$`';
                    RegExp regex = new RegExp(pattern);
                    if (value == null || value.trim().isEmpty) {
                      return '비밀번호를 입력해주세요.';
                    } else if (!regex.hasMatch(value)) {
                      return '비밀번호는 5~18자의 영문 소문자, 숫자, 특수기호(_)만 사용 가능합니다.';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next, // 'next' 버튼을 표시
                  onFieldSubmitted: (value) { // 'next' 버튼이 클릭되면
                    FocusScope.of(context).requestFocus(_confirmPasswordFocusNode); // 비밀번호 확인 필드로 포커스 이동
                  },
                ),
              ),

              SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 1),
                child: TextFormField(
                  // obscureText: true, 비밀번호 별표표시 - 현재는 테스트로 비활성화
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    style: TextStyle(
                      color: Colors.black,
                    ),
                    cursorColor: Colors.orange,
                    cursorWidth: 3,
                    showCursor: true,
                    enabled: _isNicknameAvailable,
                    decoration: InputDecoration(
                      labelText: '비밀번호 확인',
                      labelStyle: TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.orange,
                        ),
                      ),
                      errorText: _confirmPasswordErrorText,
                    ),

                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '비밀번호를 다시 확인해주세요.';
                      } else if (value != _passwordController.text) {
                        return '비밀번호가 일치하지 않습니다.';
                      }
                      return '비밀번호가 일치합니다.';
                    },
                    textInputAction: TextInputAction.next, // 'next' 버튼을 표시
                    onFieldSubmitted: (value){
                      FocusScope.of(context).requestFocus(_buttonFocusNode);
                    }
                ),

              ),

              SizedBox(height: 30),


              // Container(
              //   padding: const EdgeInsets.fromLTRB(1, 1, 10, 10),
              //   child: FractionallySizedBox(
              //     widthFactor: 0.8, // Set the width as a fraction (0.8 means 80% of the available width)
              //     child: ElevatedButton(
              //       style: ButtonStyle(
              //         alignment: Alignment.center,
              //         backgroundColor: MaterialStateProperty.all(Colors.orange),
              //       ),
              //       child: Text(
              //         '이메일 인증하기',
              //         textAlign: TextAlign.center,
              //         style: TextStyle(color: Colors.black87),
              //       ),
              //       onPressed: () async {
              //         // await sendSignInWithEmailLink();
              //       },
              //
              //     ),
              //   ),
              // ),
              //
              // Text(
              //   isEmailVerified
              //       ? '이메일이 인증되었습니다.'
              //       : '이메일 인증이 필요합니다.',
              //   style: TextStyle(
              //     color: isEmailVerified ? Colors.green : Colors.red,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),

              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(1, 30, 10, 1),
                  child: FractionallySizedBox(
                    widthFactor: 0.5, // Set the width as a fraction (0.8 means 80% of the available width)
                    child: ElevatedButton(
                      focusNode: _buttonFocusNode,
                      style: ButtonStyle(
                        alignment: Alignment.center,
                        backgroundColor: MaterialStateProperty.all(Colors.orange),
                      ),
                      child: Text(
                        '회원가입',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black87),
                      ),
                      onPressed: () async {
                        // 유효성 검사 수행
                        if (_validateFields()) {
                          bool emailAvailable = await _checkEmailAvailability();
                          if(!emailAvailable) return; // 이메일이 이미 사용 중이면 진행 중단

                          final rootContext = context;

                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('회원가입 완료'),
                              content: Text('회원가입을 완료 하시겠습니까?'),
                              actions: [
                                TextButton(
                                  child: Text('취소'),
                                  onPressed: () {
                                    Navigator.of(context).pop();  // 다이어로그 닫기
                                  },
                                ),
                                TextButton(
                                  child: Text('확인'),
                                  onPressed: () async {
                                    Navigator.of(context).pop();  // 다이어로그 닫기

                                    String nickname = _nicknameController.text;
                                    String password = _passwordController.text;
                                    String email = _emailUserController.text + "@" + _dropdownValue!;
                                    try {
                                      await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                        email: email,
                                        password: password,
                                      );
                                      DateTime now = DateTime.now();
                                      String formattedDate = DateFormat('yyyy-MM-dd').format(now);

                                      final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
                                      await usersCollection.doc(nickname).set({
                                        'nickname': nickname,
                                        'email': email,
                                        'joined_date': formattedDate,
                                      });

                                      // // 스낵바로 알림
                                      ScaffoldMessenger.of(rootContext).showSnackBar(
                                        SnackBar(content: Text('회원가입이 완료되었습니다.')),
                                      );

                                      // BoardPage로 이동
                                      Navigator.pushReplacement(
                                        rootContext,
                                        MaterialPageRoute(builder: (context) => LoginScreen()),
                                      );
                                    } catch (e) {
                                      print("회원가입 실패: $e");
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }
                      },
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



  void _checkNicknameAvailability() async {
    final nickname = _nicknameController.text.trim();

    try {
      // Firestore에서 같은 닉네임이 있는지 확인
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(nickname)
          .get();

      // 중복된 이름
      if (snapshot.exists && snapshot.data()?['nickname'] == nickname) {
        setState(() {
          _buttonText = '다시';
          _buttonColor = Colors.red;
          _isNicknameAvailable = false;
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('알림'),
              content: Text("'" + nickname + "' " +'은 다른 사용자가 사용하고 있는 이름입니다. \n\n 다른 닉네임을 사용해 주시길 바랍니다.'),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      _nicknameController.clear();
                      Navigator.of(context).pop();
                    },
                    child: Text('취소'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    )
                ),
              ],
            );
          },
        );
      } else {
        // 사용 가능한 이름
        setState(() {
          _buttonText = '완료';
          _buttonColor = Colors.green;
          _isNicknameAvailable = true;
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('알림'),
              content: Text("'" + nickname + "' " +'은 사용가능한 이름입니다.\n\n 이 닉네임을 사용하시겠습니까?'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    // 사용자가 입력한 닉네임을 TextFormField에 넣어주기
                    _nicknameController.text = nickname;
                    Navigator.of(context).pop();
                  },
                  child: Text('확인'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('닉네임 확인 오류: $e');
    }
  }


  Future<bool> _checkEmailAvailability() async {
    final email = _emailUserController.text.trim() + "@" + _dropdownValue!;

    try {
      // 이 코드에서 await는 FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get() 작업이 완료될 때까지 다음 코드로 넘어가지 않게 합니다. 이 get() 메서드는 네트워크를 통해 Firebase의 Firestore 데이터베이스에서 데이터를 가져오는 작업이므로, 이 작업이 얼마나 걸릴지 확실하지 않습니다.
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('현재 존재하는 이메일 입니다.', textAlign: TextAlign.center,),
            // behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
        return false;
      }
      return true;
    } catch (e) {
      print('이메일 확인 오류: $e');
      return false;
    }
  }

  bool _nicknameValidateFields(){
    RegExp onlyConsonants = RegExp(r'^[ㄱ-ㅎ]+$');
    RegExp onlyVowels = RegExp(r'^[ㅏ-ㅣ]+$');
    RegExp onlyNumbers = RegExp(r'^[0-9]+$');

    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('닉네임을 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    } else if (onlyConsonants.hasMatch(_nicknameController.text) || onlyVowels.hasMatch(_nicknameController.text) || onlyNumbers.hasMatch(_nicknameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('자음, 모음, 숫자 만으로는 구성될 수 없습니다.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    } else if (!RegExp(r'^[a-zA-Zㄱ-ㅎ가-힣0-9]+$').hasMatch(_nicknameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('닉네임은 영문, 한글, 숫자만 사용 가능합니다.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }
    return true;
  }

  void _checkNicknameAvailabilityAndValidate() {
    if(_nicknameValidateFields()) {
      _checkNicknameAvailability();
    }
  }


  Future<void> sendSignInWithEmailLink() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    String email = _emailUserController.text + "@" + _dropdownValue!;

    // 이메일 주소 형식 검사
    if (!RegExp(r"^(?=.*[a-zA-Z])[a-zA-Z0-9]+$").hasMatch(_emailUserController.text )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('유효한 이메일 주소를 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // 선택되지 않은 학교 메일 처리
    if (_dropdownValue == '학교 메일 선택') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('학교 메일을 선택해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }


    ActionCodeSettings actionCodeSettings = ActionCodeSettings(
      url: 'https://onthewayljj.page.link/c8Ci',
      handleCodeInApp: true,
      androidPackageName: 'com.example.ontheway',
      androidInstallApp: true,
      androidMinimumVersion: '12',
    );

    try {
      // 이메일 인증 링크를 보냅니다.
      await _auth.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      // 이메일을 확인하도록 사용자에게 알림을 표시합니다.
      final FlutterSecureStorage storage = FlutterSecureStorage();
      await storage.write(key: 'email', value: email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입 이메일이 전송되었습니다. 확인 후 인증해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      // 오류 처리
      print("오류 원인: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일 전송에 실패했습니다. 다시 시도해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }


  bool _validateFields() {

    if (_emailUserController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일을 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }
    else if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호를 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }

    else if (!RegExp(r'^(?=.*[@$!%*#?&_-])[A-Za-z\d@$!%*#?&_-]{8,16}$').hasMatch(_passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호는 8~16자의 문자, 숫자, 적어도 한개의 특수기호를 사용해야 합니다.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }


    if (_confirmPasswordController.text != _passwordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호가 일치하지 않습니다.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }


    if (!RegExp(r"^(?=.*[a-zA-Z])[a-zA-Z0-9]+$").hasMatch(_emailUserController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('유효한 이메일 주소를 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }


    if (_dropdownValue == '학교 메일 선택') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('학교 메일을 선택해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }
    return true;
  }


}