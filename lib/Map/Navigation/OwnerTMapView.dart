import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:lottie/lottie.dart';
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
  //
  // //헬퍼위치 호출
  // void moveToHelperLocation() async {
  //   String? helperLocation = await getHelperLocation(widget.documentName);
  //   if (helperLocation != null) {
  //     List<String> coords = helperLocation.split(',');
  //     String latitude = coords[0];
  //     String longitude = coords[1];
  //
  //     controller.runJavaScript(
  //         "updateHelperLocation($latitude, $longitude);"
  //     );
  //   }
  // }



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
          print('리스너 테스트 - 호출');
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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Stack(
          children: [
            Positioned.fill(
              child: Lottie.asset(
                'assets/lottie/blue3.json',
                fit: BoxFit.fill,
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
              centerTitle: true,
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: WebViewWidget(controller: controller),
      ),
    );
  }
}
