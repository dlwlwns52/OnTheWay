// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:kakao_map_plugin/kakao_map_plugin.dart';
// import 'package:http/http.dart' as http;
//
// class RouteMapScreen extends StatefulWidget {
//   @override
//   _RouteMapScreenState createState() => _RouteMapScreenState();
// }
//
// class _RouteMapScreenState extends State<RouteMapScreen> {
//
//   List<Polyline> polylines = [];
//   late KakaoMapController _mapController; // Kakao Map Controller 초기화
//   LatLng? storeSelectedLocation; // 사용자가 선택한 위치를 저장하는 변수
//   Set<Marker> markers = {}; // 마커를 저장할 변수
//   LatLng? markerPosition; // 마커의 위치를 관리할 새로운 변수
//
//
//   @override
//   void initState() {
//     super.initState();
//     getCarDirection();
//     AuthRepository.initialize(appKey: 'd6e6f6cbd79272654032b63d9da30100'); // Kakao Map 인증 초기화
//   }
//
//   void getCarDirection() async {
//     const String REST_API_KEY = 'c8111ea329648994aa9529377ce7766f';
//     const String url = 'https://apis-navi.kakaomobility.com/v1/directions';
//
//     String origin = '36.402461020967664,127.42474065006031';
//     String destination = '36.44872437488492,127.42882136402619';
//
//     final response = await http.get(
//       Uri.parse('$url?origin=$origin&destination=$destination'),
//       headers: {
//         'Authorization': 'KakaoAK $REST_API_KEY',
//         'Content-Type': 'application/json',
//       },
//     );
//
//     if (response.statusCode == 200) {
//       var data = json.decode(response.body);
//       createPolyline(data);
//     } else {
//       throw Exception('Failed to load directions');
//     }
//   }
//
//   void createPolyline(dynamic data) {
//     List<LatLng> linePath = [];
//     var roads = data['routes'][0]['sections'][0]['roads'];
//
//     for (var road in roads) {
//       for (int i = 0; i < road['vertexes'].length; i += 2) {
//         double lat = road['vertexes'][i + 1];
//         double lng = road['vertexes'][i];
//         linePath.add(LatLng(lat, lng));
//       }
//     }
//
//     final polyline = Polyline(
//       polylineId: 'route',
//       points: linePath,
//       strokeColor: Colors.blue,
//       strokeWidth: 5,
//     );
//
//     setState(() {
//       polylines.add(polyline);
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: KakaoMap(
//         onMapCreated: (controller) {
//           _mapController = controller; // Kakao Map Controller 생성 및 할당
//         },
//         polylines: polylines,
//         markers: markers.toList(), // 마커 리스트 설정
//         center: storeSelectedLocation ?? LatLng(36.351041, 127.301007), // 초기 중심 위치 설정
//         onMarkerDragChangeCallback: (String markerId, LatLng latLng, int zoomLevel, MarkerDragType markerDragType) {
//           if (markerDragType == MarkerDragType.end) {
//             markerPosition = latLng;
//           }
//         },
//       ),
//
//     );
//   }
//
// }
