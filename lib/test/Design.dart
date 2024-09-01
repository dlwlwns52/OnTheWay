

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
            '알ㅇ림',
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
          ],
        ),
      ),

      body:Container(
        margin: EdgeInsets.fromLTRB(20, 0, 20, 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(0, 16, 0, 15),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE3E3E3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 0, 8, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: NetworkImage(
                                'assets/images/rectangle_490511.jpeg',
                              ),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: NetworkImage(
                                  'assets/images/rectangle_49053.jpeg',
                                ),
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(
                                    'assets/images/rectangle_490510.png',
                                  ),
                                ),
                              ),
                              child: Container(
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.fromLTRB(0, 0, 0, 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.fromLTRB(0, 0, 0, 8),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  '홍길동',
                                  style: GoogleFonts.getFont(
                                    'Roboto Condensed',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    height: 1,
                                    letterSpacing: -0.4,
                                    color: Color(0xFF222222),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              '채팅방이 개설되었습니다.',
                              style: GoogleFonts.getFont(
                                'Roboto Condensed',
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                height: 1,
                                letterSpacing: -0.4,
                                color: Color(0xFF767676),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 2.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(0, 0, 0, 5),
                          child: Text(
                            '18:00',
                            style: GoogleFonts.getFont(
                              'Roboto Condensed',
                              fontWeight: FontWeight.w400,
                              fontSize: 13,
                              height: 1,
                              letterSpacing: -0.3,
                              color: Color(0xFF767676),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(5.4, 0, 2.5, 0),
                          child: Stack(
                            children: [
                              Positioned(
                                top: -4,
                                child: SizedBox(
                                  width: 19.5,
                                  height: 19.5,
                                  child: SvgPicture.network(
                                    'assets/vectors/vector_5_x2.svg',
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.fromLTRB(3.7, 4, 4.1, 3.5),
                                child:
                                Text(
                                  '12',
                                  style: GoogleFonts.getFont(
                                    'Roboto Condensed',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    height: 1,
                                    letterSpacing: -0.3,
                                    color: Color(0xFFFFFFFF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 나머지 Container와 Row 등에도 동일하게 적용해주면 됩니다.
          ],
        ),
      ),



    );
  }
}