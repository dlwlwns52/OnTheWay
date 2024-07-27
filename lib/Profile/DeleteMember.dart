import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeleteMember {
  final String userEmail;
  final String userNickname;

  DeleteMember(this.userEmail, this.userNickname);

  Future<void> deleteUserData() async {
    // 각 컬렉션에서 데이터 삭제
    await _deleteCollectionData('ChatActions');
    await _deleteCollectionData('Payments');
    await _deleteCollectionData('helpActions');
    await _deleteCollectionData('naverUserHelpStatus');
    await _deleteCollectionData('naver_posts');
    await _deleteCollectionData('schoolScores');
    await _deleteCollectionData('userStatus');
    await _deleteCollectionData('users');
  }

  Future<void> _deleteCollectionData(String collectionName) async {
    try {
      // 이메일로 데이터 삭제
      var emailDocs = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('email', isEqualTo: userEmail)
          .get();

      for (var doc in emailDocs.docs) {
        await FirebaseFirestore.instance.collection(collectionName).doc(doc.id).delete();
        print("${collectionName} + ${doc.id} + ${userEmail} 삭제완료");
      }


      // 닉네임으로 데이터 삭제
      var nicknameDocs = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('nickname', isEqualTo: userNickname)
          .get();

      for (var doc in nicknameDocs.docs) {
        await FirebaseFirestore.instance.collection(collectionName).doc(doc.id).delete();
        print("${collectionName} + ${doc.id} + ${userNickname} 삭제완료");
      }
    } catch (e) {
      print('Error deleting data from $collectionName: $e');
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
