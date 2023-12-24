// import 'package:flutter/material.dart';
// import 'package:ontheway_notebook/CreateAccount/CreateAccount.dart';
//
//
// class ValidateIdPasswordEmail {
//
//   bool _validateFields() {
//
//     if (_emailUserController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('이메일을 입력해주세요.', textAlign: TextAlign.center,),
//           duration: Duration(seconds: 1),
//         ),
//       );
//       return false;
//     }
//     else if (_passwordController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('비밀번호를 입력해주세요.', textAlign: TextAlign.center,),
//           duration: Duration(seconds: 1),
//         ),
//       );
//       return false;
//     }
//
//     else if (!RegExp(r'^(?=.*[@$!%*#?&_-])[A-Za-z\d@$!%*#?&_-]{8,16}$').hasMatch(_passwordController.text)) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('비밀번호는 8~16자의 문자, 숫자, 적어도 한개의 특수기호를 사용해야 합니다.', textAlign: TextAlign.center,),
//           duration: Duration(seconds: 1),
//         ),
//       );
//       return false;
//     }
//
//
//     if (_confirmPasswordController.text != _passwordController.text) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('비밀번호가 일치하지 않습니다.', textAlign: TextAlign.center,),
//           duration: Duration(seconds: 1),
//         ),
//       );
//       return false;
//     }
//
//
//     if (_dropdownValue == '학교 메일 선택') {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('학교 메일을 선택해주세요.', textAlign: TextAlign.center,),
//           duration: Duration(seconds: 1),
//         ),
//       );
//       return false;
//     }
//     return true;
//   }
//
// }