import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:location/location.dart';


class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late KakaoMapController _mapController; // Kakao Map Controller 초기화
  LatLng? selectedLocation; // 사용자가 선택한 위치를 저장하는 변수
  Set<Marker> markers = {}; // 마커를 저장할 변수
  LatLng? markerPosition; // 마커의 위치를 관리할 새로운 변수

  @override
  void initState() {
    super.initState();
    AuthRepository.initialize(appKey: 'd6e6f6cbd79272654032b63d9da30100'); // Kakao Map 인증 초기화
    // 초기 중심 위치에 마커 추가

  }

  // 현재 위치로 지도 이동하는 함수
  void _moveToCurrentLocation() async {
    var location = new Location();
    var currentLocation = await location.getLocation(); // 현재 위치 정보 가져오기
    LatLng newCenter = LatLng(currentLocation.latitude!, currentLocation.longitude!);

    setState(() {
      selectedLocation = newCenter; // 선택된 위치 업데이트
      markers.clear(); // 기존 마커 제거
      markers.add(Marker(
        markerId: UniqueKey().toString(),
        latLng: newCenter,
        draggable: true, // 마커를 드래그 가능하게 설정
      ));
    });

    // 지도의 중심을 업데이트하는 로직이 필요 (kakao_map_plugin 문서 참조)
    _mapController.setCenter(newCenter);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFFF8B13),
        title: Text('현재 위치 선택'),
      ),
      body: KakaoMap(
        onMapCreated: (controller) {
          _mapController = controller; // Kakao Map Controller 생성 및 할당
        },
        markers: markers.toList(), // 마커 리스트 설정
        center: selectedLocation ?? LatLng(36.351041, 127.301007), // 초기 중심 위치 설정

        onMarkerDragChangeCallback: (String markerId, LatLng latLng, int zoomLevel, MarkerDragType markerDragType) {
          if (markerDragType == MarkerDragType.end) {
            markerPosition = latLng;
          }
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _moveToCurrentLocation, // 현재 위치로 이동 버튼 누를 때 _moveToCurrentLocation 함수 호출
        tooltip: '현재 위치로 이동',
        child: Icon(Icons.my_location),
      ),


      bottomNavigationBar: BottomAppBar(
        // color: Colors.transparent, // 배경 색상을 투명하게 설정
        child: Container(
          margin: EdgeInsets.all(16.0), // 여백 추가
          decoration: BoxDecoration(
            color: Color(0xFFFF8B13), // 버튼 배경색
            borderRadius: BorderRadius.circular(10.0), // 버튼 모서리를 둥글게 만듦

          ),
          child: ElevatedButton(
            onPressed: () {
              if (selectedLocation == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('현재 위치를 선택해주세요.', textAlign: TextAlign.center,),
                  duration: Duration(seconds: 2),
                ));
                return;
              }

              else if(markerPosition != selectedLocation){
                selectedLocation = markerPosition;
                Navigator.of(context).pop(selectedLocation);
              }

              else{
                Navigator.of(context).pop(selectedLocation); // 화면을 닫고 선택된 위치 반환
              }
            },
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
