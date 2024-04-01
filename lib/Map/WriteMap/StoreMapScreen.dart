import 'package:OnTheWay/Map/WriteMap/CurrentMapScreen.dart';
import 'package:flutter/material.dart';
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('위치데이터를 불러오는 중입니다.\n 잠시만 기다려 주세요.',
        textAlign: TextAlign.center,),
        duration: Duration(milliseconds: 900),
      ),
    );

    var location = new Location();
    var currentLocation = await location.getLocation(); // 현재 위치 정보 가져오기
    LatLng newCenter = LatLng(currentLocation.latitude!, currentLocation.longitude!);
    print(newCenter);

    setState(() {
      storeSelectedLocation = newCenter; // 선택된 위치 업데이트
      markers.clear(); // 기존 마커 제거
      markers.add(Marker(
        markerId: UniqueKey().toString(),
        latLng: newCenter,
        draggable: true, // 마커를 드래그 가능하게 설정
      ));
    });

    // 지도의 중심을 업데이트
    _mapController.setCenter(newCenter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFF8B13),
        title: Text('가게 위치 설정', style: TextStyle(fontWeight: FontWeight.bold),),
      ),

      body: Stack(
          children : [
            KakaoMap(
        onMapCreated: (controller) {
          _mapController = controller; // Kakao Map Controller 생성 및 할당
        },
        markers: markers.toList(), // 마커 리스트 설정
        center: storeSelectedLocation ?? LatLng(36.351041, 127.301007), // 초기 중심 위치 설정(현재 한밭대)
        onMarkerDragChangeCallback: (String markerId, LatLng latLng, int zoomLevel, MarkerDragType markerDragType) {
          if (markerDragType == MarkerDragType.end) {
            markerPosition = latLng;
          }
        },
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
                      '위치 설정',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 80.0, // 원하는 버튼의 너비
                    height: 80.0, // 원하는 버튼의 높이
                    child: FloatingActionButton(
                      onPressed: _moveToCurrentLocation,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.my_location,
                        size: 60, // 아이콘 크기 조절
                        color: Colors.black,), // 아이콘 크기
                      tooltip: '설정된 위치로 이동',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),


      //바텀바 ui
      bottomNavigationBar: BottomAppBar(
        child: Container(
          margin: EdgeInsets.all(16.0), // 여백 추가
          decoration: BoxDecoration(
            color: Color(0xFFFF8B13), // 버튼 배경색
            borderRadius: BorderRadius.circular(10.0), // 버튼 모서리를 둥글게 만듦

          ),
          //저장하기 버튼
          child: ElevatedButton(
            onPressed: () {
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

            // 위치 값 저장
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pin_drop), // 저장 아이콘
                SizedBox(width: 8.0), // 아이콘과 텍스트 사이의 간격 조절
                Text('저장하기', style: TextStyle(fontSize: 18),),
              ],
            ),
            style: ElevatedButton.styleFrom(
              primary: Color(0xFFFF8B13),
              elevation: 0, // 경계선을 제거합니다.
            ),
          ),
        ),
      ),
    );
  }
}

