import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../Chat/FullScreenImage.dart';
import 'ReferralLinkSender.dart';

class EventScreen extends StatefulWidget {
  final String nickname;

  // final String oldAccountNumber;
  EventScreen({required this.nickname});


  @override
  _EventScreenState createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {


  Widget _buildMenuItem(BuildContext context, String title, String period, String leadingIcon, {String? trailingIcon, bool isFirstItem = false}) {
    return Container(
      margin: isFirstItem
          ? EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.025)
          : EdgeInsets.fromLTRB(
        0,
        MediaQuery.of(context).size.height * 0.023,
        0,
        MediaQuery.of(context).size.height * 0.023,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.02),
                width: 20,
                height: 20,
                child: SvgPicture.asset(leadingIcon),
              ),
              // Text(
              //   title,
              //   style: TextStyle(
              //     fontFamily: 'Pretendard',
              //     fontWeight: FontWeight.w500,
              //     fontSize: MediaQuery.of(context).size.width * 0.04,
              //     height: 1,
              //     letterSpacing: -0.4,
              //     color: Color(0xFF222222),
              //   ),
              // ),

              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: title,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        height: 1,
                        letterSpacing: -0.4,
                        color: Color(0xFF222222),
                      ),
                    ),

                    TextSpan(
                      text: period,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: MediaQuery.of(context).size.width * 0.033,
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
          if (trailingIcon != null)
            Container(
              width: 20,
              height: 20,
              child: SvgPicture.asset(trailingIcon),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: Colors.grey, // 구분선 색상 설정
      // thickness: MediaQuery.of(context).size.height * 0.001, // 구분선 두께를 화면 높이에 비례하게 설정
      height: MediaQuery.of(context).size.height * 0.01, // 구분선과 항목 사이의 간격
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
        child: AppBar(
          title: Text(
            '이벤트',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 19,
              height: 1.0,
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
        ),
      ),




      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child:Container(
              margin: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width * 0.05,
                10,
                MediaQuery.of(context).size.width * 0.05,
                0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        // 이미지를 풀스크린으로 보여주는 FullScreenImage 화면으로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenImage(
                              photoUrl: 'assets/images/cnuCoffeeEvent.jpg', // 로컬 이미지 경로
                              isLocalImage: true,  // 로컬 이미지를 명시적으로 설정
                            ),
                          ),
                        );
                      },
                      child: _buildMenuItem(
                        context,
                        '랭킹 이벤트  ',
                        '( 2024.10.15 ~ 2024.12.31 )',
                        'assets/svgs/tropi.svg',
                        trailingIcon: 'assets/pigma/arrow.svg',
                      ),
                    ),

                    _buildDivider(context),

                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReferralLinkSenderScreen(nickname: widget.nickname ?? '앱 종료 후 다시 시작해주세요.',),
                          ),
                        );
                      },
                      child: _buildMenuItem(
                        context,
                        '추천인 이벤트  ',
                        '( 2024.10.15 ~ )',
                        'assets/svgs/group_add.svg',
                        trailingIcon: 'assets/pigma/arrow.svg',
                      ),
                    ),

                    _buildDivider(context),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
