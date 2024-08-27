import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:OnTheWay/login/LoginScreen.dart';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'HanbatSchoolBoard/HanbatSchoolBoard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';




Future<void> backgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
  // 백그라운드에서 수신된 메시지를 처리하는 로직
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 엔진 초기화
  await Firebase.initializeApp(); // Firebase 초기화를 기다림
  FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler); // 백그라운드 메시지 핸들러 등록
  AuthRepository.initialize(appKey: 'd6e6f6cbd79272654032b63d9da30100'); // 인증 리포지토리 초기화
  await initializeDateFormatting(); // 날짜 형식 초기화를 기다림


  runApp(MyApp()); // 앱 실행
}



Future<Map<String, dynamic>> _autoLogin() async {
  await Future.delayed(Duration(seconds: 1)); // 데이터 로딩을 시뮬레이션하기 위한 코드
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic> loginResult = {
    'isAutoLogin': false,
    'domain': '',
  };

  if (user != null) {
    String? email = user.email;
    if (email != null) {
      QuerySnapshot querySnapshot = await firestore.collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = querySnapshot.docs.first;
        bool autoLogin = userDoc['isAutoLogin'] ?? false;
        String domain = userDoc['domain'] ?? '';
        if (autoLogin) {
          loginResult['isAutoLogin'] = true;
          loginResult['domain'] = domain;
        }
      }
    }
  }
  return loginResult;
}



class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<Map<String, dynamic>>? autoLoginResult;

  @override
  void initState() {
    super.initState();
    autoLoginResult = _autoLogin();

    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   if (message.data['screen'] == 'AlarmUi' && mounted) {
    //     Navigator.of(context).push(MaterialPageRoute(builder: (_) => NaverBoardPage()));
    //   }
    // });

  }

// Future<void> initPlatformState() async {
//   await BackgroundLocator.initialize(); // background_locator_2 초기화
// }


@override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Map<String, dynamic>>(
        future: autoLoginResult,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingScreen(); // 로딩 중 화면
          }
          else if (snapshot.hasData) {
            bool isAutoLogin = snapshot.data?['isAutoLogin'] ?? false;
            String domain = snapshot.data?['domain'] ?? '';
            if (isAutoLogin) {
              switch (domain) {
                case 'naver.com':
                  return HanbatBoardPage();

              // 여기에 다른 도메인별 게시판 페이지 조건을 추가

                default:
                  return LoginScreen(); // 기본 게시판 페이지 // 테스트로 현재 게시판으로 이동
              }
            } else {
              // return LoginScreen(); // 로그인 화면
              return LoginScreen(); // 임시
            }
          }
          else {
            return LoginScreen(); // 오류 화면
          }
        },
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 교차 축(수평 방향)의 정렬을 설정합니다.
          children: <Widget>[
            Image.asset(
              'assets/images/LoginLogo.png',
              width: 200, // 이미지 너비를 설정합니다.
              height: 200, // 이미지 높이를 설정합니다.
            ),
            // Image.asset(
            //   'assets/images/LoginLogo2.png',
            //   width: 300, // 이미지 너비를 설정합니다.
            //   height: 600, // 이미지 높이를 설정합니다.
            // ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}






