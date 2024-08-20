// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
//
// class HelpScreen extends StatefulWidget {
//
//
//   @override
//   State<HelpScreen> createState() => _HelpScreenState();
// }
//
// class _HelpScreenState extends State<HelpScreen> {
//
//   Widget _buildPostCard({
//     required String userName,
//     required String timeAgo,
//     required String location,
//     required String cost,
//     required String storeName,
//   }) {
//     return Container(
//       margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
//       decoration: BoxDecoration(
//         border: Border.all(color: Color(0xFFD0D0D0)),
//         borderRadius: BorderRadius.circular(12),
//         color: Color(0xFFFFFFFF),
//       ),
//       child: Container(
//         padding: EdgeInsets.fromLTRB(15, 15, 15, 15),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.start,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                         margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
//                         child: Container(
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: ClipRRect(
//                             borderRadius: BorderRadius.circular(16),
//                             child: SvgPicture.asset(
//                               'assets/pigma/notifications.svg',
//                               width: 32,
//                               height: 32,
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                           width: 32,
//                           height: 32,
//                         ),
//                       ),
//                       Container(
//                         margin: EdgeInsets.fromLTRB(0, 8, 0, 8),
//                         child: Text(
//                           userName,
//                           style: TextStyle(
//                             fontFamily: 'Pretendard',
//                             fontWeight: FontWeight.w600,
//                             fontSize: 16,
//                             height: 1,
//                             letterSpacing: -0.4,
//                             color: Color(0xFF222222),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   Container(
//                     margin: EdgeInsets.fromLTRB(0, 10, 0, 9),
//                     child: Text(
//                       timeAgo,
//                       style: TextStyle(
//                         fontFamily: 'Pretendard',
//                         fontWeight: FontWeight.w500,
//                         fontSize: 13,
//                         height: 1,
//                         letterSpacing: -0.3,
//                         color: Color(0xFFAAAAAA),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Container(
//               margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
//               width: 303,
//               height: 1,
//               color: Color(0xFFF6F6F6),
//             ),
//             _buildInfoRow(
//               iconPath: 'assets/pigma/location.svg',
//               label: '위치',
//               value: location,
//             ),
//             _buildInfoRow(
//               iconPath: 'assets/pigma/dollar_circle.svg',
//               label: '비용',
//               value: cost,
//             ),
//             _buildInfoRow(
//               iconPath: 'assets/pigma/vuesaxbulkhouse.svg',
//               label: '매장명',
//               value: storeName,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBottomNavItem({
//     required String iconPath,
//     required String label,
//     required bool isActive,
//   }) {
//     return Expanded(
//       child: Container(
//         decoration: BoxDecoration(
//           color: Color(0xFFFFFFFF),
//           border: Border(
//             top: BorderSide(
//               color: Color(0xFFEEEEEE),
//               width: 1,
//             ),
//           ),
//         ),
//         child: Container(
//           padding: EdgeInsets.symmetric(vertical: 6),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Container(
//                 margin: EdgeInsets.only(bottom: 6),
//                 width: 24,
//                 height: 24,
//                 child: SvgPicture.asset(
//                   iconPath,
//                   width: 24,
//                   height: 24,
//                 ),
//               ),
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontFamily: 'Pretendard',
//                   fontWeight: FontWeight.w400,
//                   fontSize: 11,
//                   height: 1,
//                   letterSpacing: -0.3,
//                   color: isActive ? Color(0xFF1D4786) : Color(0xFF767676),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoRow({
//     required String iconPath,
//     required String label,
//     required String value,
//   }) {
//     return Container(
//       margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 margin: EdgeInsets.fromLTRB(0, 0, 6, 0),
//                 width: 24,
//                 height: 24,
//                 child: SvgPicture.asset(
//                   iconPath,
//                   width: 24,
//                   height: 24,
//                 ),
//               ),
//               Container(
//                 margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
//                 child: Text(
//                   label,
//                   style: TextStyle(
//                     fontFamily: 'Pretendard',
//                     fontWeight: FontWeight.w500,
//                     fontSize: 14,
//                     height: 1,
//                     letterSpacing: -0.4,
//                     color: Color(0xFF767676),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           Container(
//             margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
//             child: Text(
//               value,
//               style: TextStyle(
//                 fontFamily: 'Pretendard',
//                 fontWeight: FontWeight.w600,
//                 fontSize: 14,
//                 height: 1,
//                 letterSpacing: -0.4,
//                 color: Color(0xFF222222),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           '게시글 상세',
//           style: TextStyle(
//             fontFamily: 'Pretendard',
//             fontWeight: FontWeight.w600,
//             fontSize: 21,
//             height: 1.0,
//             letterSpacing: -0.5,
//             color: Color(0xFF222222),
//           ),
//         ),
//
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios_new_outlined), // '<' 모양의 뒤로가기 버튼 아이콘
//           color: Color(0xFF222222), // 아이콘 색상
//           onPressed: () {
//             Navigator.pop(context); // 뒤로가기 기능
//           },
//         ),
//         // 상단 왼쪽 빈 공간을 만들기 위해 빈 SizedBox를 사용
//         actions: [
//           Container(
//             margin: EdgeInsets.only(right: 18.7), // 오른쪽 여백 설정
//             child: GestureDetector(
//               onTap: () {
//                 print(1);
//               },
//               child: SvgPicture.asset(
//                 'assets/pigma/ellipsis.svg',
//                 width: 26, // 아이콘 너비
//                 height: 26, // 아이콘 높이
//               ),
//             ),
//           ),
//         ],
//       ),
//
//
//       body: SingleChildScrollView( // 내용이 화면을 넘어갈 때 스크롤할 수 있도록 함
//         child: Column(
//           children: [
//             SizedBox(height: 35,),
//             Container(
//               margin: EdgeInsets.fromLTRB(20, 0, 20, 10),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                         margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
//                         child: Container(
//                           width: 32,
//                           height: 32,
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(16),
//                           ),
//                           child: SvgPicture.asset(
//                             'assets/pigma/person.svg',
//                             width: 26, // 아이콘 너비
//                             height: 26, // 아이콘 높이
//                           ),
//                         ),
//                       ),
//                       Container(
//                         margin: EdgeInsets.fromLTRB(0, 8, 0, 8),
//                         child: Text(
//                           '이은*님',
//                           style: TextStyle(
//                             fontFamily: 'Pretendard',
//                             fontWeight: FontWeight.w600,
//                             fontSize: 16,
//                             height: 1,
//                             letterSpacing: -0.4,
//                             color: Color(0xFF222222),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   Container(
//                     margin: EdgeInsets.fromLTRB(0, 10, 0, 9),
//                     child: Text(
//                       '3분 전',
//                       style: TextStyle(
//                         fontFamily: 'Pretendard',
//                         fontWeight: FontWeight.w500,
//                         fontSize: 13,
//                         height: 1,
//                         letterSpacing: -0.3,
//                         color: Color(0xFFAAAAAA),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Container(
//               margin: EdgeInsets.fromLTRB(20, 0, 20, 16),
//               width: 335,
//               height: 1,
//               child:
//               Container(
//                 decoration: BoxDecoration(
//                   color: Color(0xFFF6F6F6),
//                 ),
//                 child: Container(
//                   width: 335,
//                   height: 0,
//                 ),
//               ),
//             ),
//             Container(
//               margin: EdgeInsets.fromLTRB(20, 0, 20, 16),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Container(
//                               margin: EdgeInsets.fromLTRB(0, 0, 6, 0),
//                               width: 24,
//                               height: 24,
//                               child:
//                               SizedBox(
//                                 width: 24,
//                                 height: 24,
//                                 child: SvgPicture.asset(
//                                   'assets/pigma/location.svg',
//                                 ),
//                               ),
//                             ),
//                             Container(
//                               margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
//                               child: Text(
//                                 '위치',
//                                 style: TextStyle(
//                                   fontFamily: 'Pretendard',
//                                   fontWeight: FontWeight.w500,
//                                   fontSize: 14,
//                                   height: 1,
//                                   letterSpacing: -0.4,
//                                   color: Color(0xFF767676),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         Container(
//                           margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
//                           child: Text(
//                             '연세대학교 도서관 4층',
//                             style: TextStyle(
//                               fontFamily: 'Pretendard',
//                               fontWeight: FontWeight.w600,
//                               fontSize: 14,
//                               height: 1,
//                               letterSpacing: -0.4,
//                               color: Color(0xFF222222),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Container(
//                               margin: EdgeInsets.fromLTRB(0, 0, 6, 0),
//                               width: 24,
//                               height: 24,
//                               child:
//                               SizedBox(
//                                 width: 24,
//                                 height: 24,
//                                 child: SvgPicture.asset(
//                                   'assets/pigma/dollar_circle.svg',
//                                 ),
//                               ),
//                             ),
//                             Container(
//                               margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
//                               child: Text(
//                                 '비용',
//                                 style: TextStyle(
//                                   fontFamily: 'Pretendard',
//                                   fontWeight: FontWeight.w500,
//                                   fontSize: 14,
//                                   height: 1,
//                                   letterSpacing: -0.4,
//                                   color: Color(0xFF767676),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                         Container(
//                           margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
//                           child: Text(
//                             '3,000원',
//                             style: TextStyle(
//                               fontFamily: 'Pretendard',
//                               fontWeight: FontWeight.w600,
//                               fontSize: 14,
//                               height: 1,
//                               letterSpacing: -0.4,
//                               color: Color(0xFF222222),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Container(
//                             margin: EdgeInsets.fromLTRB(0, 0, 6, 0),
//                             width: 24,
//                             height: 24,
//                             child:
//                             SizedBox(
//                               width: 24,
//                               height: 24,
//                               child: SvgPicture.asset(
//                                 'assets/pigma/vuesaxbulkhouse.svg',
//                               ),
//                             ),
//                           ),
//                           Container(
//                             margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
//                             child: Text(
//                               '매장명',
//                               style: TextStyle(
//                                 fontFamily: 'Pretendard',
//                                 fontWeight: FontWeight.w500,
//                                 fontSize: 14,
//                                 height: 1,
//                                 letterSpacing: -0.4,
//                                 color: Color(0xFF767676),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       Container(
//                         margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
//                         child: Text(
//                           '베스킨라빈스',
//                           style: TextStyle(
//                             fontFamily: 'Pretendard',
//                             fontWeight: FontWeight.w600,
//                             fontSize: 14,
//                             height: 1,
//                             letterSpacing: -0.4,
//                             color: Color(0xFF222222),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//
//             Container(
//               margin: EdgeInsets.fromLTRB(20, 0, 20, 16),
//               width: 335,
//               height: 1,
//               child:
//               Container(
//                 decoration: BoxDecoration(
//                   color: Color(0xFFF6F6F6),
//                 ),
//                 child: Container(
//                   width: 335,
//                   height: 0,
//                 ),
//               ),
//             ),
//
//
//
//
//
//
//
//
//
//
//             Container(
//               margin: EdgeInsets.fromLTRB(0, 0, 0, 61),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Container(
//                     margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Container(
//                           margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
//                           child: Align(
//                             alignment: Alignment.topLeft,
//                             child: Text(
//                               '요청사항',
//                               style: TextStyle(
//                                 fontFamily: 'Pretendard',
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 16,
//                                 height: 1,
//                                 letterSpacing: -0.4,
//                                 color: Color(0xFF222222),
//                               ),
//                             ),
//                           ),
//                         ),
//                         Container(
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Color(0xFFD0D0D0)),
//                             borderRadius: BorderRadius.circular(12),
//                             color: Color(0xFFFFFFFF),
//                           ),
//                           child: Container(
//                             padding: EdgeInsets.fromLTRB(15, 19, 27.3, 19),
//                             child:
//                             Text(
//                               '직접 받겠습니다. 조심히 오세요 감사합니다!! 직접 받겠습니다. 조심히 오세요 감사합니다!! ',
//                               style: TextStyle(
//                                 fontFamily: 'Pretendard',
//                                 fontWeight: FontWeight.w500,
//                                 fontSize: 14,
//                                 height: 1.4,
//                                 letterSpacing: -0.4,
//                                 color: Color(0xFF222222),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
//                     width: double.infinity,
//                     height: 10,
//                     child:
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Color(0xFFF6F6F6),
//                       ),
//                       child: Container(
//                         width: 375,
//                         height: 10,
//                       ),
//                     ),
//                   ),
//                   Container(
//                     margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Container(
//                           margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
//                           child: Align(
//                             alignment: Alignment.topLeft,
//                             child: Text(
//                               '위치',
//                               style: TextStyle(
//                                 fontFamily: 'Pretendard',
//                                 fontWeight: FontWeight.w600,
//                                 fontSize: 16,
//                                 height: 1,
//                                 letterSpacing: -0.4,
//                                 color: Color(0xFF222222),
//                               ),
//                             ),
//                           ),
//                         ),
//                         Container(
//                           decoration: BoxDecoration(
//                             color: Color(0xFFFFFFFF),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Container(
//                             width: 335,
//                             height: 219,
//                             child:
//                             Positioned(
//                               left: -136,
//                               bottom: -141,
//                               child: Container(
//                                 decoration: BoxDecoration(
//                                   image: DecorationImage(
//                                     fit: BoxFit.cover,
//                                     image: NetworkImage(
//                                       'assets/images/rectangle.png',
//                                     ),
//                                   ),
//                                 ),
//                                 child: Container(
//                                   width: 500,
//                                   height: 500,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             // 여기에 추가 컨텐츠를 넣을 수 있습니다.
//           ],
//         ),
//       ),
//
//
//       bottomNavigationBar:Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             height: 75,
//             child: ElevatedButton(
//               onPressed: () {
//                 // 버튼을 눌렀을 때의 동작을 여기에 추가하세요.
//               },
//               style: ElevatedButton.styleFrom(
//                 primary: Color(0xFF1D4786), // 배경색
//                 onPrimary: Colors.white, // 텍스트 색상
//                 padding: EdgeInsets.symmetric(vertical: 13), // 내부 패딩 (높이 조정)
//                 minimumSize: Size(double.infinity, kBottomNavigationBarHeight), // 버튼 크기 설정
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.zero, // 둥근 모서리를 제거하고 직사각형 모양으로 설정
//                   side: BorderSide(color: Color(0xFF1D4786)), // 테두리 색상 설정
//                 ),
//               ),
//               child: Text(
//                 '도와주기',
//                 style: TextStyle(
//                   fontFamily: 'Pretendard',
//                   fontWeight: FontWeight.w600,
//                   fontSize: 18,
//                   height: 1,
//                   letterSpacing: -0.5,
//                   color: Colors.white, // 텍스트 색상
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
// }
//
