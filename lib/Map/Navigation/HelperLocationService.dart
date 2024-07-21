import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class HelperLocationService {
  double? prevLat; // 이전 위도를 저장하기 위한 변수
  double? prevLon; // 이전 경도를 저장하기 위한 변수
  final String helperId; // 헬퍼의 ID를 저장하는 변수

  // 생성자: 헬퍼 ID를 초기화
  HelperLocationService(this.helperId);

  // 백그라운드 위치 추적을 설정하는 메서드
  void configureBackgroundLocation() {
    // 플러그인을 설정
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      // 위치가 3미터 이상 이동했는지 확인
      if (prevLat == null || prevLon == null || getDistance(prevLat!, prevLon!, location.coords.latitude, location.coords.longitude) > 3) {
        // 위치가 이동한 경우, 새로운 위치를 이전 위치로 저장
        prevLat = location.coords.latitude;
        prevLon = location.coords.longitude;

        // 새로운 위치를 Firebase에 저장
        saveHelperLocation(location.coords.latitude, location.coords.longitude);
      }
    });

    // 플러그인 시작
    bg.BackgroundGeolocation.start();
  }

  // 헬퍼의 위치를 Firebase에 저장하는 메서드
  void saveHelperLocation(double latitude, double longitude) {
    final DatabaseReference locationRef = FirebaseDatabase.instance.ref().child('locations/$helperId');
    locationRef.set({
      'latitude': latitude, // 위도를 저장
      'longitude': longitude, // 경도를 저장
    });
  }

  // 두 지점 사이의 거리를 계산하는 함수 (Haversine formula 사용)
  double getDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // 지구의 반지름 (km)
    double dLat = (lat2 - lat1) * (3.141592653589793 / 180); // 위도 차이를 라디안으로 변환
    double dLon = (lon2 - lon1) * (3.141592653589793 / 180); // 경도 차이를 라디안으로 변환
    double a =
        0.5 - cos(dLat)/2 +
            cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
                (1 - cos(dLon))/2; // Haversine formula 계산
    return R * 2 * asin(sqrt(a)) * 1000; // 결과를 미터로 변환하여 반환
  }
}
