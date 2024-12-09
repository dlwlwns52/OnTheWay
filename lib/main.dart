import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:OnTheWay/login/LoginScreen.dart';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_badge/flutter_app_badge.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk_auth.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'SchoolBoard/SchoolBoard.dart';




Future<void> backgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
  // 백그라운드에서 수신된 메시지를 처리하는 로직
}

// 로컬 알림 플러그인 선언
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// 로컬 알림 및 채널 설정 함수
void setupLocalNotifications() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',  // 알림 채널 ID
    'High Importance Notifications',  // 채널 이름
    description: 'This channel is used for important notifications.',  // 채널 설명
    importance: Importance.high,  // 알림 중요도 설정 (높음)
  );

  // 알림 채널 생성
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

// 알림 권한 요청 함수
Future<void> requestNotificationPermission() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    // print('User granted permission');
  } else {
    print('User declined or has not accepted permission');
  }
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 엔진 초기화
  await Firebase.initializeApp(); // Firebase 초기화를 기다림
  FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler); // 백그라운드 메시지 핸들러 등록
  // Kakao Map SDK 초기화
  AuthRepository.initialize(appKey: 'd6e6f6cbd79272654032b63d9da30100');
  //카카오로그인
  KakaoSdk.init(
    nativeAppKey: '69a96da745eed8af5198d8de5d72a2eb', // Kakao Developers에서 발급받은 앱 키
  );

  FlutterAppBadge.count(0); // 실질적으로 배지 0 설정
  await badge_zero(); // 배지 파이어스토어 0으로 업데이트
  await initializeDateFormatting(); // 날짜 형식 초기화를 기다림

  // 로컬 알림 채널 설정
  setupLocalNotifications();
  // 알림 권한 요청
  await requestNotificationPermission();



  // 포그라운드 알림 처리
  FirebaseMessaging.onMessage.listen((RemoteMessage rm) {
    RemoteNotification? notification = rm.notification;
    AndroidNotification? android = rm.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        0,  // 알림 ID
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });


  runApp(MyApp()); // 앱 실행
}

Future<void> badge_zero() async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  String? email = user?.email;
  if(email != null){
    QuerySnapshot querySnapshot = await firestore.collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot userDoc = querySnapshot.docs.first;

      await firestore.collection('users').doc(userDoc.id).update({'badgeCount': 0});

      }
    }
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

  }




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
            if (isAutoLogin) {
              return BoardPage();
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
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // 교차 축(수평 방향)의 정렬을 설정합니다.
          children: <Widget>[
            Image.asset(
              'assets/images/LoginLogo.png',
              width: 170, // 이미지 너비를 설정합니다.
              height: 170, // 이미지 높이를 설정합니다.
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






