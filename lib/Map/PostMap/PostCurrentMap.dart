import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:lottie/lottie.dart' as lottie;

class PostCurrentMap extends StatefulWidget {
  final String documentId;
  PostCurrentMap({required this.documentId});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<PostCurrentMap> {
  late KakaoMapController _mapController; // Kakao Map Controller 초기화
  LatLng? currentSelectedLocation; // 사용자가 선택한 위치를 저장하는 변수
  Set<Marker> markers = {}; // 마커를 저장할 변수
  LatLng? markerPosition; // 마커의 위치를 관리할 새로운 변수

  @override
  void initState() {
    super.initState();
    AuthRepository.initialize(
        appKey: 'd6e6f6cbd79272654032b63d9da30100'); // Kakao Map 인증 초기화
  }

  // 현재 위치로 지도 이동하는 함수
  void _moveToCurrentLocation(String documentId) async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('naver_posts')
        .doc(documentId)
        .get();

    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    var storeLocation = data['current_location'];
    if (storeLocation != null) {
      List<String> latLngParts = storeLocation.split(',');
      if (latLngParts.length == 2) {
        // 위도와 경도를 double 형태로 변환합니다.
        double latitude = double.tryParse(latLngParts[0]) ?? 0.0;
        double longitude = double.tryParse(latLngParts[1]) ?? 0.0;
        LatLng storeLatLng = LatLng(latitude, longitude);

        setState(() {
          currentSelectedLocation = storeLatLng; // 선택된 위치 업데이트
          markers.clear(); // 기존 마커 제거
          markers.add(Marker(
            markerId: UniqueKey().toString(),
            latLng: storeLatLng,
            // draggable: true, // 마커를 드래그 가능하게 설정
          ));
        });


        // 지도의 중심을 업데이트
        _mapController.setCenter(storeLatLng);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Stack(
          children: [
            Positioned.fill(
              child: lottie.Lottie.asset(
                'assets/lottie/blue3.json',
                fit: BoxFit.fill,
                options: lottie.LottieOptions(

                )
              ),
            ),
            AppBar(
              backgroundColor: Colors.transparent,
              // elevation: 4,
              // shadowColor: Colors.indigo.withOpacity(0.5),
              title: Text('사용자 위치',
                style: TextStyle(
                  fontFamily: 'NanumSquareRound',
                  fontWeight: FontWeight.w600,
                  fontSize : 23,
                ),
              ),
              actions: <Widget>[
              ],
              centerTitle: true,

            ),
          ],
        ),
      ),

      // appBar: AppBar(
      //   backgroundColor: Color(0xFFFF8B13),
      //   title: Text('사용자 위치', style: TextStyle(fontWeight: FontWeight.bold),),
      // ),

      body: Stack(
        children: [
          KakaoMap(
            onMapCreated: (controller) {
              _mapController = controller; // Kakao Map Controller 생성 및 할당
              _moveToCurrentLocation(widget.documentId); // documentId 사용
            },
            markers: markers.toList(),
            // 마커 리스트 설정
            center: currentSelectedLocation ?? LatLng(36.351041, 127.301007),
            // 초기 중심 위치 설정
            onMarkerDragChangeCallback: (String markerId, LatLng latLng,
                int zoomLevel, MarkerDragType markerDragType) {
              if (markerDragType == MarkerDragType.end) {
                markerPosition = latLng;
              }
            },
          ),
        ],
      ),
    );
  }
}