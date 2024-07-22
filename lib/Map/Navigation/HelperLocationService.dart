import 'package:background_locator_2/background_locator.dart'; // BackgroundLocator 라이브러리
import 'package:background_locator_2/settings/android_settings.dart'; // Android 설정을 위한 라이브러리
import 'package:background_locator_2/settings/ios_settings.dart'; // iOS 설정을 위한 라이브러리
import 'package:background_locator_2/settings/locator_settings.dart'; // 위치 추적 설정을 위한 라이브러리
import 'package:flutter/material.dart'; // Flutter의 기본 패키지
import 'LocationCallbackHandler.dart'; // LocationCallbackHandler 클래스

class HelperLocationService {
  final String helperId; // 헬퍼 ID를 저장하는 변수

  HelperLocationService(this.helperId); // 생성자에서 헬퍼 ID를 받아서 설정

  void configureBackgroundLocation() {
    // helperId 설정
    LocationCallbackHandler.setHelperId(helperId);

    // BackgroundLocator를 사용하여 위치 업데이트 설정
    BackgroundLocator.registerLocationUpdate(
      LocationCallbackHandler.callback, // 위치 업데이트 콜백 함수
      initCallback: LocationCallbackHandler.initCallback, // 초기화 콜백 함수
      disposeCallback: LocationCallbackHandler.disposeCallback, // 해제 콜백 함수
      iosSettings: IOSSettings(
        accuracy: LocationAccuracy.NAVIGATION, // iOS의 위치 추적 정확도 설정
        distanceFilter: 3, // 3미터마다 업데이트
      ),
      androidSettings: AndroidSettings(
        accuracy: LocationAccuracy.NAVIGATION, // Android의 위치 추적 정확도 설정
        interval: 5, // 위치 업데이트 간격 (밀리초)
        distanceFilter: 3, // 3미터마다 업데이트
        androidNotificationSettings: AndroidNotificationSettings(
          notificationChannelName: 'Location tracking', // 알림 채널 이름
          notificationTitle: 'Tracking location', // 알림 제목
          notificationMsg: 'Your location is being tracked', // 알림 메시지
          notificationIconColor: Colors.grey, // 알림 아이콘 색상
          notificationTapCallback: LocationCallbackHandler.notificationCallback, // 알림 클릭 시 콜백 함수
        ),
      ),
    );
  }
}
