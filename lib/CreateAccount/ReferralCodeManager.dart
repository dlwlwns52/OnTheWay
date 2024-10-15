import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralCodeManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 추천 코드를 생성하는 함수
  String _generateReferralCode(int length) {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }


  // 추천 코드가 중복되지 않도록 Firestore에서 확인하는 함수
  Future<String> generateUniqueReferralCode() async {
    String referralCode;
    bool isUnique = false;

    // 중복되지 않는 코드가 생성될 때까지 반복
    do {
      referralCode = _generateReferralCode(6);  // 6자리 추천 코드 생성
      final querySnapshot = await _firestore
          .collection('users')
          .where('referralCode', isEqualTo: referralCode)
          .get();

      // Firestore에서 같은 추천 코드가 없으면 중복되지 않은 것으로 간주
      if (querySnapshot.docs.isEmpty) {
        isUnique = true;
      }
    } while (!isUnique);

    return referralCode;
  }

  // 추천 코드를 Firestore에 저장하는 함수
  Future<void> saveReferralCodeToUser(String userId, String referralCode) async {
    await _firestore.collection('users').doc(userId).set({
      'referralCode': referralCode,
    }, SetOptions(merge: true));
  }


}
