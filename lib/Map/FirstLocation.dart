import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class FirstLocation {
  final DatabaseReference _locationRef;

  FirstLocation(String helperNickname)
      : _locationRef = FirebaseDatabase.instance.ref().child('locations/$helperNickname');

  // 초기 위치 저장
  Future<void> saveInitialLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    await _locationRef.set({
      'latitude': position.latitude,
      'longitude': position.longitude,
    });
  }
}
