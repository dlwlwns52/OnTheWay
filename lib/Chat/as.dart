// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:intl/intl.dart';
// import 'package:lottie/lottie.dart';
// import '../login/LoginScreen.dart';
// import '../login/NavigateToBoard.dart';
//
//
// class CreateAccount extends StatefulWidget {
//
//   @override
//   _CreateAccountState createState() => _CreateAccountState();
//
// }
//
// class _CreateAccountState extends State<CreateAccount> with WidgetsBindingObserver{
//   final _formKey = GlobalKey<FormState>();
//   TextEditingController _nicknameController = TextEditingController();
//   TextEditingController _passwordController = TextEditingController();  // 비밀번호 컨트롤러 추가
//   TextEditingController _confirmPasswordController = TextEditingController();  // 비밀번호 확인 컨트롤러 추가
//   TextEditingController _emailUserController = TextEditingController();
//   final FocusNode _buttonFocusNode = FocusNode();// 게시하기 버튼을 위한 FocusNode 추가
//
//   bool _isNicknameAvailable = false; // 입력 필드 활성화 여부 설정
//   String _buttonText = '중복확인';
//   Color _buttonColor = Colors.white70;
//   String? _usernicknameErrorText; // 닉네임 제한 ( 영문 대소문자 알파벳, 한글 음절, 일반적인 하이픈 기호, 그리고 숫자를 모두 허용)
//   String? _userpasswordErrorText; // password 제한 (비밀번호는 8~16자의 영문 대/소문자, 숫자, 특수문자를 사용 가능)
//   String? _confirmPasswordErrorText; // password 와 동일한가 확인
//   String? _userEmailErrorText; // 이메일 에러 텍스트 확인
//   final FocusNode _passwordFocusNode = FocusNode(); // 엔터눌렀을때 아이디 -> 비밀번호
//   final FocusNode _confirmPasswordFocusNode = FocusNode(); // 엔터눌렀을때 비밀번호 -> 비밀번호확인
//   final FocusNode _emailFocusNode = FocusNode(); // 엔터눌렀을때 비밀번호확인 -> 이메일
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   String? _dropdownValue = '학교 메일 선택';
//   bool isEmailVerified = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _nicknameController.addListener(_onNicknameChanged);
//     _passwordController.addListener(_onpasswordChanged);
//     _confirmPasswordController.addListener(_confirmPasswordChanged);
//     _emailUserController.addListener(_onEmaildChanged);
//
//   }
//
//
//   @override
//   void dispose() {
//     _nicknameController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // appBar: AppBar(
//       //   backgroundColor:  Color(0xFFFF8B13),
//       //   title: Text("회원가입", style: TextStyle(fontWeight: FontWeight.bold),),
//       // ),
//       appBar: PreferredSize(
//         preferredSize: Size.fromHeight(kToolbarHeight),
//         child: Stack(
//           children: [
//             Positioned.fill(
//               child: Lottie.asset(
//                 'assets/lottie/login.json',
//                 fit: BoxFit.fill,
//               ),
//             ),
//             AppBar(
//               backgroundColor:  Colors.transparent,
//               title: Text("회원가입", style: TextStyle(fontWeight: FontWeight.bold),),
//             ),
//           ],
//         ),
//
//       ),
//       body: SingleChildScrollView(
//         child : Form(
//           key: _formKey,
//           child: Column(
//             children: <Widget>[
//               SizedBox(height: 30),
//               Row(
//                 children: [
//                   Expanded(
//                     child: Padding(
//                       padding: const EdgeInsets.fromLTRB(15, 0, 10, 1),
//                       child: Container(
//                         height: 80, // 이 값을 조절하여 더 많은 공간을 확보하거나 줄일 수 있습니다.
//                         child: TextFormField(
//                           controller: _nicknameController,
//                           style: TextStyle(
//                             color: Colors.black,
//                           ),
//                           cursorColor: Colors.indigo,
//                           cursorWidth: 3,
//                           showCursor: true,
//                           decoration: InputDecoration(
//                             labelText: '닉네임',
//                             labelStyle: TextStyle(color: Colors.black54),
//                             border: OutlineInputBorder(),
//                             focusedBorder: OutlineInputBorder(
//                               borderSide: BorderSide(
//                                 color: Colors.indigo,
//                               ),
//                             ),
//                             errorText: _usernicknameErrorText,
//                           ),
//                           validator: (value) {
//                             String pattern = r'[a-zA-Zㄱ-ㅎ가-힣-0-9]';
//                             RegExp regex = new RegExp(pattern);
//                             if (value == null || value.trim().isEmpty) {
//                               return '닉네임을 입력해주세요.';
//                             }
//                             return null;
//                           },
//                           onChanged: (value){
//                             setState(() {
//                               _isNicknameAvailable = false;
//                               _buttonText = '중복확인';
//                               _buttonColor = Colors.white70;
//                             });
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.fromLTRB(1, 1, 10, 25), // 다른 에뮬레이터(기기)에 사용했을때 위치 변하면 수정 필요
//                     child: ElevatedButton(
//                       style: ButtonStyle(
//                         alignment: Alignment.center,
//                         backgroundColor: MaterialStateProperty.all(_buttonColor),
//                       ),
//                       child: Text(
//                         _buttonText,
//                         textAlign: TextAlign.center,
//                         style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
//                       ),
//                       onPressed: _checkNicknameAvailabilityAndValidate,
//                     ),
//                   ),
//                 ],
//               ),
//
//
//
//               SizedBox(height: 30),
//
//               Container(
//                 padding: const EdgeInsets.fromLTRB(15, 0, 15, 1),
//                 child: Row(
//                   children: <Widget>[
//                     Expanded(
//                       child: TextFormField(
//                         focusNode: _emailFocusNode,
//                         decoration: InputDecoration(
//                           labelText: '이메일',
//                           border: OutlineInputBorder(),
//                           enabled: _isNicknameAvailable,
//                           focusedBorder: OutlineInputBorder(
//                             borderSide: BorderSide(
//                               color: Colors.indigo,
//                             ),
//                           ),
//                           errorText: _userEmailErrorText,
//                         ),
//                         controller: _emailUserController,
//                       ),
//                     ),
//
//                     SizedBox(width: 10),
//                     Text('@'),
//                     SizedBox(width: 10),
//
//                     GestureDetector(
//                       onTap: () async {
//                         String? newValue = await showDialog<String>(
//                           context: context,
//                           builder: (BuildContext context) {
//                             return SimpleDialog(
//                               title: Text('본인 학교 웹메일을 선택해주세요.'),
//                               children: <String>[
//                                 //학교 웹메일 넣기
//                                 '학교 메일 선택',
//                                 'naver.com',
//                                 'edu.hanbat.ac.kr',
//                                 'yahoo.com',
//                                 'aaa.com',
//                                 // Add more domains here
//                               ]
//                                   .map((String domain) => SimpleDialogOption(
//                                 child: Text(domain),
//                                 onPressed: () {
//                                   Navigator.pop(context, domain);
//                                 },
//                               ))
//                                   .toList(),
//                             );
//                           },
//                         );
//
//                         if (newValue != null) {
//                           setState(() {
//                             _dropdownValue = newValue;
//                           });
//                         }
//                       },
//
//                       child: Container(
//                         padding: EdgeInsets.symmetric(horizontal: 40, vertical: 19),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                         child: Text(_dropdownValue ??'학교 메일 선택'),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//
//               SizedBox(height: 30),
//
//               Container(
//                 padding: const EdgeInsets.fromLTRB(15, 0, 15, 1),
//                 child: TextFormField(
//                   // obscureText: true, 비밀번호 별표표시 - 현재는 테스트로 비활성화
//                   controller: _passwordController,
//                   focusNode: _passwordFocusNode,
//                   style: TextStyle(
//                     color: Colors.black,
//                   ),
//                   cursorColor: Colors.indigo,
//                   cursorWidth: 3,
//                   showCursor: true,
//                   enabled: _isNicknameAvailable,
//                   decoration: InputDecoration(
//                     labelText: '비밀번호',
//                     labelStyle: TextStyle(color: Colors.black54),
//                     border: OutlineInputBorder(),
//                     focusedBorder: OutlineInputBorder(
//                       borderSide: BorderSide(
//                         color: Colors.indigo,
//                       ),
//                     ),
//                     errorText: _userpasswordErrorText,
//                   ),
//
//                   validator: (value) {
//                     String pattern = r'^[[A-Za-z\d@$!%*#?&_-]{8,16}$`';
//                     RegExp regex = new RegExp(pattern);
//                     if (value == null || value.trim().isEmpty) {
//                       return '비밀번호를 입력해주세요.';
//                     } else if (!regex.hasMatch(value)) {
//                       return '비밀번호는 5~18자의 영문 소문자, 숫자, 특수기호(_)만 사용 가능합니다.';
//                     }
//                     return null;
//                   },
//                   textInputAction: TextInputAction.next, // 'next' 버튼을 표시
//                   onFieldSubmitted: (value) { // 'next' 버튼이 클릭되면
//                     FocusScope.of(context).requestFocus(_confirmPasswordFocusNode); // 비밀번호 확인 필드로 포커스 이동
//                   },
//                 ),
//               ),
//
//               SizedBox(height: 30),
//
//               Container(
//                 padding: const EdgeInsets.fromLTRB(15, 0, 15, 1),
//                 child: TextFormField(
//                   // obscureText: true, 비밀번호 별표표시 - 현재는 테스트로 비활성화
//                     controller: _confirmPasswordController,
//                     focusNode: _confirmPasswordFocusNode,
//                     style: TextStyle(
//                       color: Colors.black,
//                     ),
//                     cursorColor: Colors.indigo,
//                     cursorWidth: 3,
//                     showCursor: true,
//                     enabled: _isNicknameAvailable,
//                     decoration: InputDecoration(
//                       labelText: '비밀번호 확인',
//                       labelStyle: TextStyle(color: Colors.black54),
//                       border: OutlineInputBorder(),
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: BorderSide(
//                           color: Colors.indigo,
//                         ),
//                       ),
//                       errorText: _confirmPasswordErrorText,
//                     ),
//
//                     validator: (value) {
//                       if (value == null || value.trim().isEmpty) {
//                         return '비밀번호를 다시 확인해주세요.';
//                       } else if (value != _passwordController.text) {
//                         return '비밀번호가 일치하지 않습니다.';
//                       }
//                       return '비밀번호가 일치합니다.';
//                     },
//                     textInputAction: TextInputAction.next, // 'next' 버튼을 표시
//                     onFieldSubmitted: (value){
//                       FocusScope.of(context).requestFocus(_buttonFocusNode);
//                     }
//                 ),
//
//               ),
//
//               SizedBox(height: 30),
//
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: BottomAppBar(
//         child: Container(
//           margin: EdgeInsets.all(16.0),
//           decoration: BoxDecoration(
//             color: Colors.indigo[300],
//             borderRadius: BorderRadius.circular(10.0),
//           ),
//           child: ElevatedButton(
//             onPressed: () async {
//               if (_validateFields()) {
//                 bool emailAvailable = await _checkEmailAvailability();
//                 if (!emailAvailable) return;
//
//                 final rootContext = context;
//                 showDialog(
//                   context: context,
//                   builder: (context) => AlertDialog(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20),
//                     ), // 모서리를 둥글게 처리
//                     title: Text(
//                       '회원가입 완료',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.indigo,
//                       ),
//                     ),
//                     content: Text(
//                       '회원가입을 완료 하시겠습니까?',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     actions: [
//                       Column(
//                         children:[
//                           Center(
//                             child: Lottie.asset(
//                               'assets/lottie/Animation.json',
//                               fit: BoxFit.contain,
//                               width: 200,
//                               height: 200,
//                             ),
//                           ),],),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           ElevatedButton(
//                             child: Text('확인', style: TextStyle(fontWeight: FontWeight.bold),),
//                             style: ElevatedButton.styleFrom(
//                               primary: Colors.indigo[300], // 버튼 색상 설정
//                               onPrimary: Colors.white, // 텍스트 색상 설정
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
//                             ),
//                             onPressed: () async {
//                               Navigator.of(context).pop(); // 다이어로그 닫기
//
//                               String nickname = _nicknameController.text;
//                               String password = _passwordController.text;
//                               String email = _emailUserController.text + "@" + _dropdownValue!;
//                               try {
//                                 await FirebaseAuth.instance.createUserWithEmailAndPassword(
//                                   email: email,
//                                   password: password,
//                                 );
//                                 DateTime now = DateTime.now();
//                                 String formattedDate = DateFormat('yyyy-MM-dd').format(now);
//
//                                 User? currentUser = FirebaseAuth.instance.currentUser;
//                                 String userUid = currentUser?.uid ?? ''; // 사용자 UID 얻기
//
//                                 final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
//                                 await usersCollection.doc(nickname).set({
//                                   'uid': userUid,
//                                   'nickname': nickname,
//                                   'email': email,
//                                   'joined_date': formattedDate,
//                                 });
//                                 // await getTokenAndSave();
//
//                                 // 스낵바로 알림
//                                 ScaffoldMessenger.of(rootContext).showSnackBar(
//                                   SnackBar(
//                                     content: Text(
//                                       '회원가입이 완료되었습니다.',
//                                       textAlign: TextAlign.center,
//                                     ),
//                                   ),
//                                 );
//
//                                 // BoardPage로 이동
//                                 Navigator.pushReplacement(
//                                   rootContext,
//                                   MaterialPageRoute(builder: (context) => LoginScreen()),
//                                 );
//                               } catch (e) {
//                                 print("회원가입 실패: $e");
//                               }
//                             },
//                           ),
//                           ElevatedButton(
//                             child: Text('취소', style: TextStyle(fontWeight: FontWeight.bold),),
//                             style: ElevatedButton.styleFrom(
//                               primary: Colors.grey, // 버튼 색상 설정
//                               onPrimary: Colors.white, // 텍스트 색상 설정
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
//                             ),
//                             onPressed: () {
//                               Navigator.of(context).pop();
//                             },
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 );
//
//               }
//             },
//
//             child: Text(
//               '회원가입',
//               style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
//             ),
//             style: ElevatedButton.styleFrom(
//               primary: Colors.transparent,
//               shadowColor: Colors.transparent,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   //위치 변경 조정
//   // 회원가입 로직을 처리하는 메서드 내에서 이메일 검증 후 navigateToBoard를 호출
//   void createAccountAndNavigate() {
//     String email = '${_emailUserController.text}@$_dropdownValue';
//     // 회원가입 로직...
//     // 성공적으로 회원가입이 되면, NavigateToBoard의 navigate 메소드를 호출
//     NavigateToBoard(context).navigate(email);
//   }
//
//
//   void _checkNicknameAvailability() async {
//     final nickname = _nicknameController.text.trim();
//
//     try {
//       // Firestore에서 같은 닉네임이 있는지 확인
//       final snapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(nickname)
//           .get();
//
//       // 중복된 이름
//       if (snapshot.exists && snapshot.data()?['nickname'] == nickname) {
//         setState(() {
//           _buttonText = '중복확인';
//           _buttonColor = Colors.red;
//           _isNicknameAvailable = false;
//         });
//         showDialog(
//           context: context,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20.0),
//               ),
//               title: Center(
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.notification_important, color: Colors.indigo),
//                     SizedBox(width: 8),
//                     Text(
//                       '알림',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.indigo,
//                       ),
//                     ),
//                     SizedBox(width: 8),
//                   ],
//                 ),
//               ),
//               content: Text(
//                 "'" + nickname + "' " +'은 다른 사용자가 사용하고 있는 이름입니다. \n\n 다른 닉네임을 사용해 주시길 바랍니다.',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.black87,
//                 ),
//               ),
//               actions: [
//                 ElevatedButton(
//                     onPressed: () {
//                       _nicknameController.clear();
//                       Navigator.of(context).pop();
//                     },
//                     child: Text('취소'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.indigo[300],
//                     )
//                 ),
//               ],
//             );
//           },
//         );
//
//       } else {
//         // 사용 가능한 이름
//         setState(() {
//           _buttonText = '사용가능';
//           _buttonColor = Colors.indigo[200] ?? Colors.indigoAccent;
//           _isNicknameAvailable = true;
//         });
//
//         showDialog(
//           context: context,
//           builder: (BuildContext context) {
//             return AlertDialog(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20.0),
//               ),
//               title: Center(
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.notification_important, color: Colors.indigo),
//                     SizedBox(width: 8),
//                     Text(
//                       '알림',
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.indigo,
//                       ),
//                     ),
//                     SizedBox(width: 8),
//                   ],
//                 ),
//               ),
//               content: Text(
//                 "'" + nickname + "' 은 사용 가능한 이름입니다.\n\n 이 닉네임을 사용하시겠습니까?",
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.black87,
//                 ),
//               ),
//               actions: [
//                 ElevatedButton(
//                   onPressed: () {
//                     // 사용자가 입력한 닉네임을 TextFormField에 넣어주기
//                     _nicknameController.text = nickname;
//                     Navigator.of(context).pop();
//                   },
//                   child: Text('확인'),
//                   style: TextButton.styleFrom(
//                     backgroundColor: Colors.indigo[300],
//                     primary: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10.0),
//                     ),
//                     padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//
//       }
//     } catch (e) {
//       print('닉네임 확인 오류: $e');
//     }
//   }
//
//
//
//
//
// }