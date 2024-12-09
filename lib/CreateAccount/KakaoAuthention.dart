import 'dart:io';

import 'package:OnTheWay/CreateAccount/CreateAccount.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class KakaoLoginScreen extends StatefulWidget {
  @override
  _KakaoLoginScreenState createState() => _KakaoLoginScreenState();
}

class _KakaoLoginScreenState extends State<KakaoLoginScreen> {
  bool isAuth = false;
  String? kakao_nickname;
  String? kakao_email;

  //스낵바
  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void updateAuthStatus(bool status) {
    setState(() {
      isAuth = status;
    });
  }



  // 로그인 메서드
  Future<void> _loginWithKakao() async {
    HapticFeedback.lightImpact();
    try {
      // 1. 카카오톡 설치 여부 확인
      bool isInstalled = await isKakaoTalkInstalled();
      print('카카오톡 설치 여부: $isInstalled');

      if (isInstalled) {
        try {
          await UserApi.instance.loginWithKakaoTalk();
          updateAuthStatus(true);
          showSnackBar('카카오 인증이 완료되었습니다.');
        }

        catch (error) {
          print('카카오톡으로 로그인 실패 $error');
          if(isAuth) {
            updateAuthStatus(false);
          }
          await UserApi.instance.logout();

          return;

        }
      }

      else {
        try {
          await UserApi.instance.loginWithKakaoAccount();
          updateAuthStatus(true);
          showSnackBar('카카오 인증이 완료되었습니다.');

        } catch (error) {
          if(isAuth) {
            updateAuthStatus(false);
          }
            await UserApi.instance.logout();
            return;

        }
      }

      // 사용자 정보 요청
      User user = await UserApi.instance.me();
      kakao_nickname = user.kakaoAccount?.profile?.nickname;
      kakao_email = user.kakaoAccount?.email;

    } catch (e) {
      print('카카오 로그인 실패: $e');
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
            '카카오 인증',
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
      ),
      body: Center(
        child: GestureDetector(
          onTap: _loginWithKakao,
          child: Image.asset(
            'assets/images/kakao_login_large_narrow.png',
            width: 312,
            height: 48,
          ),
        ),
      ),

      bottomNavigationBar:Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: Platform.isAndroid ? MediaQuery.of(context).size.width * 0.15 : MediaQuery.of(context).size.width * 0.20,
            child: ElevatedButton(
              onPressed: () {
                if(isAuth && kakao_nickname!=null && kakao_email != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CreateAccount(kakao_email: kakao_email!, kakao_nickname: kakao_nickname!,)),
                  );

                  HapticFeedback.lightImpact();
                }

                if(!isAuth){
                  HapticFeedback.lightImpact();
                  showSnackBar('카카오 인증을 완료해주세요.');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isAuth ? Color(0xFF1D4786) : Color(0xFFB4C8E7), // 배경색
                foregroundColor: Colors.white, // 텍스트 색상
                padding: EdgeInsets.symmetric(vertical: 13), // 내부 패딩 (높이 조정)
                minimumSize: Size(double.infinity, kBottomNavigationBarHeight), // 버튼 크기 설정
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // 둥근 모서리를 제거하고 직사각형 모양으로 설정
                  side: BorderSide(color: isAuth ? Color(0xFF1D4786) : Color(0xFFB4C8E7)), // 테두리 색상 설정
                ),
              ),
              child: Text(
                '인증 완료',
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

