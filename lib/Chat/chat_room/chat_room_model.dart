import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatRoomModel{


  //userStatus에서 본인 nickname 찾기
  Future<String?> getNickname(String botton_email) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: botton_email)
        .get();

    if (querySnapshot.docs.isNotEmpty){
      return querySnapshot.docs.first['nickname'];
    }
    return null;
  }


  //future builder에서 사용 -> 매개변수 받음
  Future<String?> getNickname2(String email) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isNotEmpty){
      return querySnapshot.docs.first['nickname'];
    }
    return null;
  }

  //마지막 메시지 보낸 시간 확인
  Future<DateTime?> fetchLastMessage(String documentName) async {
    try {
      // 채팅방의 마지막 메시지를 검색하기 위한 쿼리
      QuerySnapshot<Map<String, dynamic>> lastMessageSnapshot = await FirebaseFirestore.instance
          .collection('ChatActions')
          .doc(documentName)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      // 검색된 문서가 있는지 확인하고, 있다면 마지막 메시지의 타임스탬프를 가져옴
      if (lastMessageSnapshot.docs.isNotEmpty) {
        Timestamp lastMessageTimestamp = lastMessageSnapshot.docs.first.data()['timestamp'];
        return lastMessageTimestamp.toDate();
      }
    }
    catch (error) {
      // 에러 처리 로직
      // 예: print("Error fetching last message: $error");
    }
  }


  //userStatus messageCount 값 초기화
  Future<void> resetMessageCount(String nickname) async {
    DocumentReference docRef = FirebaseFirestore.instance.collection('userStatus').doc(nickname);
    await docRef.set({'messageCount': 0}, SetOptions(merge: true));
  }

  // Firestore에서 messageCount 값을 실시간으로 가져오는 메서드
  Stream<DocumentSnapshot> getMessageCountStream(String nickname) {
    return FirebaseFirestore.instance
        .collection('userStatus')
        .doc(nickname)
        .snapshots();
  }


  //------------------------
  //나가기를 눌렀을 때 각 닉네임을 가진 사람의 상태 정보 삭제
  Future<void> deleteUserStatusChatRoom(String documentId, String nickname) async {
    await FirebaseFirestore.instance
        .collection('userStatus')
        .doc(nickname)
        .collection('chatRooms')
        .doc(documentId)
        .delete();
  }


  Future<void> updateDeleteStatus(String documentId, String userNickname) async {
    await FirebaseFirestore.instance.collection('ChatActions').doc(documentId).update({
      'isDeleted_$userNickname': true,
    });
  }



// 서브컬렉션의 모든 문서를 삭제하는 메서드
  Future<void> deleteSubCollection(DocumentReference parentDocRef) async {
    // 서브컬렉션 참조
    CollectionReference subcollectionRef = parentDocRef.collection('messages');

    // 서브컬렉션의 모든 문서 가져오기
    QuerySnapshot subcollectionSnapshot = await subcollectionRef.get();

    // 각 문서 삭제
    for (var doc in subcollectionSnapshot.docs) {
      await doc.reference.delete();
    }
  }


}