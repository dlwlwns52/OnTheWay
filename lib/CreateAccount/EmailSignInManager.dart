// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:OnTheWayCreateAccount/CreateAccount.dart';
//
//
// class EmailSignInManager {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final TextEditingController _emailUserController;
//   final String? _dropdownValue;
//   final BuildContext context;
//
//   EmailSignInManager({
//     required TextEditingController emailUserController,
//     required String? dropdownValue,
//     required this.context,
//   }) : _emailUserController = emailUserController,
//         _dropdownValue = dropdownValue;
//
//   Future<void> sendSignInWithEmailLink() async {
//     String email = _emailUserController.text + "@" + _dropdownValue!;
//
//     // 이메일 주소 형식 검사
//     if (!RegExp(r"^[a-zA-Z0-9]+$").hasMatch(_emailUserController.text)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('유효한 이메일 주소를 입력해주세요.', textAlign: TextAlign.center,),
//           duration: Duration(seconds: 1),
//         ),
//       );
//       return;
//     }
//
//     // 선택되지 않은 학교 메일 처리
//     if (_dropdownValue == '학교 메일 선택') {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('학교 메일을 선택해주세요.', textAlign: TextAlign.center,),
//           duration: Duration(seconds: 1),
//         ),
//       );
//       return;
//     }
//
//     ActionCodeSettings actionCodeSettings = ActionCodeSettings(
//       url: 'https://onthewayljj.page.link/c8Ci',
//       handleCodeInApp: true,
//       androidPackageName: 'com.example.ontheway',
//       androidInstallApp: true,
//       androidMinimumVersion: '12',
//     );
//
//     try {
//       // 이메일 인증 링크를 보냅니다.
//       await _auth.sendSignInLinkToEmail(
//         email: email,
//         actionCodeSettings: actionCodeSettings,
//       );
//
//       // 이메일을 확인하도록 사용자에게 알림을 표시합니다.
//       final FlutterSecureStorage storage = FlutterSecureStorage();
//       await storage.write(key: 'email', value: email);
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('회원가입 이메일이 전송되었습니다. 확인 후 인증해주세요.', textAlign: TextAlign.center,),
//           duration: Duration(seconds: 1),지
//         ),
//       );
//     } catch (e) {
//       // 오류 처리
//       print("오류 원인: $e");
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('이메일 전송에 실패했습니다. 다시 시도해주세요.', textAlign: TextAlign.center,),
//           duration: Duration(seconds: 1),
//         ),
//       );
//     }
//   }
// }
