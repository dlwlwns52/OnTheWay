import 'package:OnTheWay/Chat/AllUsersScreen.dart';
import 'package:OnTheWay/Map/WriteMap/StoreMapScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // 플러터의 머티리얼 디자인 위젯을 사용하기 위한 임포트입니다.
import 'package:OnTheWay/login/LoginScreen.dart'; // 로그인 화면을 위한 임포트입니다.
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 데이터베이스를 사용하기 위한 임포트입니다.
import 'package:flutter/widgets.dart';
import '../Alarm/AlarmUi.dart';
import '../Map/TMapView.dart';
import '../Ranking/SchoolRanking.dart';
import 'NaverWriteBoard.dart';
import 'NaverPostManager.dart';
import '../Alarm/Alarm.dart'; // NaverAlarm 클래스를 임포트합니다.
import 'package:OnTheWay/Map/PostMap/PostStoreMap.dart';
import 'package:OnTheWay/Map/PostMap/PostCurrentMap.dart';
import 'dart:io' show Platform;
// BoardPage 클래스는 게시판 화면의 상태를 관리하는 StatefulWidget 입니다.
class NaverBoardPage extends StatefulWidget {
  @override
  _NaverBoardPageState createState() => _NaverBoardPageState(); // 상태(State) 객체를 생성합니다.
}

// _BoardPageState 클래스는 BoardPage의 상태를 관리합니다.
class _NaverBoardPageState extends State<NaverBoardPage> {
  // Firestore 인스턴스를 생성하여 데이터베이스에 접근할 수 있게 합니다.
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  // PostManager 인스턴스 생성
  final postManager = NaverPostManager();
  // final Alarm = Alarm(); // NaverAlarm 인스턴스를 생성합니다.
  late Alarm alarm;



  @override
  void initState() {
    super.initState();
    alarm = Alarm(
      FirebaseAuth.instance.currentUser?.email ?? '',
          () => setState(() {}),context,
    );
  }

  // Firestore의 'posts' 컬렉션으로부터 게시글 목록을 스트림 형태로 불러오는 함수입니다.
  Stream<List<DocumentSnapshot>> getPosts() {
    return firestore.collection('naver_posts').snapshots().map((snapshot) {
      return snapshot.docs.toList(); // 스냅샷의 문서들을 리스트로 변환하여 반환합니다.
    });
  }


  // 현재 로그인한 사용자의 이메일을 반환하는 메서드로그인이 필요합니다
  String? currentUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email;
  }

  //ios, 안드로이드 기기 텍스트 크기 다르게 하기
  double getTextSize(bool isMyPost){
    if(Platform.isIOS){ // ios
      return isMyPost ? 18 : 18;
    }
    else if(Platform.isAndroid){ // Android
      return isMyPost ? 16 : 16;
    }
    else{
      return isMyPost ? 16 : 16; // 기본 텍스트 크기
    }
  }


  // build 함수는 위젯을 렌더링하는 데 사용됩니다.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Color(0xFFFF8B13),
      //   // backgroundColor: Colors.deepOrange,
      //
      //   // 앱 바의 배경색을 오렌지색으로 설정합니다.
      //   title: Text('한밭대 게시판', style: TextStyle(fontWeight: FontWeight.bold), ),


      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [ Color(0xFFFF4500), Colors.yellow.shade700], // 진한 주황색에서 연한 주황색으로
                // Color(0xFFFF8B13), Color(0xFFFFD700)
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            title: Text('한밭대 게시판', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new),
              onPressed: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => LoginScreen()));
              },
            ),
            actions: <Widget>[
              Padding(
                padding: EdgeInsets.only(right: 10.0),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AlarmUi(),
                          ),
                        );
                        setState(() {
                          alarm.resetNotificationCount();
                        });
                      },
                    ),
                    if (alarm.getNotificationCount() > 0)
                      Positioned(
                        right: 11,
                        top: 11,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '${alarm.getNotificationCount()}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
//게시판 몸통
      body:
      Column(
        children: <Widget>[

          SizedBox(height: 10), // AppBar와 Row 사이에 20픽셀의 높이를 가진 공간을 추가합니다.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.location_on,), // 원하는 색상으로 설정
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "상대방이 있는 위치 입니다.",
                        textAlign: TextAlign.center,
                      ),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),


              IconButton(
                icon: Icon(Icons.store,),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("가게 위치 입니다.", textAlign: TextAlign.center,),
                      // behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),

              IconButton(
                icon: Icon(Icons.monetization_on),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("도움 비용입니다.", textAlign: TextAlign.center,),
                      // behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),

          Flexible( // Flexible 위젯을 사용하여 자식 위젯이 화면 공간을 유연하게 확장할 수 있도록 함
            child: StreamBuilder<List<
                DocumentSnapshot>>( // Firestore 데이터 스트림을 사용하여 게시물 목록을 갱신하는 위젯
              stream: getPosts(), // getPosts() 함수로부터 Firestore 데이터 스트림을 얻어옴
              builder: (context, snapshot) { // 스트림의 상태에 따라 화면을 동적으로 구성하는 빌더 함수
                if (snapshot.connectionState ==
                    ConnectionState.waiting) { // 데이터가 아직 로딩 중인 경우
                  return Center(
                      child: CircularProgressIndicator()); // 로딩 중을 나타내는 화면을 반환
                } else if (snapshot.hasError) { // 데이터 로딩 중에 오류가 발생한 경우
                  return Center(child: Text('오류가 발생했습니다.')); // 오류 메시지를 표시
                } else if (snapshot.hasData) { // 데이터가 로딩되었고, 데이터가 있는 경우
                  final posts = snapshot.data!; // Firestore에서 가져온 게시물 목록
                  final myEmail = currentUserEmail(); // 현재 사용자의 이메일을 가져옴

                  // 게시물 목록을 사용자 이메일을 기준으로 정렬
                  posts.sort((a, b) {
                    Map<String, dynamic> dataA = a.data() as Map<String,
                        dynamic>;
                    Map<String, dynamic> dataB = b.data() as Map<String,
                        dynamic>;
                    bool isMyPostA = dataA['user_email'] == myEmail;
                    bool isMyPostB = dataB['user_email'] == myEmail;
                    if (isMyPostA && !isMyPostB) return -1;
                    if (!isMyPostA && isMyPostB) return 1;
                    return 0;
                  });

                  return ListView.builder( // 게시물 목록을 스크롤 가능한 리스트뷰로 표시
                    itemCount: posts.length, // 아이템 개수는 게시물 목록의 길이
                    itemBuilder: (context, index) { // 각 아이템을 생성하는 함수 정의
                      DocumentSnapshot doc = posts[index]; // 현재 아이템에 대한 Fiestore 문서
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>; // Firestore 문서 데이터 가져옴
                      bool isMyPost = data['user_email'] == myEmail; // 현재 아이템이 내 게시물인지 여부
                      bool nextPostIsMine = false;


                      if (index + 1 < posts.length) { // 다음 아이템이 있는 경우
                        Map<String, dynamic> nextData = posts[index + 1]
                            .data() as Map<String, dynamic>; // 다음 아이템의 데이터
                        nextPostIsMine = nextData['user_email'] ==
                            myEmail; // 다음 아이템이 내 게시물인지 여부
                      }

                      return Column(
                        children: <Widget>[
                          InkWell( // 터치 이벤트를 처리하기 위한 InkWell 위젯
                            onTap: () {
                              postManager.helpAndExit(context, doc); // 게시물을 탭하면 상세 정보 또는 편집/삭제 다이얼로그를 표시
                            },
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0), // 라운드 모서리
                              ),
                              elevation: 3.0, // 그림자 효과
                              color: isMyPost ? Colors.orange[100] : Colors.white,
                              child: Container(
                                height: 100, // 카드의 높이 설정
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  // 내부 패딩 설정
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Center( // Expanded 안에서 중앙 정렬을 위해 Center 위젯 사용
                                          child: Container(
                                            width: 80, // 버튼의 가로 폭을 70으로 고정
                                            child: GestureDetector(
                                              onTap: () {
                                                if (!isMyPost) {
                                                  // postManager.helpAndExit(context, doc); // 게시물을 탭하면 상세 정보 또는 편집/삭제 다이얼로그를 표시
                                                  Navigator.of(context).push(MaterialPageRoute(
                                                    builder: (context) => PostCurrentMap(documentId: doc.id),
                                                  ));
                                                } else {
                                                  postManager.helpAndExit(context, doc); // 내 게시물인 경우에는 원래 게시물 눌렀을때 기능
                                                }
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(5.0), // 내부 여백
                                                decoration: BoxDecoration(
                                                  color: isMyPost ? Colors.orange[100] : Colors.white, // 배경 색상
                                                  borderRadius: BorderRadius.circular(20.0), // 둥근 모서리
                                                  boxShadow: isMyPost ? [] :[
                                                    BoxShadow(
                                                      // color: Colors.deepOrangeAccent.withOpacity(0.25),
                                                      color: Colors.blueGrey.withOpacity(0.25),
                                                      spreadRadius: 1,
                                                      // blurRadius: 0,
                                                      offset: Offset(0, 2), // 그림자 위치 조정
                                                    ),
                                                  ],
                                                ),
                                                child: Text(
                                                  data['my_location'] ?? '내용 없음',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    // fontSize: isMyPost ? 19 : 18,
                                                    fontSize: getTextSize(isMyPost),
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black, // 텍스트 색상 변경
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      Expanded(
                                        child: Center(
                                          child: Container(
                                             width: 80,
                                            child: GestureDetector(
                                              onTap: () {
                                                if(!isMyPost){
                                                  Navigator.of(context).push(MaterialPageRoute(
                                                      builder: (context) => PostStoreMap(documentId: doc.id,),
                                                  ));
                                                }
                                                else{
                                                  postManager.helpAndExit(context, doc);
                                                }
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(5.0),
                                                decoration: BoxDecoration(
                                                  color: isMyPost ? Colors.orange[100] : Colors.white, // 배경 색상
                                                  borderRadius: BorderRadius.circular(20),
                                                  boxShadow: isMyPost ? []
                                                    : [
                                                      BoxShadow(
                                                        color: Colors.blueGrey.withOpacity(0.25),
                                                        spreadRadius: 1,
                                                        offset: Offset(0,2),
                                                      ),
                                                  ],
                                                ),
                                                child: Text(
                                                  data['store'] ?? '내용 없음',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: getTextSize(isMyPost),
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black, // 텍스트 색상 변경
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      Expanded(
                                        child: Text(
                                          data['cost'] ?? '추가 내용 없음',
                                          // 비용 정보 또는 '추가 내용 없음' 표시
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 17.0,
                                              fontWeight: FontWeight.bold, color: Colors.black),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 현재 게시물이 내 게시물이고 다음 게시물이 내 게시물이 아닐 때만 구분선을 추가
                          if (isMyPost && !nextPostIsMine)
                            Divider(
                              color: Colors.orange[50], // 구분선의 색상 설정
                              thickness: 3.0, // 구분선의 두께 설정
                            ),
                        ],
                      );
                    },
                  );
                } else { // 데이터가 로딩되지 않았거나 비어 있는 경우
                  return Center(
                      child: Text('게시글이 없습니다.')); // '게시글이 없습니다.' 메시지를 표시
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_rounded, color: Colors.black),
            label: '채팅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.create, color: Colors.black,),
            label: '새 게시글',
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.person, color: Colors.black,),
          //   label: '프로필',
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school, color: Colors.black,),
            label: '학교 랭킹',
          ),

        ],
        selectedItemColor: Colors.black,    // 선택된 항목의 텍스트 색상
        unselectedItemColor: Colors.black,  // 선택되지 않은 항목의 텍스트 색상
        onTap: (index) {
          // 채팅방으로 이동
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AllUsersScreen()),
            );
            //새 게시글 만드는 곳으로 이동
          } else if (index == 1) {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NaverNewPostScreen()),
            );
          }
          else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RankingPage()),
            );
          }

        },
        selectedLabelStyle: TextStyle(color: Colors.orange), // 선택된 항목의 텍스트 색상 설정
      ),
    );
  }
}

