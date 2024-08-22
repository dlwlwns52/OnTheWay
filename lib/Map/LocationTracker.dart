import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationTracker {
  bool trackingEnabled = false;
  StreamSubscription<Position>? positionStream;
  Timer? _timer;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String docunmetName;  // 사용자 닉네임을 저장하는 필드

  // 생성자에서 닉네임을 받아서 초기화
  LocationTracker(this.docunmetName);


  // 위치 권한 요청
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // throw Exception('위치 권한이 거부되었습니다.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // throw Exception('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 수동으로 허용해주세요.');
      return false;
    }
    return true;
  }

  // 위치 추적 시작
  void startTracking() async {
    // 이미 tracking 중이면 재실행하지 않도록 방지
    if (_timer != null && _timer!.isActive) {
      print("이미 위치 추적이 실행 중입니다.");
      return;
    }

    trackingEnabled = true;

    _timer = Timer.periodic(Duration(seconds: 120), (Timer t) async {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      saveLocation(position);
    });
  }



  // 위치 데이터 저장
  void saveLocation(Position position) async {
    String locationString = "${position.latitude},${position.longitude}";
    if (trackingEnabled) {
      await _firestore.collection('ChatActions').doc(docunmetName).update({
        'helper_location': locationString,
        'helper_timestamp': FieldValue.serverTimestamp(),
      });
      print("${position.latitude}, ${position.longitude} 저장완료");
    }
  }

  // 위치 추적 중지
  void stopTracking() {
    trackingEnabled = false;
    _timer?.cancel();
  }
}
