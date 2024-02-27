// 이 코드는 채팅 애플리케이션에서 사용되는 메시지 데이터를 나타내는 Dart 클래스인 'Message' 클래스를 정의합니다.
// 'Message' 클래스는 사용자 간의 채팅 메시지나 이미지 메시지와 같은 채팅 관련 데이터를 다루기 위해 사용됩니다.

import 'package:cloud_firestore/cloud_firestore.dart';

// Message 클래스: 메시지 관련 데이터를 저장하고 처리
class Message {
  // 멤버 변수들: 사용자의 UID, 메시지 타입, 내용, 타임스탬프, 이미지 URL, 읽음 여부
  String receiverName;
  String senderName;
  String senderUid;
  String receiverUid;
  String type;
  String? message; // 메시지는 null일 수 있음 (이미지 메시지일 경우)
  Timestamp timestamp;
  String? photoUrl; // 이미지 URL도 null일 수 있음 (텍스트 메시지일 경우)
  bool read;

  // 생성자: 필수적인 속성들을 받아서 Message 객체를 생성
  Message({
    required this.receiverName,
    required this.senderName,
    required this.senderUid,
    required this.receiverUid,
    required this.type,
    this.message,
    required this.timestamp,
    required this.read,
    this.photoUrl,
  });

  Message.withoutMessage({
    required this.receiverName,
    required this.senderName,
    required this.senderUid,
    required this.receiverUid,
    required this.type,
    required this.timestamp,
    required this.read,
    this.photoUrl,
  });

  // Message 객체를 Map 형식으로 변환
  Map<String, dynamic> toMap() {
    return {
      'receiverName' : receiverName,
      'senderName' : senderName,
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'type': type,
      'message': message,
      'timestamp': timestamp,
      'photoUrl': photoUrl,
      'read': read,
    };
  }

  // Map을 Message 객체로 변환하는 factory 생성자
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      receiverName : map['receiverName'] ?? '',
      senderName : map['senderName'] ?? '',
      senderUid: map['senderUid'] ?? '',
      receiverUid: map['receiverUid'] ?? '',
      type: map['type'] ?? '',
      message: map['message'],
      timestamp: map['timestamp'],
      photoUrl: map['photoUrl'],
      read: map['read'] ?? false, // 기본값을 false로 설정
    );
  }
}
