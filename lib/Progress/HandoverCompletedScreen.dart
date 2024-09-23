import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class HandoverCompletedScreen extends StatefulWidget {
  @override
  _HandoverCompletedScreenState createState() => _HandoverCompletedScreenState();
}

class _HandoverCompletedScreenState extends State<HandoverCompletedScreen> {
  String currentEmail = '';

  @override
  void initState() {
    super.initState();
    // 현재 로그인한 사용자의 이메일을 FirebaseAuth에서 가져오기
    currentEmail = FirebaseAuth.instance.currentUser?.email ?? '';
  }


  //삭제되면 delete 업로드
  Future<List<Map<String, dynamic>>> _fetchCompletedDeliveries() async {
    try {
      // Firestore에서 completedReceipts 컬렉션에서 ownerEmail이 현재 이메일과 일치하는 문서들을 가져옴
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('completedDeliveries')
          .where('helperEmail', isEqualTo: currentEmail)
          .get();

      // delete 필드가 true가 아닌 문서만 호출 (delete 필드가 없을 경우 false로 간주)
      return snapshot.docs
          .where((doc) {
        final data = doc.data() as Map<String, dynamic>?; // data를 Map으로 캐스팅
        return data != null &&
            (data.containsKey('delete') ? data['delete'] != true : true);
      })
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching completed receipts: $e');
      return []; // 오류 발생 시 빈 리스트 반환
    }
  }


  //수령 내역 삭제
  Future<void> _deleteDeliveries(String docName) async {
    try {
      await FirebaseFirestore.instance
          .collection('completedDeliveries')
          .doc(docName)
          .update({'delete': true});
    } catch (e) {
      print('Error updating delete field: $e');
    }
  }


  // 요청 or 결제 -> request true일 경우 요청 false일 경우 결제
  Future<void> showDeleteConfirmationDialog(BuildContext context,
      String docName) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Container(

          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery
                    .of(context)
                    .size
                    .height * 0.07),
                Text(
                  '선택한 전달완료 내역을 삭제하시겠습니까? \n삭제 후에는 복구할 수 없습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    height: 1.3,
                    letterSpacing: -0.1,
                    color: Color(0xFF222222),
                  ),
                ),

                SizedBox(height: MediaQuery
                    .of(context)
                    .size
                    .height * 0.055),
                Divider(color: Colors.grey, height: 1),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                        ),
                        child: Center(
                          child: Text(
                            '취소',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF636666),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 0.5, // 구분선의 두께
                      height: 55, // 구분선의 높이
                      color: Colors.grey, // 구분선의 색상
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await _deleteDeliveries(docName);
                          Navigator.of(context).pop();
                          setState(() {

                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                        ),
                        child: Center(
                          child: Text(
                            '확인',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1D4786),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  //게시글 내용
  Widget _buildPostCard({
    required String docName,
    required String timeAgo,
    required String storeName,
    required String location,
    required String cost,
    required String owner_email_nickname,
    required String ownerPhotoUrl,

  }) {
    return Container(
        margin: EdgeInsets.fromLTRB(
            0,
            0,
            0,
            MediaQuery.of(context).size.height * 0.02),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFFD0D0D0)),
          borderRadius: BorderRadius.circular(12),
          color: Color(0xFFFFFFFF),
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(15, 10, 15, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 5, 0, 10),
                    child: Text(
                      timeAgo,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height: 1,
                        letterSpacing: -0.5,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      showDeleteConfirmationDialog(context, docName);
                    },
                    child: Icon(
                      Icons.delete,
                      size: 20,
                      color: Color(0xFFAAAAAA),// 아이콘 크기 조정
                    ),
                  ),
                ],
              ),


              Container(
                margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                width: double.infinity,
                height: 1,
                color: Color(0xFFF6F6F6),
              ),
              _buildInfoRow(
                iconPath: 'assets/pigma/vuesaxbulkhouse.svg',
                label: '픽업 장소',
                value: storeName,
              ),
              _buildInfoRow(
                iconPath: 'assets/pigma/location.svg',
                label: '드랍 장소',
                value: location,
              ),
              _buildInfoRow(
                iconPath: 'assets/pigma/dollar_circle.svg',
                label: '헬퍼비',
                value: cost,
              ),
              //헬퍼는 프로필 사진도 넣야해서 따로
              Container(
                margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(0, 0, 7, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF1D4786), Color(0xFF1D4786)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                (ownerPhotoUrl != null &&
                                    ownerPhotoUrl.isNotEmpty)
                                    ? BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 1,
                                  offset: Offset(0, 1), // 그림자 위치 조정
                                )
                                    : BoxShadow(),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 12, // 반지름 설정 (32 / 2)
                              backgroundColor: Colors.grey[200],
                              child: (ownerPhotoUrl != null &&
                                  ownerPhotoUrl.isNotEmpty)
                                  ? null
                                  : Icon(
                                Icons.account_circle,
                                size: 24,
                                // 원래 코드에서 width와 height가 32였으므로 여기에 맞춤
                                color: Color(0xFF1D4786),
                              ),
                              backgroundImage: ownerPhotoUrl != null &&
                                  ownerPhotoUrl.isNotEmpty
                                  ? NetworkImage(ownerPhotoUrl)
                                  : null,
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                          child: Text(
                            '오더',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              height: 1,
                              letterSpacing: -0.4,
                              color: Color(0xFF767676),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                      child: Text(
                        '${owner_email_nickname}',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1,
                          letterSpacing: -0.1,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                width: double.infinity,
                height: 1,
                color: Color(0xFFF6F6F6),
              ),
            ],
          ),
        ),
      );
  }

  //게시글 구조
  Widget _buildInfoRow({
    required String iconPath,
    required String label,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(0, 0, 6, 0),
                width: 24,
                height: 24,
                child: SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    height: 1,
                    letterSpacing: -0.4,
                    color: Color(0xFF767676),
                  ),
                ),
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.fromLTRB(0, 5, 0, 5),
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1,
                letterSpacing: -0.1,
                color: Color(0xFF222222),
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchCompletedDeliveries(), // 데이터를 불러오는 Future
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // 로딩 중
          } else if (snapshot.hasError) {
            return Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다.'));
          }

          // 아직 사용하지 않음 : 데이터 0건
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: RichText(
                    text: TextSpan(
                      text: '총 ',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        height: 1,
                        letterSpacing: -0.5,
                        color: Color(0xFF222222),
                      ),
                      children: [
                        TextSpan(
                          text: '0건',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            height: 1.3,
                            letterSpacing: -0.5,
                            color: Color(0xFF1D4786),
                          ),
                        ),
                        TextSpan(
                          text: '의 전달 완료건이 있어요!',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            height: 1,
                            letterSpacing: -0.5,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.22),
                    child:
                    Text(
                      '전달 완료된 데이터가 아직 없습니다. \n거래를 진행해 주세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'NanumSquareRound',
                        color: Color(0xFF1D4786),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // 전달완료 내역
          else {
            List<Map<String, dynamic>> deliveries = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: RichText(
                    text: TextSpan(
                      text: '총 ',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        height: 1,
                        letterSpacing: -0.5,
                        color: Color(0xFF222222),
                      ),
                      children: [
                        TextSpan(
                          text: '${deliveries.length}건',
                          // deliveries.length를 이용해 건수 표시
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            height: 1.3,
                            letterSpacing: -0.5,
                            color: Color(0xFF1D4786),
                          ),
                        ),
                        TextSpan(
                          text: '의 전달 완료건이 있어요!',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            height: 1,
                            letterSpacing: -0.5,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.builder(
                      itemCount: deliveries.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> deliverie = deliveries[index];
                        return _buildPostCard(
                          docName: deliverie['docName'],
                          timeAgo: DateFormat('yyyy-MM-dd HH:mm').format(deliverie['timeAgo'].toDate()),
                          storeName: deliverie['storeName'] ?? '가게 이름 없음',
                          location: deliverie['location'] ?? '위치 정보 없음',
                          cost: deliverie['cost'] ?? '비용 정보 없음',
                          owner_email_nickname: deliverie['ownerNickname'] ??
                              '사용자 이름 없음',
                          ownerPhotoUrl: deliverie['ownerPhotoUrl'] ??
                              '사용자 사진 없음',
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}