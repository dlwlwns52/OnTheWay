// 이 코드는 채팅 애플리케이션에서 사용되는 메시지 데이터를 나타내는 Dart 클래스인 'Message' 클래스를 정의합니다.
// 'Message' 클래스는 사용자 간의 채팅 메시지나 이미지 메시지와 같은 채팅 관련 데이터를 다루기 위해 사용됩니다.

import 'package:cloud_firestore/cloud_firestore.dart';

// Message 클래스: 메시지 관련 데이터를 저장하고 처리
class Message {
  // 멤버 변수들: 사용자의 UID, 메시지 타입, 내용, 타임스탬프, 이미지 URL
  String senderUid;
  String receiverUid;
  String type;
  String? message; // 메시지는 null일 수 있음 (이미지 메시지일 경우)
  FieldValue timestamp;
  String? photoUrl; // 이미지 URL도 null일 수 있음 (텍스트 메시지일 경우)

  // 생성자: 필수적인 속성들을 받아서 Message 객체를 생성
  // null safety를 위해 필수 필드에 required 키워드 추가, 선택적 필드는 nullable로 변경
  Message({
    required this.senderUid,
    required this.receiverUid,
    required this.type,
    this.message,
    required this.timestamp,
    this.photoUrl,
  });

  // Message 객체를 Map 형식으로 변환
  // Map<String, dynamic> 사용하여 여러 타입의 데이터를 다룰 수 있도록 함
  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'type': type,
      'message': message,
      'timestamp': timestamp,
      'photoUrl': photoUrl,
    };
  }

  // Map을 Message 객체로 변환하는 factory 생성자
  // factory 키워드를 사용하여 Map에서 직접 객체를 생성
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      senderUid: map['senderUid'] ?? '', // null 체크
      receiverUid: map['receiverUid'] ?? '',
      type: map['type'] ?? '',
      message: map['message'],
      timestamp: map['timestamp'] as FieldValue, // 캐스팅 필요
      photoUrl: map['photoUrl'],
    );
  }
}


//
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class Message {
//
//   String senderUid;
//   String receiverUid;
//   String type;
//   String message;
//   FieldValue timestamp;
//   String photoUrl;
//
//   Message({this.senderUid, this.receiverUid, this.type, this.message, this.timestamp});
//   Message.withoutMessage({this.senderUid, this.receiverUid, this.type, this.timestamp, this.photoUrl});
//
//   Map toMap() {
//     var map = Map<String, dynamic>();
//     map['senderUid'] = this.senderUid;
//     map['receiverUid'] = this.receiverUid;
//     map['type'] = this.type;
//     map['message'] = this.message;
//     map['timestamp'] = this.timestamp;
//     return map;
//   }
//
//   Message fromMap(Map<String, dynamic> map) {
//     Message _message = Message();
//     _message.senderUid = map['senderUid'];
//     _message.receiverUid = map['receiverUid'];
//     _message.type = map['type'];
//     _message.message = map['message'];
//     _message.timestamp = map['timestamp'];
//     return _message;
//   }
//
//
//
// }