import 'package:flutter/material.dart'; // 플러터의 머티리얼 디자인 위젯을 사용하기 위한 임포트입니다.
import 'package:ontheway_notebook/login/login_screen.dart'; // 로그인 화면을 위한 임포트입니다.
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 데이터베이스를 사용하기 위한 임포트입니다.

// BoardPage 클래스는 게시판 화면의 상태를 관리하는 StatefulWidget 입니다.
class BoardPage extends StatefulWidget {
  @override
  _BoardPageState createState() => _BoardPageState(); // 상태(State) 객체를 생성합니다.
}

// _BoardPageState 클래스는 BoardPage의 상태를 관리합니다.
class _BoardPageState extends State<BoardPage> {
  // Firestore 인스턴스를 생성하여 데이터베이스에 접근할 수 있게 합니다.
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Firestore의 'posts' 컬렉션으로부터 게시글 목록을 스트림 형태로 불러오는 함수입니다.
  Stream<List<DocumentSnapshot>> getPosts() {
    return firestore.collection('posts').snapshots().map((snapshot) {
      return snapshot.docs.toList(); // 스냅샷의 문서들을 리스트로 변환하여 반환합니다.
    });
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
                        return Card(
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
                                      data['title'] ?? '제목 없음',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  // 가운데 컬럼은 그대로 둡니다.
                                  child: Text(
                                    data['content'] ?? '내용 없음',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Expanded(
                                  // 오른쪽 컬럼에 Padding 추가
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 8.0), // 왼쪽에만 패딩을 추가합니다.
                                    child: Text(
                                      data['content2'] ?? '추가 내용 없음',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ),
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




// 새 게시글을 작성하는 화면을 위한 StatefulWidget입니다.
class NewPostScreen extends StatefulWidget {
  @override
  _NewPostScreenState createState() => _NewPostScreenState(); // 상태 객체를 생성합니다.
}

// NewPostScreen의 상태를 관리하는 클래스입니다.
class _NewPostScreenState extends State<NewPostScreen> {
  // 사용자 입력을 관리하기 위한 컨트롤러들입니다.
  final TextEditingController _titleController = TextEditingController(); // 제목 입력 필드를 위한 컨트롤러입니다.
  final TextEditingController _contentController = TextEditingController(); // 내용 입력 필드를 위한 컨트롤러입니다.
  final TextEditingController _content2Controller = TextEditingController();
  // 게시물을 업로드하는 함수입니다.
  Future<void> _uploadPost() async {
    try {
      // Firestore의 'posts' 컬렉션에 새 문서를 추가합니다. 문서에는 입력받은 제목, 내용, 현재 날짜가 포함됩니다.
      await FirebaseFirestore.instance.collection('posts').add({
        'my_location': _titleController.text, // 제목 필드
        'store': _contentController.text, // 내용 필드
        'cost': _content2Controller.text, // 새로운 필드 추가
        'date': DateTime.now(), // 현재 날짜와 시간
      });
      // 성공적으로 업로드 후 이전 화면으로 돌아갑니다.
      Navigator.of(context).pop();
    } catch (e) {
      // 오류 발생 시 사용자에게 알립니다.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시물 업로드에 실패했습니다.')), // 스낵바로 오류 메시지를 보여줍니다.
      );
    }
  }



  // 위젯을 빌드하는 메소드입니다.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시물 작성'), // 앱 바의 타이틀을 '새 게시물 작성'으로 설정합니다.
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0), // 전체 패딩을 설정합니다.
        child: Column(
          // 세로로 위젯들을 나열하기 위한 컬럼 위젯입니다.
          children: <Widget>[

            TextField(
              controller: _titleController, // 제목을 입력받기 위한 텍스트 필드입니다.
              decoration: InputDecoration(
                labelText: '본인 위치', // 라벨을 '제목'으로 설정합니다.
              ),
            ),

            SizedBox(height: 8.0), // 위젯 사이의 간격을 주기 위한 SizedBox입니다.

            TextField(
              controller: _contentController, // 내용을 입력받기 위한 텍스트 필드입니다.
              decoration: InputDecoration(
                labelText: '주문 시킬 가게', // 라벨을 '내용'으로 설정합니다.
              ),
            ),

            SizedBox(height: 16.0), // 위젯 사이의 간격을 주기 위한 SizedBox입니다.

            TextField(

              controller: _content2Controller, // 내용을 입력받기 위한 텍스트 필드입니다.
              decoration: InputDecoration(
                labelText: '비용', // 라벨을 '내용'으로 설정합니다.
              ),
            ),

              SizedBox(height: 16.0,),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange
              ),
              child: Text('게시하기'), // 버튼의 텍스트를 '게시하기'로 설정합니다.
              onPressed: _uploadPost, // 버튼이 눌렸을 때 _uploadPost 함수를 실행합니다.
            ),
          ],
        ),
      ),
    );
  }
}
