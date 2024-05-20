import 'package:flutter/material.dart';
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
          duration: Duration(seconds: 2),
        ),
      );
    });

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: Text(
          "길찾기",
          style: TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}
