import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OwnerTMapView extends StatefulWidget {
  final String currentLocation;
  final String storeLocation;
  final String helperId;
  final String documentName;

  OwnerTMapView({required this.currentLocation, required this.storeLocation, required this.helperId, required this.documentName});

  @override
  State<OwnerTMapView> createState() => _OwnerTMapViewState();
}

class _OwnerTMapViewState extends State<OwnerTMapView> with WidgetsBindingObserver {  // WidgetsBindingObserver 추가
  late WebViewController controller;

  //파이어베이스에서 헬퍼 위치 데이터 가져오기
  Future<String?> getHelperLocation(String documentName) async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('ChatActions')
          .doc(documentName)
          .get();

      if (documentSnapshot.exists) {
        // 문서가 존재하면 helper_location 필드를 가져옴
        String? helperLocation = documentSnapshot.get('helper_location');
        return helperLocation;
      } else {
        print("Document does not exist.");
        return null;
      }
    } catch (e) {
      print("Failed to get helper location: $e");
      return null;
    }
  }


  //경로찾기
  void update(String startLocation, String endLocation) {
    List<String> startCoords = startLocation.split(',');
    List<String> endCoords = endLocation.split(',');

    controller.runJavaScript(
        "update('${startCoords[0]}', '${startCoords[1]}', '${endCoords[0]}', '${endCoords[1]}');"
    );
  }

  // Firestore에서 ownerClick 업데이트
  void _updateOwnerClick(bool isClicked) {
    FirebaseFirestore.instance
        .collection('ChatActions')
        .doc(widget.documentName)
        .update({
      'ownerClick': isClicked,
    });
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _updateOwnerClick(true);
        break;
      case AppLifecycleState.inactive:
        print("앱이 비활성화되었습니다.");
        // 앱이 비활성화될 때 수행할 작업
        break;
      case AppLifecycleState.paused:
        print("앱이 일시 중지되었습니다.");
        _updateOwnerClick(false); // 앱이 백그라운드로 가거나 종료될 때 업데이트
        break;
      case AppLifecycleState.detached:
        print("앱이 종료되었습니다.");
        _updateOwnerClick(false);// 앱이 백그라운드로 가거나 종료될 때 업데이트
        break;
      case AppLifecycleState.hidden:
        print("앱이 숨겨졌습니다.");
        _updateOwnerClick(false); // 앱이 숨겨졌을 때 업데이트
        break;
    }
  }


  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);  // 오브저버 등록
    _updateOwnerClick(true);

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            // 페이지 로딩이 완료되면 메서드를 호출
            update(widget.currentLocation, widget.storeLocation);
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://ontheway-b2bdf.web.app'));

    // Firestore 리스너 추가 -> helper_location 변할때마다 호출
    FirebaseFirestore.instance
        .collection('ChatActions')
        .doc(widget.documentName)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        String? helperLocation = snapshot.get('helper_location');
        if (helperLocation != null) {
          List<String> coords = helperLocation.split(',');
          String latitude = coords[0];
          String longitude = coords[1];

          // JavaScript 함수 호출하여 헬퍼 위치 업데이트
          controller.runJavaScript(
              "updateHelperLocation($latitude, $longitude);"
          );
        }
      }
    });

    // 위젯이 트리에 완전히 삽입된 후에 스낵바를 보여줌
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min, // 스낵바의 크기를 텍스트 내용에 맞춤
            children: [
              Text(
                "헬퍼위치 데이터를 업로드 중입니다. \n잠시만 기다려 주세요.",
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6), // 텍스트 사이에 약간의 여백 추가
              Text(
                "헬퍼가 앱을 종료할 경우에는, 위치 추적이 중단됩니다!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13, // 작은 텍스트 크기
                  color: Colors.white70, // 텍스트 색상을 약간 밝게 설정
                ),
              ),
            ],
          ),
          duration: Duration(seconds: 2),
        ),

      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);  // 오브저버 해제
    _updateOwnerClick(false); // 페이지 종료 시 ownerClick을 false로 설정
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '헬퍼 위치',
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
        child: WebViewWidget(controller: controller),
      ),
    );
  }
}
