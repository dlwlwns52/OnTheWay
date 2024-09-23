import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:location/location.dart';

class CurrentMapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<CurrentMapScreen> {
  late KakaoMapController _mapController; // Kakao Map Controller 초기화
  LatLng? currentSelectedLocation; // 사용자가 선택한 위치를 저장하는 변수
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
        content: Text(
          '위치데이터를 불러오는 중입니다.\n 잠시만 기다려 주세요.',
          textAlign: TextAlign.center,
        ),
        duration: Duration(milliseconds: 900),
      ),
    );

    var location = Location();
    var currentLocation = await location.getLocation(); // 현재 위치 정보 가져오기
    LatLng newCenter = LatLng(currentLocation.latitude!, currentLocation.longitude!);
    setState(() {
      currentSelectedLocation = newCenter; // 선택된 위치 업데이트
    });

    // 지도의 중심을 업데이트
    _mapController.setCenter(newCenter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '드랍 장소',
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
        actions: <Widget>[],
      ),
      body: Stack(
        children: [
          Stack(
            alignment: Alignment.center, // Stack의 모든 자식 위젯을 중앙에 배치
            children: [
              KakaoMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                center: currentSelectedLocation ?? LatLng(37.5718, 126.9769),
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
                  size: 48,
                  color: Colors.indigo[500],
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
                      BoxShadow(color: Colors.black26, blurRadius: 5),
                    ],
                  ),
                  child: Text(
                    '위치 설정',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: 72.0, // 원하는 버튼의 너비
                  height: 72.0, // 원하는 버튼의 높이
                  child: FloatingActionButton(
                    onPressed: _moveToCurrentLocation,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.my_location,
                      size: 54, // 아이콘 크기 조절
                      color: Colors.black,
                    ), // 아이콘 크기
                    tooltip: '설정된 위치로 이동',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      //바텀바 UI
      bottomNavigationBar: BottomAppBar(
        child: Container(
          margin: EdgeInsets.all(16.0), // 여백 추가
          decoration: BoxDecoration(
            color: Color(0xFF1D4786), // 버튼 배경색
            borderRadius: BorderRadius.circular(10.0), // 버튼 모서리를 둥글게 만듦
          ),
          //저장하기 버튼
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              // 현재위치 설정을 안 했을 때
              if (currentSelectedLocation == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '현재 위치를 선택해주세요.',
                      textAlign: TextAlign.center,
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              // 현재위치 마커와 움직인 마커 위치에 따라 값 다르게 넣기
              else if (markerPosition != currentSelectedLocation) {
                if (markerPosition == null) {
                  Navigator.of(context).pop(currentSelectedLocation);
                } else {
                  currentSelectedLocation = markerPosition;
                  Navigator.of(context).pop(currentSelectedLocation);
                }
              }
            },
            // 위치 값 저장
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pin_drop), // 저장 아이콘
                SizedBox(width: 8.0), // 아이콘과 텍스트 사이의 간격 조절
                Text(
                  '저장하기',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1D4786),
              elevation: 0, // 경계선을 제거합니다.
            ),
          ),
        ),
      ),
    );
  }
}
