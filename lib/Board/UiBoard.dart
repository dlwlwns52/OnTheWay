import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // 플러터의 머티리얼 디자인 위젯을 사용하기 위한 임포트입니다.
import 'package:ontheway_notebook/login/login_screen.dart'; // 로그인 화면을 위한 임포트입니다.
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

  //현재 로그인한 사용자의 이메일을 반환하는 메서드
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
        title: Text('게시판'), // 앱 바의 타이틀을 '게시판'으로 설정합니다.
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NewPostScreen()), // NewPostScreen 위젯으로 이동합니다.
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: (){
              // 본인 확인 클래스 생성시 그 클래스로 이동하는 코드 추가
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
                      content: Text("헬퍼 비용입니다.", textAlign: TextAlign.center,),
                      // behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),

          Flexible(
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: getPosts(), // getPosts 함수로부터 게시글 목록 스트림을 가져옵니다.
              builder: (context, snapshot) {
                // 스트림의 상태에 따라 다른 위젯을 반환합니다.
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // 데이터를 기다리는 중이라면 로딩 인디케이터를 보여줍니다.
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  // 스트림에서 오류가 발생하면 오류 메시지를 보여줍니다.
                  return Center(child: Text('오류가 발생했습니다.'));
                } else if (snapshot.hasData) {
                  // 스트림에 데이터가 있으면, 데이터를 리스트뷰로 보여줍니다.
                  final posts = snapshot.data!;

                  return ListView(
                    children: posts.map((doc) {
                      // 문서들을 순회하면서 각각의 문서를 카드 형태로 보여줍니다.
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>; // 문서의 데이터를 맵으로 변환합니다.
                      return GestureDetector(
                          onTap: (){
                            postManager.showPostDetailsOrEditDeleteDialog(context, doc);
                          },
                          child: Card(
                            child: Container(
                              height: 100,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      // 왼쪽 컬럼에 Padding 추가
                                      child: Padding(
                                        padding: EdgeInsets.only(right: 8.0), // 오른쪽에만 패딩을 추가합니다.
                                        child: Text(
                                          data['my_location'] ?? '제목 없음',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      // 가운데 컬럼은 그대로 둡니다.
                                      child: Text(
                                          data['store'] ?? '내용 없음',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 20.0)
                                      ),
                                    ),
                                    Expanded(
                                      // 오른쪽 컬럼에 Padding 추가
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 8.0), // 왼쪽에만 패딩을 추가합니다.
                                        child: Text(
                                          data['cost'] ?? '추가 내용 없음',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                      );
                    }).toList(), // map 함수로 생성된 Iterable을 List로 변환합니다.
                  );
                }
                else {
                  // 스트림에 데이터가 없으면 '게시글이 없습니다' 메시지를 보여줍니다.
                  return Center(child: Text('게시글이 없습니다.'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
