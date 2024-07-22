import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lottie/lottie.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OwnerTMapView extends StatefulWidget {
  final String currentLocation;
  final String storeLocation;
  final String helperId;

  OwnerTMapView({required this.currentLocation, required this.storeLocation, required this.helperId});

  @override
  State<OwnerTMapView> createState() => _OwnerTMapViewState();
}

class _OwnerTMapViewState extends State<OwnerTMapView> {
  late WebViewController controller;
  DatabaseReference? _locationRef;
  double? _latitude;
  double? _longitude;

  // 길찾기 함수 호출
  void update(String startLocation, String endLocation) {
    // startLocation과 endLocation을 ','를 기준으로 분리하여 위도와 경도를 추출
    List<String> startCoords = startLocation.split(',');
    List<String> endCoords = endLocation.split(',');

    // JavaScript 함수 호출
    controller.runJavaScript(
        "update('${startCoords[0]}', '${startCoords[1]}', '${endCoords[0]}', '${endCoords[1]}');"
    );
  }


  void moveToHelperLocation() {
    controller.runJavaScript("moveToHelperLocation();");
  }

  @override
  void initState() {
    super.initState();

    // 헬퍼 위치 업데이트 리스너 설정
    _locationRef = FirebaseDatabase.instance.ref().child('locations/${widget.helperId}');
    _locationRef!.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      setState(() {
        _latitude = data?['latitude'];
        _longitude = data?['longitude'];
      });

    });

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            // 페이지 로딩이 완료되면 메서드를 호출
            print(1);
            update(widget.currentLocation, widget.storeLocation);
            if (_latitude != null && _longitude != null) {
              print(2);
              controller.runJavaScript("setHelperId('${widget.helperId}');");
              controller.runJavaScript("updateHelperLocation('$_latitude', '$_longitude');");
            }
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://ontheway-b2bdf.web.app'));
  }




  void updateHelperLocation(double lat, double lon) {
    controller.runJavaScript(
        "updateHelperLocation('$lat', '$lon');"
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Stack(
          children: [
            Positioned.fill(
              child: Lottie.asset(
                  'assets/lottie/blue3.json',
                  fit: BoxFit.fill,
                  options: LottieOptions(
                  )
              ),
            ),
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 1,
              shadowColor: Colors.indigo.withOpacity(0.5),
              title: Text('헬퍼 위치 확인',
                style: TextStyle(
                  fontFamily: 'NanumSquareRound',
                  fontWeight: FontWeight.w700,
                  fontSize: 23,
                ),
              ),
              actions: <Widget>[
              ],
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: WebViewWidget(controller: controller),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          margin: EdgeInsets.all(16.0), // 여백 추가
          decoration: BoxDecoration(
            color: Colors.indigo[300], // 버튼 배경색
            borderRadius: BorderRadius.circular(10.0), // 버튼 모서리를 둥글게 만듦

          ),
          //저장하기 버튼
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '헬 위치로 이동 중 입니다. \n잠시만 기다려주세요.',
                    textAlign: TextAlign.center,
                  ),
                  duration: Duration(seconds: 1),
                ),
              );
              moveToHelperLocation();
            },

            // 위치 값 저장
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pin_drop), // 저장 아이콘
                SizedBox(width: 8.0), // 아이콘과 텍스트 사이의 간격 조절
                Text('헬퍼 위치로 이동', style: TextStyle(fontSize: 18),),
              ],
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[300],
              elevation: 0, // 경계선을 제거합니다.
            ),
          ),
        ),
      ),
    );
  }
}
