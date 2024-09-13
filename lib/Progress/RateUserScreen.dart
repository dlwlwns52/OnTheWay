import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../Chat/AllUsersScreen.dart';

class RateUserScreen extends StatefulWidget {
  final String docName;
  final String ownerEmail;
  final String helperEmail;
  final String helperNickname;
  final String ownerNickname;
  final String storeName;
  final String location;
  final String cost;
  final String ownerPhotoUrl;
  final String helperPhotoUrl;


  RateUserScreen(this.docName, this.ownerEmail, this.helperEmail
      , this.helperNickname, this.ownerNickname, this.storeName, this.location, this.cost, this.ownerPhotoUrl, this.helperPhotoUrl);


  @override
  _RateUserScreenState createState() => _RateUserScreenState();
}

class _RateUserScreenState extends State<RateUserScreen> {

  double grade = 0.0;
  double _currentRating = 0.0; // 초기 평점 값 (0을 기준으로 -0.2 ~ +0.2 범위)
  String _currentGrade = 'C+'; // 초기 학점 (C+로 기본 설정)


  @override
  void initState() {
    super.initState();
  }


  Future<void> deletePaymentDocument(String documentId) async {
    try {
      await FirebaseFirestore.instance.collection('Payments').doc(documentId).delete();
      print('Document successfully deleted');
    } catch (e) {
      print('Error deleting document: $e');
    }
  }

  Future<void> helperGrade(double rateGrade) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.helperEmail)
        .get();

    // 문서가 존재하는지 확인하고 grade 필드를 가져옴
    if (snapshot.docs.isNotEmpty) {
      // 첫 번째 문서의 데이터를 가져옴 (필요시 여러 문서 처리 가능)
      DocumentSnapshot document = snapshot.docs.first;

      // grade 필드값 가져오기
      double currentGrade = document['grade'];
      double updatedGrade = _limitToTwoDecimals(currentGrade + rateGrade);

      // updatedGrade가 4.5를 초과하지 않도록 제한
      updatedGrade = updatedGrade > 4.5 ? 4.5 : updatedGrade; // 최대값 4.5로 제한

      // grade 값 업데이트
      await FirebaseFirestore.instance
          .collection('users')
          .doc(document.id) // 문서 ID를 사용하여 해당 문서를 업데이트
          .update({
        'grade': updatedGrade,
      });

      print('Updated grade: $updatedGrade');
    } else {
      print('해당 이메일을 가진 유저를 찾을 수 없습니다.');
    }
  }


// 학점을 결정하는 함수
  String _getGrade(double value) {
    if ((value - (-0.1)).abs() < 0.01) {
      return 'F';
    } else if ((value - (-0.05)).abs() < 0.01) {
      return 'D+';
    } else if (value.abs() < 0.01) {
      return 'C+';
    } else if ((value - 0.05).abs() < 0.01) {
      return 'B+';
    } else if ((value - 0.1).abs() < 0.01) {
      return 'A+';
    }
    return 'C+'; // 기본값
  }

// 점수에 따라 다른 기능을 실행하는 함수
  void _handleRating(double value) {
    setState(() {
      _currentGrade = _getGrade(value); // 학점 업데이트
    });

    if ((value - (-0.1)).abs() < 0.01) {
      HapticFeedback.lightImpact(); // 가벼운 햅틱
    } else if ((value - (-0.05)).abs() < 0.01) {
      HapticFeedback.lightImpact(); // 가벼운 햅틱
    } else if (value.abs() < 0.01) {
      HapticFeedback.lightImpact(); // 가벼운 햅틱
    } else if ((value - 0.05).abs() < 0.01) {
      HapticFeedback.lightImpact(); // 가벼운 햅틱
    } else if ((value - 0.1).abs() < 0.01) {
      HapticFeedback.lightImpact(); // 가벼운 햅틱
    }
  }

  double _limitToTwoDecimals(double value) {
    return double.parse(value.toStringAsFixed(2)); // 소수점 두 자리까지만 남김
  }

  // 수령완료 컬렉션과 전달완료 컬렉션에 데이터를 저장하는 함수
  Future<void> saveToFirestore() async {
    // 수령완료 컬렉션에 저장할 데이터
    Map<String, dynamic> receiptData = {
      'docName': widget.docName,
      'ownerEmail' : widget.ownerEmail,
      'helperEmail': widget.helperEmail,
      'helperNickname': widget.helperNickname,
      'ownerNickname': widget.ownerNickname,
      'storeName': widget.storeName,
      'location': widget.location,
      'cost': widget.cost,
      'ownerPhotoUrl' : widget.ownerPhotoUrl,
      'helperPhotoUrl' : widget.helperPhotoUrl,
      'timeAgo': Timestamp.now(), // 현재 시각
    };

    // 전달완료 컬렉션에 저장할 데이터
    Map<String, dynamic> deliveryData = {
      'docName': widget.docName,
      'ownerEmail' : widget.ownerEmail,
      'helperEmail': widget.helperEmail,
      'helperNickname': widget.helperNickname,
      'ownerNickname': widget.ownerNickname,
      'storeName': widget.storeName,
      'location': widget.location,
      'cost': widget.cost,
      'ownerPhotoUrl' : widget.ownerPhotoUrl,
      'helperPhotoUrl' : widget.helperPhotoUrl,
      'timeAgo': Timestamp.now(), // 현재 시각
    };

    try {
      // Firestore에 데이터 저장
      await FirebaseFirestore.instance.collection('completedReceipts').doc(widget.docName).set(receiptData);
      await FirebaseFirestore.instance.collection('completedDeliveries').doc(widget.docName).set(deliveryData);

      print('Data saved to Firestore successfully.');
    } catch (e) {
      print('Error saving data to Firestore: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
        child: AppBar(
          title: Text(
            '평가',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 19,
              height: 1.0,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),

          centerTitle: true,
          backgroundColor: Color(0xFF1D4786),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_outlined), // '<' 모양의 뒤로가기 버튼 아이콘
            color: Colors.white, // 아이콘 색상
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context); // 뒤로가기 기능
            },
          ),
          // 상단 왼쪽 빈 공간을 만들기 위해 빈 SizedBox를 사용
          actions: [

          ],
        ),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(
                  0,
                  MediaQuery.of(context).size.height * 0.15,
                  0,
                  0),
              width: MediaQuery.of(context).size.width * 0.45, // 원하는 터치 영역의 너비
              height: MediaQuery.of(context).size.height * 0.3, // 원하는 터치 영역의 높이
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.contain,
                    image: AssetImage(
                      'assets/images/RateStar.png',
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 16),
              child: Text(
                '서비스가 어떠셨나요? \n ',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  height: 1,
                  letterSpacing: -0.5,
                  color: Color(0xFF1D4786),
                ),
              ),
            ),
            // 레이블을 나타내는 텍스트 위젯들
            Column(
              children: [
                Slider(
                  value: _currentRating,
                  min: -0.1,
                  max: 0.1,
                  divisions: 4, // 5개의 구역 (-0.2, -0.1, 0, 0.1, 0.2)
                  onChanged: (double value) {
                    setState(() {
                      _currentRating = value; // 슬라이더 값 업데이트
                      _handleRating(value); // 점수 변경에 따른 햅틱 및 학점 설정;
                    });
                  },
                  activeColor: Color(0xFF1D4786),
                  inactiveColor: Colors.grey[300],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '점수 :  ', // 실시간 학점 표시
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Column(
                      children: [
                        Text(
                          '$_currentGrade', // 실시간 학점 표시
                          style: TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D4786),
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.012)
                      ],
                    )
                  ],
                )
              ],
            ),
          ],
        ),
      ),

      bottomNavigationBar:
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            Container(
              height: Platform.isAndroid ? MediaQuery.of(context).size.width * 0.15 : MediaQuery.of(context).size.width * 0.20,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  helperGrade(_currentRating);
                  deletePaymentDocument(widget.docName);
                  saveToFirestore(); // 수령완료, 전달완료 컬렉션 저장
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AllUsersScreen()),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('평가가 완료되었습니다. \n채팅 목록에서 헬퍼의 계좌로 결제를 진행해주세요.'
                      ,textAlign: TextAlign.center,),
                      duration: Duration(seconds: 3), // 스낵바가 표시되는 시간
                    ),
                  );

                },
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFF1D4786), // 배경색
                  onPrimary: Colors.white, // 텍스트 색상
                  padding: EdgeInsets.symmetric(vertical: 13), // 내부 패딩 (높이 조정)
                  minimumSize: Size(double.infinity, kBottomNavigationBarHeight), // 버튼 크기 설정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // 둥근 모서리를 제거하고 직사각형 모양으로 설정
                    side: BorderSide(color: Color(0xFF1D4786)), // 테두리 색상 설정
                  ),
                ),
                child: Text(
                  '평가완료',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    height: 1,
                    letterSpacing: -0.5,
                    color: Colors.white, // 텍스트 색상
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

