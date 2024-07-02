import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TMapView extends StatefulWidget {
  final String currentLocation;
  final String storeLocation;

  TMapView({required this.currentLocation, required this.storeLocation});

  @override
  State<TMapView> createState() => _TMapViewState();
}

class _TMapViewState extends State<TMapView> {
  late WebViewController controller;
  String distance = '';
  String time = '';

  // JavaScript 함수를 호출하는 함수 예시
  void update(String startLocation, String endLocation) {
    // startLocation과 endLocation을 ','를 기준으로 분리하여 위도와 경도를 추출
    List<String> startCoords = startLocation.split(',');
    List<String> endCoords = endLocation.split(',');

    // JavaScript 함수 호출
    controller.runJavaScript(
        "update('${startCoords[0]}', '${startCoords[1]}', '${endCoords[0]}', '${endCoords[1]}');"
    );
  }

  //현재위치 호출
  void moveToCurrentLocation() {
    controller.runJavaScript("moveToCurrentLocation();");
  }

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            // 페이지 로딩이 완료되면 updateMap 메서드를 호출
            update(widget.currentLocation, widget.storeLocation);
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://ontheway-b2bdf.web.app'));

    // 길찾기 기능 참고용 안내 알림을 초기화 후 보여줌
    // WidgetsBinding.instance.addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '길찾기 기능은 참고용으로만 사용해 주세요.\n감사합니다.',
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 1),
        ),
      );
    });

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
              title: Text('길찾기', style: TextStyle(fontWeight: FontWeight.bold),),
              actions: <Widget>[
              ],
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            Expanded(
              child: WebViewWidget(controller: controller),
            ),
          ],
        ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '현재 위치로 이동 중 입니다. \n잠시만 기다려주세요.',
                    textAlign: TextAlign.center,
                  ),
                  duration: Duration(seconds: 1),
                ),
              );
              moveToCurrentLocation();
            },

            // 위치 값 저장
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pin_drop), // 저장 아이콘
                SizedBox(width: 8.0), // 아이콘과 텍스트 사이의 간격 조절
                Text('현재 위치로 이동', style: TextStyle(fontSize: 18),),
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