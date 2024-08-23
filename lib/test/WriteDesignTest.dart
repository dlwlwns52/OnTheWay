// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/svg.dart';
//
// import '../CreateAccount/CreateAccount.dart';
//
// class WriteDesignTest extends StatefulWidget {
//   @override
//   _WriteDesignTestState createState() => _WriteDesignTestState();
// }
//
// class _WriteDesignTestState extends State<WriteDesignTest> {
//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//         onWillPop: () async{
//           return true;
//         },
//         child: GestureDetector(
//           onHorizontalDragEnd: (details){
//           if (details.primaryVelocity! >  0){
//             Navigator.pop(context);
//           }
//         },
//         child: Scaffold(
//           appBar: PreferredSize(
//             preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
//             child: AppBar(
//               title: Text(
//                 '비밀번호 재설정',
//                 style: TextStyle(
//                   fontFamily: 'Pretendard',
//                   fontWeight: FontWeight.w600,
//                   fontSize: 19,
//                   height: 1.0,
//                   letterSpacing: -0.5,
//                   color: Colors.white,
//                 ),
//               ),
//               centerTitle: true,
//               backgroundColor: Color(0xFF1D4786),
//               elevation: 0,
//               leading: IconButton(
//                 icon: Icon(Icons.arrow_back_ios_new_outlined), // '<' 모양의 뒤로가기 버튼 아이콘
//                 color: Colors.white, // 아이콘 색상
//                 onPressed: () {
//                   HapticFeedback.lightImpact();
//                   Navigator.pop(context); // 뒤로가기 기능
//                 },
//               ),
//               actions: [],
//             ),
//           ),
//           body: Stack(
//             children: [
//               Center(
//                 child: Container(
//                   margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
//                   child: Column(
//                     children: [
//                       SizedBox(height : 30),
//                       Container(
//                         margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             Container(
//                               margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
//                               child: Text(
//                                 '이메일 주소를 입력 후 전송 버튼을 누르면 \n비밀번호 재설정 링크가 발송됩니다.',
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   fontFamily: 'Pretendard',
//                                   fontWeight: FontWeight.w600,
//                                   fontSize: 17,
//                                   height: 1.4,
//                                   letterSpacing: -0.4,
//                                   color: Color(0xFF424242),
//                                 ),
//                               ),
//                             ),
//                             Column(
//                               mainAxisAlignment: MainAxisAlignment.start,
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Container(
//                                   margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
//                                   child: Align(
//                                     alignment: Alignment.topLeft,
//                                     child: Text(
//                                       '이메일',
//                                       style: TextStyle(
//                                         fontFamily: 'Pretendard',
//                                         fontWeight: FontWeight.w500,
//                                         fontSize: 14,
//                                         height: 1,
//                                         letterSpacing: -0.4,
//                                         color: Color(0xFF424242),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 Container(
//                                   width: double.infinity,
//                                   child: Positioned(
//                                     left: 0,
//                                     right: 0,
//                                     top: 0,
//                                     bottom: 0,
//                                     child: Container(
//                                       decoration: BoxDecoration(
//                                         border: Border.all(color: Color(0xFFD0D0D0)),
//                                         borderRadius: BorderRadius.circular(8),
//                                         color: Color(0xFFFFFFFF),
//                                       ),
//                                       child: Container(
//                                         width: 335,
//                                         height: 48,
//                                         padding: EdgeInsets.fromLTRB(15, 15, 15, 15),
//                                         child:
//                                         Text(
//                                           'idididid',
//                                           style: TextStyle(
//                                             fontFamily: 'Pretendard',
//                                             fontWeight: FontWeight.w400,
//                                             fontSize: 16,
//                                             height: 1,
//                                             letterSpacing: -0.4,
//                                             color: Color(0xFF222222),
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//
//                                   SizedBox(height: 20,),
//                                   Container(
//                                     width: double.infinity,
//                                     decoration: BoxDecoration(
//                                       border: Border.all(color: Color(0xFF1D4786)),
//                                       borderRadius: BorderRadius.circular(8),
//                                       color: Color(0xFF1D4786),
//                                     ),
//                                     child: Container(
//                                       padding: EdgeInsets.fromLTRB(5.2, 15, 0, 15),
//                                       child:
//                                       Text(
//                                         '재설정 링크 전송',
//                                         style: TextStyle(
//                                           fontFamily: 'Pretendard',
//                                           fontWeight: FontWeight.w400,
//                                           fontSize: 16,
//                                           height: 1,
//                                           letterSpacing: -0.4,
//                                           color: Color(0xFFFFFFFF),
//                                         ),
//                                         textAlign: TextAlign.center,
//                                       ),
//                                     ),
//                                   ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         )
//     );
//   }
// }
