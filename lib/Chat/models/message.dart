// 이 코드는 채팅 애플리케이션에서 사용되는 메시지 데이터를 나타내는 Dart 클래스인 'Message' 클래스를 정의합니다.
// 'Message' 클래스는 사용자 간의 채팅 메시지나 이미지 메시지와 같은 채팅 관련 데이터를 다루기 위해 사용됩니다.


import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  String senderUid;       // 메시지를 보낸 사용자의 UID
  String receiverUid;     // 메시지를 받는 사용자의 UID
  String type;            // 메시지의 타입 (텍스트 메시지 또는 이미지 메시지)
  String message;         // 텍스트 메시지의 내용 (type이 'text'인 경우에만 사용)
  FieldValue timestamp;   // 메시지의 타임스탬프
  String photoUrl;        // 이미지 메시지의 이미지 URL (type이 'image'인 경우에만 사용)

  // 생성자: 필수적인 속성들을 받아서 Message 객체를 생성합니다.
  Message({
    this.senderUid,
    this.receiverUid,
    this.type,
    this.message,
    this.timestamp,
  });

  // 이미지 메시지를 위한 생성자: 필수적인 속성들과 이미지 URL을 받아서 Message 객체를 생성합니다.
  Message.withoutMessage({
    this.senderUid,
    this.receiverUid,
    this.type,
    this.timestamp,
    this.photoUrl,
  });

  // Message 객체를 Map 형태로 변환합니다.
  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();
    map['senderUid'] = this.senderUid;
    map['receiverUid'] = this.receiverUid;
    map['type'] = this.type;
    map['message'] = this.message;
    map['timestamp'] = this.timestamp;
    return map;
  }

  // Map을 Message 객체로 변환합니다.
  Message fromMap(Map<String, dynamic> map) {
    Message _message = Message();
    _message.senderUid = map['senderUid'];
    _message.receiverUid = map['receiverUid'];
    _message.type = map['type'];
    _message.message = map['message'];
    _message.timestamp = map['timestamp'];
    return _message;
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