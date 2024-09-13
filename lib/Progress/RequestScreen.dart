import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class RequestScreen extends StatefulWidget {
  @override
  _RequestScreenState createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  // Firestore 인스턴스를 생성하여 데이터베이스에 접근할 수락 있게 합니다.
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  // 초기 게시글 개수
  int postCount = 0;
  String email = ""; // 사용자의 이메일을 저장할 변수


  @override
  void initState() {
    super.initState();
    final FirebaseAuth _auth = FirebaseAuth.instance;
    email = _auth.currentUser?.email ?? "";
  }



  // Firestore의 'naver_posts' 컬렉션에서 내 문서들 추출
  Stream<List<DocumentSnapshot>> getPosts() {
    return firestore.collection('naver_posts')
        .where('email', isEqualTo: email)
        .snapshots().map((snapshot) {
      return snapshot.docs.toList(); // 스냅샷의 문서들을 리스트로 변환하여 반환합니다.
    });
  }

  // 현재 로그인한 사용자의 이메일을 반환하는 메서드
  String? currentUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email;
  }

  //현재 시간
  String formatTimeAgo(Timestamp timestamp) {
    // Timestamp를 DateTime으로 변환
    DateTime dateTime = timestamp.toDate();
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inMinutes <= 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      // 날짜를 '2024.10.12 17:30' 형식으로 변환
      DateFormat dateFormat = DateFormat('yyyy.MM.dd HH:mm');
      return dateFormat.format(dateTime);  // 형식화된 날짜 반환
    }
  }


  //게시글 내용
  Widget _buildPostCard({
    required String userName,
    required String timeAgo,
    required String location,
    required String cost,
    required String storeName,
    required bool isMyPost,
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
        padding: EdgeInsets.fromLTRB(15, 15, 15, 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    child: Text(
                      timeAgo,
                      style: TextStyle(
                        fontFamily: 'Pretendard', // Pretendard 폰트 지정
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        height: 1,
                        letterSpacing: -0.5,
                        color: Color(0xFFAAAAAA),
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
              label: '비용',
              value: cost,
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
              style:TextStyle(
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
      body:  Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 10), // AppBar와 Row 사이에 10픽셀의 높이를 가진 공간을 추가합니다.
              Container(
                margin: EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('naver_posts')
                          .where('email', isEqualTo: email)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}");
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }

                        postCount = snapshot.data?.size ?? 0;
                        return RichText(
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
                                text: '$postCount건',
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
                                text: '의 요청건이 있어요!',
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
                        );
                      }
                  ),
                ),
              ),
              Flexible(
                child: StreamBuilder<List<DocumentSnapshot>>(
                  stream: getPosts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('오류가 발생했습니다.'));
                    } else if (snapshot.hasData) {
                      final posts = snapshot.data!;

                      if (posts.isEmpty) {
                        return Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 300,
                            height: 200,
                            child: Text(
                              '현재 요청한 게시글이 없습니다. \n새로운 게시글을 작성하시면\n이곳에서 확인하실 수 있습니다.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                  fontFamily: 'Pretendard',
                                color: Color(0xFF1D4786),
                              ),
                            ),
                          ),
                        );
                      }
                      final myEmail = currentUserEmail();

                      posts.sort((a, b) {
                        Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
                        Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
                        bool isMyPostA = dataA['email'] == myEmail;
                        bool isMyPostB = dataB['email'] == myEmail;
                        if (isMyPostA && !isMyPostB) return -1;
                        if (!isMyPostA && isMyPostB) return 1;
                        // 이메일이 같을 경우 시간을 기준으로 정렬
                        Timestamp timeA = dataA['date'];
                        Timestamp timeB = dataB['date'];

                        return timeB.compareTo(timeA); // 최신 순으로 정렬
                      });



                      return ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot doc = posts[index];
                          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                          if (data == null) {
                            return SizedBox(); // 데이터가 없을 경우 빈 공간 반환
                          }
                          bool isMyPost = data['email'] == myEmail;

                          return Column(
                            children: <Widget>[
                              Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                  child: _buildPostCard(
                                        userName: data['nickname'] ?? '사용자 이름 없음',

                                        timeAgo:  DateFormat('yyyy-MM-dd HH:mm').format(data['date'].toDate()),
                                        location: data['my_location'] ?? '위치 정보 없음',
                                        cost: data['cost'] ?? '비용 정보 없음',
                                        storeName: data['store'] ?? '가게 이름 없음',
                                        isMyPost: isMyPost,
                                      ),

                              ),
                            ],
                          );

                        },
                      );
                    } else {
                      return Center(child: Text('게시글이 없습니다.'));
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
