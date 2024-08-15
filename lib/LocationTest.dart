
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 사용 시


class IsolateExample extends StatefulWidget {
  @override
  _TrackingPageState createState() => _TrackingPageState();
}

class _TrackingPageState extends State<IsolateExample> {
  bool shouldTrack = false;
  StreamSubscription<Position>? positionStream;
  Timer? _timer;

  // Firestore 사용 시
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Realtime Database 사용 시
  // final FirebaseDatabase _database = FirebaseDatabase.instance;

  void toggleTracking() async {
    setState(() {
      shouldTrack = !shouldTrack;
    });

    if (shouldTrack) {
      // 위치 추적 시작
      startTracking();
    } else {
      // 위치 추적 중지
      stopTracking();
    }
  }

  Future<void> _requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('위치 권한이 거부되었습니다.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 수동으로 허용해주세요.');
    }
  }

  void startTracking() async {
    await _requestPermission();
    // 위치 추적 스트림 시작
    _timer = Timer.periodic(Duration(seconds: 5), (Timer t) async {
      // 5초마다 새로운 위치 정보를 얻음
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      saveLocation(position);
    });
  }


  void stopTracking() {
    // 위치 추적 스트림과 타이머 종료
    positionStream?.cancel();
    _timer?.cancel();
  }

  void saveLocation(Position position) async {
    if (shouldTrack) {
      // Firestore에 위치 저장
      await _firestore.collection('locations').add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("${position.latitude}, ${position.longitude} 저장완료");

      // Realtime Database 사용 시
      // await _database.ref('locations').push().set({
      //   'latitude': position.latitude,
      //   'longitude': position.longitude,
      //   'timestamp': ServerValue.timestamp,
      // });
    }
  }

  @override
  void dispose() {
    positionStream?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('위치 추적')),
      body: Center(
        child: ElevatedButton(
          onPressed: toggleTracking,
          child: Text(shouldTrack ? '위치 추적 중지' : '위치 추적 시작'),
        ),
      ),
    );
  }
}
