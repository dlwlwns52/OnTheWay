
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../login/LoginScreen.dart';
import '../login/NavigateToBoard.dart';
import '../CreateAccount/SchoolEmailDialog.dart';


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


  //이메일인증
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(_onNicknameChanged);
    _passwordController.addListener(_onpasswordChanged);
    _confirmPasswordController.addListener(_confirmPasswordChanged);
    _emailUserController.addListener(_onEmaildChanged);

  }


  @override
  void dispose() {
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
    String pattern = r"^[a-zA-Z0-9]+$";// 영문과 또는 숫자를 포함해야 함
    RegExp regex = new RegExp(pattern);
    String value = _emailUserController.text;
    setState(() {
      if (value == null || value.trim().isEmpty) {
        _userEmailErrorText = '아이디를 입력해주세요.';
      } else if (!regex.hasMatch(value)) {
        _userEmailErrorText = "영문과 숫자만 가능합니다.";
      } else {
        _userEmailErrorText = null;
      }
      isEmailVerified = false; // 이메일 필드가 변경되면 인증 상태를 false로 설정
    });
  }

// 이메일 중복 여부 확인
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


  bool _validateFields() {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('닉네임을 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }

    if (_emailUserController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일을 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }

    if(isEmailVerified == false){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일 인증을 완료해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }

    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호를 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }

    if (!RegExp(r'^(?=.*[@$!%*#?&_-])[A-Za-z\d@$!%*#?&_-]{8,16}$').hasMatch(_passwordController.text)) {
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
          _buttonText = '중복확인';
          _buttonColor = Colors.red;
          _isNicknameAvailable = false;
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              title: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notification_important, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text(
                      '알림',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                ),
              ),
              content: Text(
                "'" + nickname + "' " +'은 다른 사용자가 사용하고 있는 이름입니다. \n\n 다른 닉네임을 사용해 주시길 바랍니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      _nicknameController.clear();
                      Navigator.of(context).pop();
                    },
                    child: Text('취소'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[300],
                    )
                ),
              ],
            );
          },
        );

      } else {
        // 사용 가능한 이름
        setState(() {
          _buttonText = '사용가능';
          _buttonColor = Colors.indigo[200] ?? Colors.indigoAccent;
          _isNicknameAvailable = true;
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              title: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notification_important, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text(
                      '알림',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                ),
              ),
              content: Text(
                "'" + nickname + "' 은 사용 가능한 이름입니다.\n\n 이 닉네임을 사용하시겠습니까?",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    // 사용자가 입력한 닉네임을 TextFormField에 넣어주기
                    _nicknameController.text = nickname;
                    Navigator.of(context).pop();
                  },
                  child: Text('확인'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.indigo[300],
                    primary: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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

  //이메일 선택 메소드
  void _showSchoolEmailDialog(BuildContext context) {
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

  //이메일 인증
  Future<void> _signInWithGoogle() async {
    try {
      String userEmail = _emailUserController.text.trim();
      if (_dropdownValue == null) {
        setState(() {
          _userEmailErrorText = '학교 메일을 선택해 주세요';
        });
        return;
      }

      String fullEmail = '$userEmail@$_dropdownValue';

      // 이전에 로그인한 계정 로그아웃
      await _googleSignIn.signOut();


      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // 사용자가 로그인 취소
        return;
      }

      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null && user.email == fullEmail) {
        // 성공적으로 로그인
        setState(() {
          isEmailVerified = true;
          _userEmailErrorText = null; // 이메일 인증 성공 시 오류 메시지 제거
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일 인증이 완료되었습니다.', textAlign: TextAlign.center,),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // 이메일이 일치하지 않으면 로그아웃
        await _auth.signOut();
        setState(() {
          _userEmailErrorText = '이메일이 일치하지 않습니다.';
        });
      }
    } catch (e) {
      // 로그인 오류 처리
      print(e);
    }
  }


  Widget _buildNicknameField() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 10, 1),
            child: Container(
              height: 80,
              child: TextFormField(
                controller: _nicknameController,
                style: TextStyle(
                  color: Colors.black,
                ),
                cursorColor: Colors.indigo,
                cursorWidth: 3,
                showCursor: true,
                decoration: InputDecoration(
                  labelText: '닉네임',
                  labelStyle: TextStyle(color: Colors.black54),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.indigo,
                    ),
                  ),
                  errorText: _usernicknameErrorText,
                ),
                validator: (value) {
                  String pattern = r'[a-zA-Zㄱ-ㅎ가-힣-0-9]';
                  RegExp regex = RegExp(pattern);
                  if (value == null || value.trim().isEmpty) {
                    return '닉네임을 입력해주세요.';
                  }
                  return null;
                },
                onChanged: (value) {
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
          padding: const EdgeInsets.fromLTRB(1, 1, 10, 25),
          child: ElevatedButton(
            style: ButtonStyle(
              alignment: Alignment.center,
              backgroundColor: MaterialStateProperty.all(_buttonColor),
            ),
            child: Text(
              _buttonText,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            onPressed: _checkNicknameAvailabilityAndValidate,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Container(
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
                    color: Colors.indigo,
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
            onTap: () => _showSchoolEmailDialog(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 19),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(_dropdownValue ?? '학교 메일 선택'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailCheck() {
    return Container(
      width: 250,
      child: ElevatedButton.icon(
          onPressed: _signInWithGoogle,
          icon: Icon(Icons.mark_email_read, color: Colors.white),
          label: Text(
            '이메일 인증',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            primary: isEmailVerified ? Colors.indigo : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
    );
  }


  Widget _buildPasswordField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 1),
      child: TextFormField(
        obscureText: true,
        controller: _passwordController,
        focusNode: _passwordFocusNode,
        style: TextStyle(
          color: Colors.black,
        ),
        cursorColor: Colors.indigo,
        cursorWidth: 3,
        showCursor: true,
        enabled: _isNicknameAvailable,
        decoration: InputDecoration(
          labelText: '비밀번호',
          labelStyle: TextStyle(color: Colors.black54),
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.indigo,
            ),
          ),
          errorText: _userpasswordErrorText,
        ),
        validator: (value) {
          String pattern = r'^[[A-Za-z\d@$!%*#?&_-]{8,16}$`';
          RegExp regex = RegExp(pattern);
          if (value == null || value.trim().isEmpty) {
            return '비밀번호를 입력해주세요.';
          } else if (!regex.hasMatch(value)) {
            return '비밀번호는 5~18자의 영문 소문자, 숫자, 특수기호(_)만 사용 가능합니다.';
          }
          return null;
        },
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (value) {
          FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
        },
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 1),
      child: TextFormField(
        obscureText: true,
        controller: _confirmPasswordController,
        focusNode: _confirmPasswordFocusNode,
        style: TextStyle(
          color: Colors.black,
        ),
        cursorColor: Colors.indigo,
        cursorWidth: 3,
        showCursor: true,
        enabled: _isNicknameAvailable,
        decoration: InputDecoration(
          labelText: '비밀번호 확인',
          labelStyle: TextStyle(color: Colors.black54),
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.indigo,
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
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (value) {
          FocusScope.of(context).requestFocus(_buttonFocusNode);
        },
      ),
    );
  }

  Widget _buildBottomAppBar(BuildContext context) {
    return BottomAppBar(
      child: Container(
        margin: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.indigo[300],
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: ElevatedButton(
          onPressed: () => _onSignUpButtonPressed(context),
          child: Text(
            '회원가입',
            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            primary: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
        ),
      ),
    );
  }

  void _onSignUpButtonPressed(BuildContext context) async {
    if (_validateFields()) {
      bool emailAvailable = await _checkEmailAvailability();
      if (!emailAvailable) return;

      final rootContext = context;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '회원가입 완료',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          content: Text(
            '회원가입을 완료 하시겠습니까?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          actions: [
            Column(
              children: [
                Center(
                  child: Lottie.asset(
                    'assets/lottie/Animation.json',
                    fit: BoxFit.contain,
                    width: 200,
                    height: 200,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  child: Text(
                    '확인',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.indigo[300],
                    onPrimary: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();

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

                      User? currentUser = FirebaseAuth.instance.currentUser;
                      String userUid = currentUser?.uid ?? '';

                      final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
                      await usersCollection.doc(nickname).set({
                        'uid': userUid,
                        'nickname': nickname,
                        'email': email,
                        'joined_date': formattedDate,
                      });

                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            '회원가입이 완료되었습니다.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );

                      Navigator.pushReplacement(
                        rootContext,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    } catch (e) {
                      print("회원가입 실패: $e");
                    }
                  },
                ),
                ElevatedButton(
                  child: Text(
                    '취소',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.grey,
                    onPrimary: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }
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
              title: Text("회원가입", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              SizedBox(height: 30),
              _buildNicknameField(),
              SizedBox(height: 30),
              _buildEmailField(),
              SizedBox(height: 30),
              _buildEmailCheck(),
              SizedBox(height: 30),
              _buildPasswordField(),
              SizedBox(height: 30),
              _buildConfirmPasswordField(),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomAppBar(context),
    );
  }


  // Future<void> saveTokenToDatabase(String? token) async {
  //   // 사용자가 로그인한 경우에만 토큰을 저장합니다.
  //   String nickname = _nicknameController.text;
  //   print(nickname);
  //   String? userId = FirebaseAuth.instance.currentUser?.uid;
  //   if (userId == null) return;
  //
  //   // Firestore 인스턴스를 가져옵니다.
  //   final FirebaseFirestore firestore = FirebaseFirestore.instance;
  //
  //   // Firestore의 'users' 컬렉션에 토큰을 저장합니다.
  //   await firestore.collection('users').doc(nickname).set({
  //     'token': token,
  //   }, SetOptions(merge: true));
  // }
  //
  // Future<void> getTokenAndSave() async {
  //   // FCM 토큰을 가져옵니다.
  //   String? token = await FirebaseMessaging.instance.getToken();
  //
  //   // 토큰을 Firestore에 저장합니다.
  //   await saveTokenToDatabase(token);
  // }


}