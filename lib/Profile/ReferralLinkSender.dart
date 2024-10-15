// ReferralLinkSender
import 'dart:io';

import 'package:OnTheWay/login/LoginScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:share_plus/share_plus.dart';


class ReferralLinkSenderScreen extends StatefulWidget {
  final String nickname;

  ReferralLinkSenderScreen({required this.nickname});


  @override
  _ReferralLinkSenderScreenState createState() => _ReferralLinkSenderScreenState();
}

class _ReferralLinkSenderScreenState extends State<ReferralLinkSenderScreen> {
  String? referralCode;
  int referralCount = 0;  // 기본값을 0으로 설정
  bool isLoading = true;  // 데이터를 로드하는 동안 로딩 상태 표시

  @override
  void initState() {
    super.initState();
    // Firestore에서 referralCode와 referralCount 가져오기
    fetchReferralData();
  }

  Future<void> fetchReferralData() async {
    try {
      // Firestore에서 widget.nickname 문서를 찾음
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.nickname) // nickname을 문서 ID로 사용한다고 가정
          .get();

      if (documentSnapshot.exists) {
        // referralCode 필드 가져오기
        setState(() {
          referralCode = documentSnapshot['referralCode'];
          referralCount = documentSnapshot['referralCount'] ?? 0;
        });
      } else {
        print('문서를 찾을 수 없습니다.');
        setState(() {
        });
      }
    } catch (e) {
      print('Error getting referral data: $e');
      setState(() {
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
        child: AppBar(
          title: Text(
            '초대하기',
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

      body: Center(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height*0.13,),

            // 이미지 크기 조정 (적절한 크기로 변경)
            Container(
              width: 140, // 크기를 조금 더 키움
              height: 140,
              child: SvgPicture.asset('assets/svgs/group_add.svg'),
            ),

            // 첫 번째 설명 텍스트
            Container(
              margin: EdgeInsets.fromLTRB(0, 24, 0, 16), // 여백 조정
              child:
              // Text(
              //   '본인의 추천인 코드 : ${referralCode} 를 확인하고 \n친구에게 전송해보세요!',
              //   style: TextStyle(
              //     fontFamily: 'Pretendard',
              //     fontWeight: FontWeight.w600,
              //     fontSize: 18,  // 폰트 크기 키움
              //     height: 1.4,
              //     letterSpacing: -0.4,
              //     color:  Color(0xFF222222),
              //   ),
              //   textAlign: TextAlign.center,
              // ),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '본인의 추천인 코드 : ',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600, // 더 굵게
                        fontSize: 18,  // 폰트 크기 키움
                        height: 1.4,
                        letterSpacing: -0.4,
                        color: Color(0xFF222222),
                      ),
                    ),


                    TextSpan(
                      text: '${referralCode}',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600, // 더 굵게
                        fontSize: 20,  // 폰트 크기 키움
                        height: 1.4,
                        letterSpacing: -0.4,
                        color: Color(0xFF1D4786),
                      ),
                    ),
                    TextSpan(
                      text: ' 를 확인하고',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600, // 더 굵게
                        fontSize: 18,  // 폰트 크기 키움
                        height: 1.4,
                        letterSpacing: -0.4,
                        color: Color(0xFF222222),
                      ),
                    ),

                    TextSpan(
                      text: ' \n친구에게 전송해보세요.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600, // 더 굵게
                        fontSize: 18,  // 폰트 크기 키움
                        height: 1.4,
                        letterSpacing: -0.4,
                        color: Color(0xFF222222),
                      ),
                    ),

                  ],
                ),
              ),
            ),

            // 강조 텍스트: 세 명이 추천을 통해 가입하면
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '추천을 통해 ',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600, // 더 굵게
                      fontSize: 18,  // 폰트 크기 키움
                      height: 1.4,
                      letterSpacing: -0.4,
                      color: Color(0xFF222222),
                    ),
                  ),
                  TextSpan(
                    text: '3명',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600, // 더 굵게
                      fontSize: 20,  // 폰트 크기 키움
                      height: 1.4,
                      letterSpacing: -0.4,
                      color: Color(0xFF1D4786),
                    ),
                  ),
                  TextSpan(
                    text: ' 이 가입하면\n',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600, // 더 굵게
                      fontSize: 18,  // 폰트 크기 키움
                      height: 1.4,
                      letterSpacing: -0.4,
                      color: Color(0xFF222222),
                    ),
                  ),

                  TextSpan(
                    text: '빽다방 기프티콘',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600, // 더 굵게
                      fontSize: 20,  // 폰트 크기 키움
                      height: 1.4,
                      letterSpacing: -0.4,
                      color: Color(0xFF1D4786),
                    ),
                  ),
                  TextSpan(
                    text: ' 이 이메일로 전송됩니다!',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600, // 더 굵게
                      fontSize: 18,  // 폰트 크기 키움
                      height: 1.4,
                      letterSpacing: -0.4,
                      color: Color(0xFF222222),
                    ),
                  ),

                ],
              ),
            ),

            // 전송하기 버튼 설명 텍스트
            //
            // Container(
            //   margin: EdgeInsets.fromLTRB(0, 32, 0, 16), // 여백 조정
            //   child:  RichText(
            //     textAlign: TextAlign.center,
            //     text: TextSpan(
            //       children: [
            //         TextSpan(
            //           text: '추천을 통해 ',
            //           style: TextStyle(
            //             fontFamily: 'Pretendard',
            //             fontWeight: FontWeight.w600, // 더 굵게
            //             fontSize: 18,  // 폰트 크기 키움
            //             height: 1.4,
            //             letterSpacing: -0.4,
            //             color: Color(0xFF767676),
            //           ),
            //         ),
            //         TextSpan(
            //           text: '3명',
            //           style: TextStyle(
            //             fontFamily: 'Pretendard',
            //             fontWeight: FontWeight.w600, // 더 굵게
            //             fontSize: 20,  // 폰트 크기 키움
            //             height: 1.4,
            //             letterSpacing: -0.4,
            //             color: Color(0xFF1D4786),
            //           ),
            //         ),
            //         TextSpan(
            //           text: ' 이 가입하면\n\n',
            //           style: TextStyle(
            //             fontFamily: 'Pretendard',
            //             fontWeight: FontWeight.w600, // 더 굵게
            //             fontSize: 18,  // 폰트 크기 키움
            //             height: 1.4,
            //             letterSpacing: -0.4,
            //             color: Color(0xFF767676),
            //           ),
            //         ),
            //
            //         TextSpan(
            //           text: '빽다방 기프티콘',
            //           style: TextStyle(
            //             fontFamily: 'Pretendard',
            //             fontWeight: FontWeight.w600, // 더 굵게
            //             fontSize: 20,  // 폰트 크기 키움
            //             height: 1.4,
            //             letterSpacing: -0.4,
            //             color: Color(0xFF1D4786),
            //           ),
            //         ),
            //         TextSpan(
            //           text: ' 이 이메일로 전송됩니다!\n\n',
            //           style: TextStyle(
            //             fontFamily: 'Pretendard',
            //             fontWeight: FontWeight.w600, // 더 굵게
            //             fontSize: 18,  // 폰트 크기 키움
            //             height: 1.4,
            //             letterSpacing: -0.4,
            //             color: Color(0xFF767676),
            //           ),
            //         ),
            //
            //       ],
            //     ),
            //   ),
            // ),
            //

            Container(
              margin: EdgeInsets.fromLTRB(0, 32, 0, 16), // 여백 조정
              child:  RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '지금 바로 아래 ',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600, // 더 굵게
                        fontSize: 18,  // 폰트 크기 키움
                        height: 1.4,
                        letterSpacing: -0.4,
                        color: Color(0xFF222222),

                      ),
                    ),
                    TextSpan(
                      text: '전송하기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600, // 더 굵게
                        fontSize: 20,  // 폰트 크기 키움
                        height: 1.4,
                        letterSpacing: -0.4,
                        color: Color(0xFF1D4786),
                      ),
                    ),
                    TextSpan(
                      text: ' 버튼을 눌러보세요!\n\n',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600, // 더 굵게
                        fontSize: 18,  // 폰트 크기 키움
                        height: 1.4,
                        letterSpacing: -0.4,
                        color: Color(0xFF222222),

                      ),
                    ),

                    TextSpan(
                      text: '현재까지 ',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600, // 더 굵게
                        fontSize: 14,  // 폰트 크기 키움
                        height: 1.4,
                        letterSpacing: -0.4,
                        color: Color(0xFF767676),

                      ),
                    ),
                    TextSpan(
                      text: '${referralCount}',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600, // 더 굵게
                        fontSize: 16,  // 폰트 크기 키움
                        height: 1.4,
                        letterSpacing: -0.4,
                        color: Color(0xFF1D4786),
                      ),
                    ),
                    TextSpan(
                      text: ' 명 초대하셨습니다!',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600, // 더 굵게
                        fontSize: 14,  // 폰트 크기 키움
                        height: 1.4,
                        letterSpacing: -0.4,
                        color: Color(0xFF767676),
                      ),
                    ),
                  ],
                ),
              ),
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
                // 공유할 텍스트
                String shareText ="대학생 전용 배달 플랫폼, 온더웨이! 🎉\n\n아래 링크를 통해 앱을 다운로드하고 회원가입 시 추천인 코드를 입력해 주세요.\n\n추천인 코드: ${referralCode}\n\n다운로드 링크: https://apps.apple.com/kr/app/%EC%98%A8%EB%8D%94%EC%9B%A8%EC%9D%B4/id6720720743";
                // 공유 기능 호출
                Share.share(shareText, subject: '추천 코드를 보내고 \n커피 상품 받아가세요!');
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // 아이콘과 텍스트를 중앙 정렬
                children: [
                  Text(
                    '전송하기',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      height: 1,
                      letterSpacing: -0.5,
                      color: Colors.white, // 텍스트 색상
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

    );

  }
}
