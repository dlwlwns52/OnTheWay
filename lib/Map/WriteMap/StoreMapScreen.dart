import 'dart:io';

import 'package:OnTheWay/Map/WriteMap/CurrentMapScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:location/location.dart';


class StoreMapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<StoreMapScreen> {
  late KakaoMapController _mapController; // Kakao Map Controller 초기화
  LatLng? storeSelectedLocation; // 사용자가 선택한 위치를 저장하는 변수
  Set<Marker> markers = {}; // 마커를 저장할 변수
  LatLng? markerPosition; // 마커의 위치를 관리할 새로운 변수

  @override
  void initState() {
    super.initState();
    AuthRepository.initialize(appKey: 'd6e6f6cbd79272654032b63d9da30100'); // Kakao Map 인증 초기화
  }

  // 현재 위치로 지도 이동하는 함수
  void _moveToCurrentLocation() async {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text:'위치데이터를 불러오는 중입니다.\n 잠시만 기다려 주세요.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextSpan(
                text: '\n\n⚠️위치 데이터가 불러오지 않으면, \n이전 화면으로 돌아갔다가 다시 시도해 주세요.',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.normal, // 작은 글씨는 일반적인 가중치로 설정
                  fontSize: 12, // 작은 글씨 크기 설정

                ),
              ),
            ],
          ),
        ),
        duration: Duration(milliseconds: 900),
      ),
    );

    var location = new Location();
    var currentLocation = await location.getLocation(); // 현재 위치 정보 가져오기
    LatLng newCenter = LatLng(currentLocation.latitude!, currentLocation.longitude!);

    setState(() {
      storeSelectedLocation = newCenter; // 선택된 위치 업데이트
    });

    // 지도의 중심을 업데이트
    _mapController.setCenter(newCenter);

  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '픽업 장소',
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
      // appBar: AppBar(
      //   backgroundColor: Color(0xFFFF8B13),
      //   title: Text('가게 위치 설정', style: TextStyle(fontWeight: FontWeight.bold),),
      // ),

      body: Stack(
          children : [
            Stack(
              alignment: Alignment.center, // Stack의 모든 자식 위젯을 중앙에 배치
              children: [
                KakaoMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  center: storeSelectedLocation ?? LatLng(37.5718, 126.9769),
                  onCameraIdle: (LatLng center, int zoomLevel) {
                    setState(() {
                      markerPosition = center;
                    });
                  },
                ),
                Container(
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height * 0.05,
                  ),
                  child: Icon(
                    Icons.location_pin,
                    size: 42,
                    color: Colors.red[500],
                  ), // 중앙에 고정된 마커
                ),
              ],
            ),

      //현재위치 아이콘
            Positioned(
              right: 20,
              bottom: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 5)
                      ],
                    ),
                    child: Text(
                      '위치 찾기',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 80.0,
                    height: 80.0,
                    child: ClipOval( // 원형으로 자르기
                      child: FloatingActionButton(
                        onPressed: _moveToCurrentLocation,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.my_location,
                          size: 60, // 아이콘 크기 조절
                          color: Colors.black,
                        ),
                        tooltip: '설정된 위치로 이동',
                      ),
                    ),
                  ),

                ],
              ),
            ),
        ],
      ),


      //바텀바 ui
      bottomNavigationBar:
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            Container(
              height: Platform.isAndroid ? MediaQuery.of(context).size.width * 0.15 : MediaQuery.of(context).size.width * 0.20,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // 현재위치 설정을 안했을때
                  if (storeSelectedLocation == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('현재 위치를 선택해주세요.', textAlign: TextAlign.center,),
                      duration: Duration(seconds: 2),
                    ));
                    return;
                  }

                  // 현재위치 마커와 움직인 마커위치에 따라 값 다르게 넣기
                  else if(markerPosition != storeSelectedLocation){
                    if(markerPosition == null){
                      Navigator.of(context).pop(storeSelectedLocation);
                    }
                    else{
                      storeSelectedLocation = markerPosition;
                      Navigator.of(context).pop(storeSelectedLocation);
                    }
                  }
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
                child: Text(
                  '저장하기',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    height: 1,
                    letterSpacing: -0.5,
                    color: Colors.white, // 텍스트 색상
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

