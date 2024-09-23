import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class DeleteMember {
  final String userEmail;
  final String userNickname;
  final String collection_domain;
  DeleteMember(this.userEmail, this.userNickname, this.collection_domain);


  Future<void> deleteUserData() async {
    // 각 컬렉션에서 데이터 삭제
    await _deleteCollectionData('ChatActions');
    await _deleteCollectionData('Payments');
    await _deleteCollectionData('helpActions');
    await _deleteCollectionData(collection_domain);
    await _deleteCollectionData('schoolScores');
    await _deleteCollectionData('userStatus');
    await _deleteCollectionData('users');
  }

  Future<void> _deleteCollectionData(String collectionName) async {
    try {
      // 필드 값이 이메일과 닉네임과 일치하는 문서 삭제
      await _deleteDocumentsByFieldValue(collectionName, userEmail);
      await _deleteDocumentsByFieldValue(collectionName, userNickname);


      // 유저 닉네임이 필드값인 경우 삭제
      if (collectionName == 'schoolScores') {
        await _deleteDocumentsByFieldKey(collectionName, userNickname);
      }

    } catch (e) {
      print('Error deleting data from $collectionName: $e');
    }
  }

  Future<void> _deleteDocumentsByFieldValue(String collectionName, String value) async {
    List<QuerySnapshot> querySnapshots = [];

    // 여러 필드 값으로 문서 삭제
    if (collectionName == 'ChatActions' || collectionName == 'Payments' || collectionName == 'helpActions') {
      querySnapshots.add(await FirebaseFirestore.instance.collection(collectionName).where('owner_email', isEqualTo: value).get());
      querySnapshots.add(await FirebaseFirestore.instance.collection(collectionName).where('helper_email', isEqualTo: value).get());

    } else if (collectionName == collection_domain) {
      querySnapshots.add(await FirebaseFirestore.instance.collection(collectionName).where('email', isEqualTo: value).get());
    }

    else if (collectionName == 'users' || collectionName == 'userStatus') {
      await FirebaseFirestore.instance.collection(collectionName).doc(value).delete();

    }


    Set<String> deletedDocIds = {};
    for (var querySnapshot in querySnapshots) {
      for (var doc in querySnapshot.docs) {
        if (!deletedDocIds.contains(doc.id)) {
          //서브컬렉션 삭제
          if (collectionName == 'ChatActions') {
            await _deleteSubCollection(doc.reference);
          }

          await FirebaseFirestore.instance.collection(collectionName).doc(doc.id).delete();
          deletedDocIds.add(doc.id);
        }
      }
    }
  }

  Future<void> _deleteDocumentsByFieldKey(String collectionName, String keyToMatch) async {
    // 해당 컬렉션의 모든 문서를 가져옴
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection(collectionName).get();
    // 각 문서의 모든 필드 이름을 검사
    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      if (data.containsKey(keyToMatch)) {
        // 필드 이름이 keyToMatch와 일치하는 경우 해당 필드를 삭제
        print(keyToMatch);
        await FirebaseFirestore.instance.collection(collectionName).doc(doc.id).update({
          keyToMatch: FieldValue.delete()
        });
        print('Deleted field $keyToMatch from document with ID: ${doc.id} in collection: $collectionName');
      }
    }
  }

  // ChatActions 서브컬렉션의 모든 문서를 삭제하는 메서드
  Future<void> _deleteSubCollection(DocumentReference parentDocRef) async {
    // 서브컬렉션 참조
    CollectionReference subcollectionRef = parentDocRef.collection('messages');

    // 서브컬렉션의 모든 문서 가져오기
    QuerySnapshot subcollectionSnapshot = await subcollectionRef.get();

    // 각 문서 삭제
    for (var doc in subcollectionSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> deleteUserAccount() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      print('Error deleting user account: $e');
    }
  }

  Future<void> deleteMember() async {
    // Firestore 데이터 삭제
    await deleteUserData();

    // Firebase Authentication 계정 삭제
    await deleteUserAccount();
  }
}
