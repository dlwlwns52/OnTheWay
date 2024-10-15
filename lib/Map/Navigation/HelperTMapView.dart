import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HelperTMapView extends StatefulWidget {
  final String currentLocation;
  final String storeLocation;

  HelperTMapView({required this.currentLocation, required this.storeLocation});

  @override
  State<HelperTMapView> createState() => _HelperTMapViewState();
}

class _HelperTMapViewState extends State<HelperTMapView> {
  late WebViewController controller;
  String distance = '';
  String time = '';

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

  // 초기 위치 설정
  void setCurrentLocation() {
    controller.runJavaScript("setCurrentLocation();");
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
          onWebResourceError: (WebResourceError error) {
            print("Web resource error: ${error.description}");
          },
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '길찾기',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 19,
            height: 1.0,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),

        centerTitle: true,
        backgroundColor: Color(0xFF1D4786),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined), // '<' 모양의 뒤로가기 버튼 아이콘
          color: Colors.white, // 아이콘 색상
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context); // 뒤로가기 기능
          },
        ),
        actions: <Widget>[
        ],
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
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: Platform.isAndroid ? MediaQuery.of(context).size.width * 0.00 : MediaQuery.of(context).size.width * 0.20,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1D4786), // 배경색
                foregroundColor: Colors.white, // 텍스트 색상
                padding: EdgeInsets.symmetric(vertical: 13), // 내부 패딩 (높이 조정)
                minimumSize: Size(double.infinity, kBottomNavigationBarHeight), // 버튼 크기 설정
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // 둥근 모서리를 제거하고 직사각형 모양으로 설정
                  side: BorderSide(color: Color(0xFF1D4786)), // 테두리 색상 설정
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // 아이콘과 텍스트를 중앙 정렬
                children: [
                  Icon(
                    Icons.pin_drop, // 원하는 아이콘 선택
                    size: 24, // 아이콘 크기
                    color: Colors.white, // 아이콘 색상
                  ),
                  SizedBox(width: 13), // 아이콘과 텍스트 사이 간격
                  Text(
                    '현재 위치로 이동',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 21,
                      height: 1,
                      letterSpacing: -0.5,
                      color: Colors.white, // 텍스트 색상
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}