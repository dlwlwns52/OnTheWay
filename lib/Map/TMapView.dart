import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TMapView extends StatefulWidget {
  @override
  _TMapViewState createState() => _TMapViewState();
}

class _TMapViewState extends State<TMapView> {
  @override
  Widget build(BuildContext context) {
    return WebView(
      initialUrl: 'https://your_firebase_hosting_url/index.html', // Firebase Hosting URL로 교체
      javascriptMode: JavascriptMode.unrestricted,
    );
  }
}
