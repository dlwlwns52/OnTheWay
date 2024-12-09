import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PostDetailMapView extends StatefulWidget {
  final String currentLocation;
  final String storeLocation;

  PostDetailMapView({required this.currentLocation, required this.storeLocation});

  @override
  State<PostDetailMapView> createState() => _PostDetailMapView();
}

class _PostDetailMapView extends State<PostDetailMapView> {
  late WebViewController controller;

  void update(String startLocation, String endLocation) {
    List<String> startCoords = startLocation.split(',');
    List<String> endCoords = endLocation.split(',');

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
          onPageFinished: (String url) {
            update(widget.currentLocation, widget.storeLocation);
          },
        ),
      )
      ..loadRequest(Uri.parse('https://ontheway-b2bdf.web.app/tmap/'));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12), // 모서리를 둥글게 설정
      child: WebViewWidget(controller: controller), // WebView만 반환
    );
  }
}
