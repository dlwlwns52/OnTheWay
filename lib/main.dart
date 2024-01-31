import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'Alarm/AlarmUi.dart';
import 'NaverBoard/NaverUiBoard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:OnTheWay/Alarm/Alarm.dart';

Future<void> backgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
  // 백그라운드에서 수신된 메시지를 처리하는 로직
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);

  AuthRepository.initialize(appKey: 'd6e6f6cbd79272654032b63d9da30100');
  runApp(MyApp());
}

Future<String> loadSomeData() async {
  await Future.delayed(Duration(seconds: 1)); // 데이터 로딩을 시뮬레이션하기 위한 코드
  return 'Some data';
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['screen'] == 'AlarmUi') {
        // `Navigator`를 사용하여 `AlarmUi` 화면으로 이동합니다.
        // 이 예제에서는 `AlarmUi` 클래스를 직접 구현해야 합니다.
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => AlarmUi()));
      }
    });
  }
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        // FutureBuilder는 Future 객체와 함께 사용하여, Future가 완료될 때까지 로딩 화면을 표시하고,
        // Future가 완료되면 해당 데이터를 화면에 표시하는데 사용됩니다.
        future: loadSomeData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return LoadingScreen(); // 로딩 중일 때는 LoadingScreen을 표시
          } else {
            // return LoginScreen(); // 로딩이 완료되면 LoginScreen으로 전환
            return NaverBoardPage();

          }
        },
      ),
      routes: {
        '/naverBoard': (context) => NaverBoardPage(),
        // '/hanbatBoard': (context) => HanbatBoardScreen(),
        // '/yahooBoard': (context) => YahooBoardScreen(),
        // '/defaultBoard': (context) => DefaultBoardScreen(),
        // 기타 라우트 추가 가능
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // 주 축(수직 방향)의 정렬을 설정합니다.
          crossAxisAlignment: CrossAxisAlignment.center, // 교차 축(수평 방향)의 정렬을 설정합니다.
          children: <Widget>[
            Center(
              child: AutoSizeText(
                'OnTheWay',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 60,
                  color: Color(0xFFFF8B13),
                ),
                maxLines: 1,
              ),
            ),


            SizedBox(height: 30),

            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}
