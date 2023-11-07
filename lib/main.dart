import 'package:flutter/material.dart';
import 'UiBoard.dart';
import 'login/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_size_text/auto_size_text.dart';
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

Future<String> loadSomeData() async {
  await Future.delayed(Duration(seconds: 1)); // 데이터 로딩을 시뮬레이션하기 위한 코드
  return 'Some data';
}

class MyApp extends StatelessWidget {
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
            return BoardPage();
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

      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // 주 축(수직 방향)의 정렬을 설정합니다.
          crossAxisAlignment: CrossAxisAlignment.center, // 교차 축(수평 방향)의 정렬을 설정합니다.
          children: <Widget>[
            AutoSizeText(
              'OnTheWay',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 80,
                color: Colors.orange,
              ),
              maxLines: 1,
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
