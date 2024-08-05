import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // 플러터의 머티리얼 디자인 위젯을 사용하기 위한 임포트입니다.
import 'package:OnTheWay/login/LoginScreen.dart'; // 로그인 화면을 위한 임포트입니다.
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 데이터베이스를 사용하기 위한 임포트입니다.
import 'WriteBoard.dart';
import 'PostManager.dart';

// BoardPage 클래스는 게시판 화면의 상태를 관리하는 StatefulWidget 입니다.
class BoardPage extends StatefulWidget {
  @override
  _BoardPageState createState() => _BoardPageState(); // 상태(State) 객체를 생성합니다.
}

// _BoardPageState 클래스는 BoardPage의 상태를 관리합니다.
class _BoardPageState extends State<BoardPage> {
  // Firestore 인스턴스를 생성하여 데이터베이스에 접근할 수 있게 합니다.
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  // PostManager 인스턴스 생성
  final postManager = PostManager();



  // Firestore의 'posts' 컬렉션으로부터 게시글 목록을 스트림 형태로 불러오는 함수입니다.
  Stream<List<DocumentSnapshot>> getPosts() {
    return firestore.collection('posts').snapshots().map((snapshot) {
      return snapshot.docs.toList(); // 스냅샷의 문서들을 리스트로 변환하여 반환합니다.
    });
  }


  // 현재 로그인한 사용자의 이메일을 반환하는 메서드
  String? currentUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email;
  }


  // build 함수는 위젯을 렌더링하는 데 사용됩니다.
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.orange, // 앱 바의 배경색을 오렌지색으로 설정합니다.
        title: Text('반갑습니다\n이곳에 오시다니.\n당신은 선택받은 자 입니다.',
            style: TextStyle(fontSize: 15) ,textAlign: TextAlign.center), // 앱 바의 타이틀을 '게시판'으로 설정합니다.
        centerTitle: true,

        leading: IconButton(
          icon: Icon(Icons.arrow_back), // 뒤로 가기 아이콘을 설정합니다.
          onPressed: () {
            // 아이콘 버튼이 눌렸을 때 수행할 동작을 정의합니다.
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => LoginScreen())); // 로그인 화면으로 이동합니다.
          },
        ),

        actions: [
          IconButton(
            icon: Icon(Icons.create), // '생성' 아이콘을 설정합니다.
            onPressed: () {
              // 아이콘 버튼이 눌렸을 때 새 게시글 작성 화면으로 이동합니다.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("에러게시판 입니다..\n다시 뒤로가기 해주세요! \n 죄송합니다.!",
                      style: TextStyle(fontSize: 25) ,textAlign: TextAlign.center),
                  duration: Duration(seconds: 2),),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: (){
              // 본인 확인 클래스 생성시 그 클래스로 이동하는 코드 추가
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("뾱!",
                      style: TextStyle(fontSize: 25) ,textAlign: TextAlign.center),
                  duration: Duration(seconds: 2),),
              );
            },
          )
        ],
      ),

//게시판 몸통
      body: Column(
        children: <Widget>[
          SizedBox(height: 10), // AppBar와 Row 사이에 20픽셀의 높이를 가진 공간을 추가합니다.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.home),
                onPressed: (){
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("상대방이 있는 위치 입니다.", textAlign: TextAlign.center,),
                      // behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),

              IconButton(
                icon: Icon(Icons.store),
                onPressed: (){
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
                onPressed: (){
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
            child: StreamBuilder<List<DocumentSnapshot>>( // Firestore 데이터 스트림을 사용하여 게시물 목록을 갱신하는 위젯
              stream: getPosts(), // getPosts() 함수로부터 Firestore 데이터 스트림을 얻어옴
              builder: (context, snapshot) { // 스트림의 상태에 따라 화면을 동적으로 구성하는 빌더 함수
                if (snapshot.connectionState == ConnectionState.waiting) { // 데이터가 아직 로딩 중인 경우
                  return Center(child: CircularProgressIndicator()); // 로딩 중을 나타내는 화면을 반환
                } else if (snapshot.hasError) { // 데이터 로딩 중에 오류가 발생한 경우
                  return Center(child: Text('오류가 발생했습니다.')); // 오류 메시지를 표시
                } else if (snapshot.hasData) { // 데이터가 로딩되었고, 데이터가 있는 경우
                  final posts = snapshot.data!; // Firestore에서 가져온 게시물 목록
                  final myEmail = currentUserEmail(); // 현재 사용자의 이메일을 가져옴

                  // 게시물 목록을 사용자 이메일을 기준으로 정렬
                  posts.sort((a, b) {
                    Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
                    Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
                    bool isMyPostA = dataA['user_email'] == myEmail;
                    bool isMyPostB = dataB['user_email'] == myEmail;
                    if (isMyPostA && !isMyPostB) return -1;
                    if (!isMyPostA && isMyPostB) return 1;
                    return 0;
                  });

                  return ListView.builder( // 게시물 목록을 스크롤 가능한 리스트뷰로 표시
                    itemCount: posts.length, // 아이템 개수는 게시물 목록의 길이
                    itemBuilder: (context, index) { // 각 아이템을 생성하는 함수 정의
                      DocumentSnapshot doc = posts[index]; // 현재 아이템에 대한 Firestore 문서
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>; // Firestore 문서 데이터 가져옴
                      bool isMyPost = data['user_email'] == myEmail; // 현재 아이템이 내 게시물인지 여부
                      bool nextPostIsMine = false;

                      if (index + 1 < posts.length) { // 다음 아이템이 있는 경우
                        Map<String, dynamic> nextData = posts[index + 1].data() as Map<String, dynamic>; // 다음 아이템의 데이터
                        nextPostIsMine = nextData['user_email'] == myEmail; // 다음 아이템이 내 게시물인지 여부
                      }

                      return Column(
                        children: <Widget>[
                          InkWell( // 터치 이벤트를 처리하기 위한 InkWell 위젯
                            onTap: () {
                              postManager.helpAndExit(context, doc); // 게시물을 탭하면 상세 정보 또는 편집/삭제 다이얼로그를 표시
                            },
                            child: Card( // 정보를 담는 카드 위젯
                              color: isMyPost ? Colors.orange[100]  : Colors.white, // 내 게시물인 경우 배경색을 주황색으로, 아닌 경우 흰색으로 설정
                              child: Container(
                                height: 100, // 카드의 높이 설정
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0), // 내부 패딩 설정
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          data['my_location'] ?? '제목 없음', // 위치 정보 또는 '제목 없음' 표시
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          data['store'] ?? '내용 없음', // 가게 정보 또는 '내용 없음' 표시
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          data['cost'] ?? '추가 내용 없음', // 비용 정보 또는 '추가 내용 없음' 표시
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
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
                  return Center(child: Text('게시글이 없습니다.')); // '게시글이 없습니다.' 메시지를 표시
                }
              },
            ),
          ),
        ],
      ),
    );

  }
}