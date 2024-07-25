// import 'dart:async';
// import 'dart:isolate';
// import 'dart:ui';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:background_locator_2/location_dto.dart';
//
//
// class LocationCallbackHandler {
//   static const String _isolateName = "LocatorIsolate";
//   static String? _helperId;
//   static Timer? _timer;
//   static SendPort? sendPort;
//
//   // 위치 업데이트가 발생할 때 호출되는 콜백 함수
//   static void callback(LocationDto locationDto) async {
//     sendPort = IsolateNameServer.lookupPortByName(_isolateName);
//     sendPort?.send(locationDto.toJson());
//
//     if (_helperId != null) {
//       if (_timer == null) {
//         _timer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
//           saveLocationToFirebase(locationDto.latitude, locationDto.longitude);
//           print('5초마다 저장 ${locationDto.latitude} ${locationDto.longitude}');
//         });
//       }
//     }
//   }
//
//   // 플러그인 초기화 시 호출되는 함수
//   static Future<void> initCallback(Map<dynamic, dynamic> params) async {
//     print('Plugin initialization');
//     if (params.containsKey('sendPort')) {
//       sendPort = params['sendPort'];
//       IsolateNameServer.registerPortWithName(sendPort!, _isolateName);
//     } else {
//       print('SendPort가 null입니다.');
//     }
//   }
//
//   // 알림 클릭 시 호출되는 콜백 함수
//   static void notificationCallback() {
//     print('User clicked on the notification');
//   }
//
//   // 플러그인 해제 시 호출되는 콜백 함수
//   static void disposeCallback() {
//     print('BackgroundLocator has been stopped');
//     _timer?.cancel();
//     _timer = null;
//   }
//
//   // 헬퍼 ID를 설정하는 함수
//   static void setHelperId(String helperId) {
//     _helperId = helperId;
//   }
//
//   // Firebase에 위치를 저장하는 함수
//   static void saveLocationToFirebase(double latitude, double longitude) {
//     DatabaseReference locationRef = FirebaseDatabase.instance.ref().child('locations/$_helperId');
//     locationRef.set({
//       'latitude': latitude,
//       'longitude': longitude,
//     }).then((_) {
//       print('위치 저장 완료: 위도 $latitude, 경도 $longitude');
//     }).catchError((error) {
//       print('위치 저장 실패: $error');
//     });
//   }
//
//   // callbackDispatcher를 포함하여 설정
//   @pragma('vm:entry-point')
//   static void callbackDispatcher() {
//     final ReceivePort port = ReceivePort();
//     IsolateNameServer.registerPortWithName(port.sendPort, _isolateName);
//
//     port.listen((dynamic data) async {
//       if (data is Map<String, dynamic>) {
//         callback(LocationDto.fromJson(data));
//       }
//     });
//   }
// }
//
// extension on LocationDto {
//   Map<String, dynamic> toJson() {
//     return {
//       'latitude': latitude,
//       'longitude': longitude,
//     };
//   }
// }
