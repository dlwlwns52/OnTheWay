import 'dart:async'; // 비동기 프로그래밍을 위한 라이브러리
import 'dart:isolate'; // Isolate를 사용하기 위한 라이브러리
import 'dart:ui'; // UI 작업을 위한 라이브러리
import 'package:background_locator_2/location_dto.dart'; // 위치 데이터를 나타내는 DTO 클래스
import 'package:firebase_database/firebase_database.dart'; // Firebase 실시간 데이터베이스 사용
import 'dart:math'; // 수학 계산을 위한 라이브러리

class LocationCallbackHandler {
  static const String _isolateName = "LocatorIsolate"; // Isolate 이름을 정의
  static String? _helperId; // 헬퍼 ID를 저장하기 위한 변수
  static double? _prevLatitude; // 이전 위치의 위도
  static double? _prevLongitude; // 이전 위치의 경도

  // 위치 업데이트가 발생할 때 호출되는 콜백 함수
  @pragma('vm:entry-point') // VM entry-point를 정의하여 플러그인 콜백 함수로 사용
  static void callback(LocationDto locationDto) async {
    final SendPort? send = IsolateNameServer.lookupPortByName(_isolateName); // Isolate 이름으로 포트를 찾음
    send?.send(locationDto); // 포트를 통해 위치 데이터를 전송

    // 헬퍼 ID가 설정되어 있으면
    // 헬퍼 ID가 설정되어 있으면
    if (_helperId != null) {
      // 이전 위치가 설정되어 있지 않으면 현재 위치를 이전 위치로 설정
      if (_prevLatitude == null || _prevLongitude == null) {
        _prevLatitude = locationDto.latitude;
        _prevLongitude = locationDto.longitude;
        // Firebase에 위치 저장
        print('새롭게 저장 ${_prevLatitude} ${_prevLongitude}');
        saveLocationToFirebase(locationDto.latitude, locationDto.longitude);
      } else {
        // 이전 위치와 현재 위치 간의 거리를 계산
        double distance = getDistance(_prevLatitude!, _prevLongitude!, locationDto.latitude, locationDto.longitude);
        // 거리가 3미터 이상일 경우에만 위치를 저장
        if (distance >= 3) {
          _prevLatitude = locationDto.latitude;
          _prevLongitude = locationDto.longitude;
          // Firebase에 위치 저장
          saveLocationToFirebase(locationDto.latitude, locationDto.longitude);
          print('3미터 저장 ${_prevLatitude} ${_prevLongitude}');

        }
      }
    }
  }

  // 플러그인 초기화 시 호출되는 함수
  @pragma('vm:entry-point')
  static Future<void> initCallback(Map<dynamic, dynamic> params) async {
    print('Plugin initialization'); // 초기화 로그 출력
    IsolateNameServer.registerPortWithName(params['sendPort'], _isolateName); // Isolate 이름과 포트를 등록
  }

  // 알림 클릭 시 호출되는 콜백 함수
  @pragma('vm:entry-point')
  static void notificationCallback() {
    print('User clicked on the notification'); // 알림 클릭 로그 출력
  }

  // 플러그인 해제 시 호출되는 콜백 함수
  @pragma('vm:entry-point')
  static void disposeCallback() {
    print('BackgroundLocator has been stopped'); // 플러그인 중지 로그 출력
  }


  // 헬퍼 ID를 설정하는 함수
  static void setHelperId(String helperId) {
    _helperId = helperId;
  }


  // Firebase에 위치를 저장하는 함수
  static void saveLocationToFirebase(double latitude, double longitude) {
    DatabaseReference locationRef = FirebaseDatabase.instance.ref().child('locations/$_helperId'); // Firebase 경로 설정
    locationRef.set({
      'latitude': latitude, // 위도 저장
      'longitude': longitude, // 경도 저장
    });
  }


  // 두 지점 간의 거리를 계산하는 함수 (Haversine formula 사용)
  static double getDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // 지구의 반지름 (km)
    double dLat = (lat2 - lat1) * (pi / 180); // 위도 차이
    double dLon = (lon2 - lon1) * (pi / 180); // 경도 차이
    double a = 0.5 - cos(dLat) / 2 +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
            (1 - cos(dLon)) / 2; // Haversine formula 계산
    return R * 2 * asin(sqrt(a)) * 1000; // 결과를 미터로 변환
  }
}
