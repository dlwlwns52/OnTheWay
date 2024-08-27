

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';


class Design extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<Design> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
        child: AppBar(
          title: Text(
            '알림',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 19,
              height: 1.0,
              // letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Color(0xFF1D4786),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_outlined), // '<' 모양의 뒤로가기 버튼 아이콘
            color: Colors.white, // 아이콘 색상
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context); // 뒤로가기 기능
            },
          ),
          actions: [
            // IconButton(
            //   icon: Icon(isDeleteMode ? Icons.delete_outline : Icons.delete),
            //   onPressed: () {
            //     HapticFeedback.lightImpact();
            //     setState(() {
            //       isDeleteMode = !isDeleteMode; // 삭제 모드 상태 토글
            //     });
            //   },
            // ),
          ],
        ),
      ),

      body: Container(// 전체
        margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Column( // 전체
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 25,),
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        '새로운 알림',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          height: 1,
                          letterSpacing: -0.4,
                          color: Color(0xFF1D4786),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child:
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0xFFEEEEEE),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(0, 16, 0, 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.fromLTRB(0, 0, 26.9, 0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 0, 10, 30),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),

                                        ),
                                        child: Container(
                                          child : SvgPicture.asset(
                                            'assets/pigma/person.svg',
                                            width: 30,
                                            height: 30,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: Text(
                                              '이은지',
                                              style: TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                height: 1,
                                                letterSpacing: -0.4,
                                                color: Color(0xFF222222),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                          child: Text(
                                            '도와주기를 요청하였습니다.',
                                            style: TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              height: 1,
                                              letterSpacing: -0.4,
                                              color: Color(0xFF222222),
                                            ),
                                          ),
                                        ),
                                        Align(
                                          alignment: Alignment.topLeft,
                                          child: Text(
                                            '1시간 전',
                                            style: TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                              height: 1,
                                              letterSpacing: -0.3,
                                              color: Color(0xFFAAAAAA),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              child: Container(
                                margin: EdgeInsets.fromLTRB(0, 15, 0, 15),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Color(0xFF4B7CC5)),
                                  borderRadius: BorderRadius.circular(100),
                                  color: Color(0xFFFFFFFF),
                                ),
                                child: Container(
                                  padding: EdgeInsets.fromLTRB(14.5, 2.5, 19, 2.5),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.fromLTRB(0, 0, 2, 0),
                                        child: Container(
                                            child : SvgPicture.asset(
                                              'assets/pigma/book.svg',
                                              width: 25,
                                              height: 25,
                                            ),
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.fromLTRB(0, 5, 6.3, 5),
                                        child: Text(
                                          'A+',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            height: 1,
                                            letterSpacing: -0.4,
                                            color: Color(0xFF1D4786),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                                        child: Text(
                                          '(4.5)',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                            height: 1,
                                            letterSpacing: -0.4,
                                            color: Color(0xFF767676),
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
            // Column(
            //   mainAxisAlignment: MainAxisAlignment.start,
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     Container(
            //       margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
            //       child: Align(
            //         alignment: Alignment.topLeft,
            //         child: Text(
            //           '지난 알림',
            //           style: GoogleFonts.getFont(
            //             'Roboto Condensed',
            //             fontWeight: FontWeight.w600,
            //             fontSize: 16,
            //             height: 1,
            //             letterSpacing: -0.4,
            //             color: Color(0xFF1D4786),
            //           ),
            //         ),
            //       ),
            //     ),
            //
            //
            //
            //     Container(
            //       margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
            //       child: Opacity(
            //         opacity: 0.8,
            //         child: Container(
            //           child:
            //           Container(
            //             width: double.infinity,
            //             decoration: BoxDecoration(
            //               border: Border(
            //                 bottom: BorderSide(
            //                   color: Color(0xFFEEEEEE),
            //                   width: 1,
            //                 ),
            //               ),
            //             ),
            //             child: Container(
            //               padding: EdgeInsets.fromLTRB(0, 16, 0, 15),
            //               child: Row(
            //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                 crossAxisAlignment: CrossAxisAlignment.start,
            //                 children: [
            //                   Expanded(
            //                     child: Container(
            //                       margin: EdgeInsets.fromLTRB(0, 0, 26.9, 0),
            //                       child: Row(
            //                         mainAxisAlignment: MainAxisAlignment.start,
            //                         crossAxisAlignment: CrossAxisAlignment.start,
            //                         children: [
            //                           Container(
            //                             margin: EdgeInsets.fromLTRB(0, 0, 10, 30),
            //                             child: Container(
            //                               decoration: BoxDecoration(
            //                                 borderRadius: BorderRadius.circular(16),
            //                                 // image: DecorationImage(
            //                                 //   fit: BoxFit.cover,
            //                                 //   image: NetworkImage(
            //                                 //     'assets/images/rectangle_490514.jpeg',
            //                                 //   ),
            //                                 // ),
            //                               ),
            //                               child: Container(
            //                                 decoration: BoxDecoration(
            //                                   borderRadius: BorderRadius.circular(16),
            //                                   // image: DecorationImage(
            //                                   //   fit: BoxFit.cover,
            //                                   //   image: NetworkImage(
            //                                   //     'assets/images/rectangle_49053.jpeg',
            //                                   //   ),
            //                                   // ),
            //                                 ),
            //                                 child: Container(
            //                                   width: 32,
            //                                   height: 32,
            //                                 ),
            //                               ),
            //                             ),
            //                           ),
            //                           Column(
            //                             mainAxisAlignment: MainAxisAlignment.start,
            //                             crossAxisAlignment: CrossAxisAlignment.start,
            //                             children: [
            //                               Container(
            //                                 margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
            //                                 child: Align(
            //                                   alignment: Alignment.topLeft,
            //                                   child: Text(
            //                                     '이은지',
            //                                     style: GoogleFonts.getFont(
            //                                       'Roboto Condensed',
            //                                       fontWeight: FontWeight.w600,
            //                                       fontSize: 16,
            //                                       height: 1,
            //                                       letterSpacing: -0.4,
            //                                       color: Color(0xFF222222),
            //                                     ),
            //                                   ),
            //                                 ),
            //                               ),
            //                               Container(
            //                                 margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
            //                                 child: Text(
            //                                   '도와주기를 요청하였습니다.',
            //                                   style: GoogleFonts.getFont(
            //                                     'Roboto Condensed',
            //                                     fontWeight: FontWeight.w500,
            //                                     fontSize: 14,
            //                                     height: 1,
            //                                     letterSpacing: -0.4,
            //                                     color: Color(0xFF222222),
            //                                   ),
            //                                 ),
            //                               ),
            //                               Align(
            //                                 alignment: Alignment.topLeft,
            //                                 child: Text(
            //                                   '1시간 전',
            //                                   style: GoogleFonts.getFont(
            //                                     'Roboto Condensed',
            //                                     fontWeight: FontWeight.w500,
            //                                     fontSize: 12,
            //                                     height: 1,
            //                                     letterSpacing: -0.3,
            //                                     color: Color(0xFFAAAAAA),
            //                                   ),
            //                                 ),
            //                               ),
            //                             ],
            //                           ),
            //                         ],
            //                       ),
            //                     ),
            //                   ),
            //                   Expanded(
            //                     child: Container(
            //                       margin: EdgeInsets.fromLTRB(0, 15, 0, 15),
            //                       decoration: BoxDecoration(
            //                         border: Border.all(color: Color(0xFF4B7CC5)),
            //                         borderRadius: BorderRadius.circular(100),
            //                         color: Color(0xFFFFFFFF),
            //                       ),
            //                       child: Container(
            //                         padding: EdgeInsets.fromLTRB(14.5, 2.5, 19, 2.5),
            //                         child: Row(
            //                           mainAxisAlignment: MainAxisAlignment.start,
            //                           crossAxisAlignment: CrossAxisAlignment.start,
            //                           children: [
            //                             Container(
            //                               margin: EdgeInsets.fromLTRB(0, 0, 2, 0),
            //                               child: Container(
            //                                 decoration: BoxDecoration(
            //                                   image: DecorationImage(
            //                                     fit: BoxFit.cover,
            //                                     image: NetworkImage(
            //                                       'assets/images/ontheway.png',
            //                                     ),
            //                                   ),
            //                                 ),
            //                                 child: Container(
            //                                   width: 24,
            //                                   height: 24,
            //                                 ),
            //                               ),
            //                             ),
            //                             Container(
            //                               margin: EdgeInsets.fromLTRB(0, 5, 6.3, 5),
            //                               child: Text(
            //                                 'A+',
            //                                 style: GoogleFonts.getFont(
            //                                   'Roboto Condensed',
            //                                   fontWeight: FontWeight.w700,
            //                                   fontSize: 14,
            //                                   height: 1,
            //                                   letterSpacing: -0.4,
            //                                   color: Color(0xFF1D4786),
            //                                 ),
            //                               ),
            //                             ),
            //                             Container(
            //                               margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
            //                               child: Text(
            //                                 '(4.5)',
            //                                 style: GoogleFonts.getFont(
            //                                   'Roboto Condensed',
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
            //                       ),
            //                     ),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           ),
            //         ),
            //       ),
            //     ),
            //
            //
            //   ],
            // ),

    );
  }
}