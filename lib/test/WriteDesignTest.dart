
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

class WriteDesignTest extends StatefulWidget {
  @override
  _WriteDesignTestState createState() => _WriteDesignTestState();
}

class _WriteDesignTestState extends State<WriteDesignTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '게시글 작성',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 19,
            height: 1.0,
            letterSpacing: -0.5,
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
        // 상단 왼쪽 빈 공간을 만들기 위해 빈 SizedBox를 사용
        actions: [

        ],
      ),


      body: Center(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              '픽업 장소',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                height: 1,
                                letterSpacing: -0.4,
                                color: Color(0xFF424242),
                              ),
                            ),
                          ),
                        ),


                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFD0D0D0)),
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xFFFFFFFF),
                          ),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(15,17, 15, 17),
                            child:
                            Text(
                              '픽업 장소를 입력해주세요.',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w500,
                                fontSize: 17,
                                height: 1,
                                letterSpacing: -0.4,
                                color: Color(0xFF767676),
                              ),
                            ),
                          ),
                        ),


                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFD0D0D0)),
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xFFFFFFFF),
                          ),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(0, 13, 0, 13),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: SvgPicture.asset(
                                    'assets/pigma/write_locate.svg',
                                  ),
                                ),
                                SizedBox(
                                  width:5,
                                ),
                                Container(
                                  margin: EdgeInsets.fromLTRB(0, 4, 0, 4),
                                  child: Text(
                                    '현재 위치로 찾기',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17,
                                      height: 1,
                                      letterSpacing: -0.4,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              '드랍 장소',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                height: 1,
                                letterSpacing: -0.4,
                                color: Color(0xFF424242),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFD0D0D0)),
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xFFFFFFFF),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.fromLTRB(15,17, 15, 17),
                            child:
                            Text(
                              '드랍 장소를 입력해주세요.',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w500,
                                fontSize: 17,
                                height: 1,
                                letterSpacing: -0.4,
                                color: Color(0xFF767676),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFD0D0D0)),
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xFFFFFFFF),
                          ),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(0, 11, 0, 11),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: SvgPicture.asset(
                                    'assets/pigma/write_locate.svg',
                                  ),
                                ),
                                SizedBox(
                                  width:5,
                                ),
                                Container(
                                  margin: EdgeInsets.fromLTRB(0, 4, 0, 4),
                                  child: Text(
                                    '현재 위치로 찾기',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 17,
                                      height: 1,
                                      letterSpacing: -0.4,
                                      color: Color(0xFF222222),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              '금액',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                height: 1,
                                letterSpacing: -0.4,
                                color: Color(0xFF424242),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFFD0D0D0)),
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xFFFFFFFF),
                          ),
                          child: Container(
                            padding: EdgeInsets.fromLTRB(15, 17, 15, 17),
                            child:
                            Text(
                              '₩ 금액을 입력해주세요.',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                height: 1,
                                letterSpacing: -0.4,
                                color: Color(0xFF767676),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                            '요청사항',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              height: 1,
                              letterSpacing: -0.4,
                              color: Color(0xFF424242),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: MediaQuery.of(context).size.width * 0.4,
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFFD0D0D0)),
                          borderRadius: BorderRadius.circular(12),
                          color: Color(0xFFFFFFFF),
                        ),
                        child: Container(
                          padding: EdgeInsets.fromLTRB(15, 19, 24.4, 15),
                          child:
                          Text(
                            '요청사항을 입력해주세요. \n(민감한 세부 정보는 채팅을 이용해주세요.)',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                              height: 1.4,
                              letterSpacing: -0.4,
                              color: Color(0xFF767676),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar:Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            Container(
              height: MediaQuery.of(context).size.width*0.20,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                },
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFF1D4786), // 배경색
                  onPrimary: Colors.white, // 텍스트 색상
                  padding: EdgeInsets.symmetric(vertical: 13), // 내부 패딩 (높이 조정)
                  minimumSize: Size(double.infinity, kBottomNavigationBarHeight), // 버튼 크기 설정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // 둥근 모서리를 제거하고 직사각형 모양으로 설정
                    side: BorderSide(color: Color(0xFF1D4786)), // 테두리 색상 설정
                  ),
                ),
                child: Text(
                  '게시하기',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 21,
                    height: 1,
                    letterSpacing: -0.5,
                    color: Colors.white, // 텍스트 색상
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}