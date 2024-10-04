import 'dart:io';

import 'package:OnTheWay/login/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'SchoolBoard.dart';


class SuccessReportScreen extends StatefulWidget {

  @override
  _SuccessReportScreenState createState() => _SuccessReportScreenState();
}

class _SuccessReportScreenState extends State<SuccessReportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.01), // 화면 높이의 2% 만큼 여백
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.fill,
                  image: AssetImage(
                    'assets/images/FindPassword.png',
                  ),
                ),
              ),
              width: 140,
              height: 140,
            ),

            Text(
              '신고 내역이 정상적으로 접수되었습니다. \n소중한 의견 감사드리며, 신속히 처리하겠습니다.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                height: 1.3,
                letterSpacing: -0.4,
                color: Color(0xFF1D4786),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),

      bottomNavigationBar:Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: Platform.isAndroid ? MediaQuery.of(context).size.width * 0.15 : MediaQuery.of(context).size.width * 0.20,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BoardPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1D4786), // 배경색
                foregroundColor: Colors.white, // 텍스트 색상
                padding: EdgeInsets.symmetric(vertical: 13), // 내부 패딩 (높이 조정)
                minimumSize: Size(double.infinity, kBottomNavigationBarHeight), // 버튼 크기 설정
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // 둥근 모서리를 제거하고 직사각형 모양으로 설정
                  side: BorderSide(color: Color(0xFF1D4786)), // 테두리 색상 설정
                ),
              ),
              child: Text(
                '확인',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
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
