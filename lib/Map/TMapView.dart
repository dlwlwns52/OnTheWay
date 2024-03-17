import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';


class TMapView extends StatefulWidget { // StatefulWidget을 상속받는 VideoCard 클래스를 정의합니다. 이는 상태가 변경될 수 있는 위젯을 만들기 위함입니다.
  final String currentLocation;
  final String storeLocation;

  TMapView({required this.currentLocation, required this.storeLocation});

  @override
  State<TMapView> createState() => _TMapViewState(); // VideoCard 위젯의 상태를 생성합니다.
}
class _TMapViewState extends State<TMapView> {
  late WebViewController controller;

// JavaScript 함수를 호출하는 함수 예시
  void update(String startLocation, String endLocation) {
    // startLocation과 endLocation을 ','를 기준으로 분리하여 위도와 경도를 추출
    List<String> startCoords = startLocation.split(',');
    List<String> endCoords = endLocation.split(',');

    // JavaScript 함수 호출
// JavaScript 함수 호출
    controller.runJavaScript(
        "update('${startCoords[0]}', '${startCoords[1]}', '${endCoords[0]}', '${endCoords[1]}');");

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
            // if (request.url.startsWith('https://www.youtube.com/')) {
            //   return NavigationDecision.prevent;
            // }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://ontheway-b2bdf.web.app'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Scaffold를 사용하여 앱바와 뒤로가기 버튼을 추가합니다.
      appBar: AppBar( // AppBar를 추가합니다.
        backgroundColor: Colors.deepOrangeAccent,
        title: Text("길찾기", style: TextStyle(fontWeight: FontWeight.bold),),  // 앱바의 제목을 설정합니다.
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
    );
  }
}
