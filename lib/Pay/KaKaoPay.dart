import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iamport_flutter/iamport_payment.dart';
import 'package:iamport_flutter/model/payment_data.dart'; // PaymentData 클래스

class KaKaoPay extends StatelessWidget {
  final String buyerId = '카카오페이1'; // 구매자 ID
  final String sellerId = '카카오페이2'; // 판매자 ID
  final int amount = 100; // 결제 금액

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('결제하기'), // 앱바 타이틀 설정
      ),
      body: IamportPayment(
        // 결제 모듈 설정
        initialChild: Container(
          // 초기 로딩 화면 설정
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(0.0, 30.0, 0.0, 0.0),
                  child: Text('잠시만 기다려주세요...', style: TextStyle(fontSize: 20.0)), // 로딩 메시지
                ),
              ],
            ),
          ),
        ),
        userCode: 'imp83221800', // 아임포트 가맹점 식별코드
        data: PaymentData(
          pg: 'kakaopay', // 결제 PG사 설정
          payMethod: 'card', // 결제 방법 설정
          name: '온더웨이', // 결제 상품 이름
          merchantUid: 'mid_${DateTime.now().millisecondsSinceEpoch}', // 주문 번호
          amount: amount, // 결제 금액 설정
          buyerName: '학생1', // 구매자 이름
          buyerTel: '01011112222', // 구매자 전화번호
          buyerEmail: 'student1@example.com', // 구매자 이메일
          appScheme: 'example', // 앱 스킴 설정
        ),
        callback: (Map<String, String> result) {
          Navigator.pushReplacementNamed(
            context,
            '/payment-result', // 결제 결과 화면으로 이동
            arguments: result, // 결제 결과 전달
          );
        },
      ),
    );
  }

  // 결제 성공 처리 함수
  Future<void> _handlePaymentSuccess(Map<String, String> response, String buyerId, String sellerId, int amount) async {
    final transactionId = 'unique_transaction_id'; // 고유 거래 ID 설정
    final transactionRef = FirebaseFirestore.instance.collection('transactions').doc(transactionId);
    await transactionRef.set({
      'transactionId': transactionId, // 거래 ID 저장
      'buyerId': buyerId, // 구매자 ID 저장
      'sellerId': sellerId, // 판매자 ID 저장
      'amount': amount, // 결제 금액 저장
      'status': 'completed', // 거래 상태 저장
    });

    final int fee = (amount * 0.08).toInt(); // 수수료 계산
    final int sellerAmount = amount - fee; // 판매자 수령 금액 계산

    print('결제 성공: 구매자 $buyerId -> 판매자 $sellerId'); // 로그 출력
    print('결제 금액: $amount 원, 수수료: $fee 원, 판매자 수령액: $sellerAmount 원'); // 로그 출력

    await transferToSeller(sellerId, sellerAmount); // 판매자에게 송금
    await transferToMyAccount(fee); // 수수료 송금
  }

  // 판매자에게 송금 함수
  Future<void> transferToSeller(String sellerId, int amount) async {
    final sellerRef = FirebaseFirestore.instance.collection('users').doc(sellerId);
    final sellerData = await sellerRef.get();
    final sellerKakaoPayId = sellerData['kakaoPayId']; // 판매자의 카카오페이 ID 조회

    print('판매자에게 송금: $sellerKakaoPayId, 금액: $amount 원'); // 로그 출력
  }

  // 수수료 송금 함수
  Future<void> transferToMyAccount(int amount) async {
    const myKakaoPayId = 'myKakaoPayId'; // 내 카카오페이 ID 설정
    print('내 계좌로 수수료 입금: $myKakaoPayId, 금액: $amount 원'); // 로그 출력
  }
}
