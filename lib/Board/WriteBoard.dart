import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


// 새 게시글을 작성하는 화면을 위한 StatefulWidget입니다.
class NewPostScreen extends StatefulWidget {
  final DocumentSnapshot? post;
  NewPostScreen({this.post});

  @override
  _NewPostScreenState createState() => _NewPostScreenState();
}

// NewPostScreen의 상태를 관리하는 클래스입니다.
class _NewPostScreenState extends State<NewPostScreen> {
  // 사용자 입력을 관리하기 위한 컨트롤러들입니다.
  final TextEditingController _locationController = TextEditingController(); //사용자 위치 필드를 위한 컨트롤러입니다.
  final TextEditingController _storeController = TextEditingController(); // 주문 시킬 가게를 위한 컨트롤러입니다.
  final TextEditingController _costController = TextEditingController(); // 비용을 위한 컨트롤러 입니다.
  final TextEditingController _RequestController = TextEditingController(); // 요청사항을 위한 컨트롤러 입니다.
  final FocusNode _buttonFocusNode = FocusNode();// 게시하기 버튼을 위한 FocusNode 추가


  @override
  void dispose(){
    _buttonFocusNode.dispose();// FocusNode 정리 추가
    super.dispose();
  }

// 사용자의 이메일을 가져오는 함수입니다.
  String? getUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? user.email : '이메일 없음';
  }

  // 게시물을 업로드하는 함수입니다.
  Future<void> _uploadPost() async {

    // 위치 필드가 비어있는지 확인
    if(_locationController.text.isEmpty){
      _showSnackBar("\'본인 위치\' 칸을 입력해주세요.");
      return;
    }

    if (_storeController.text.isEmpty){
      _showSnackBar("\'주문 시킬 가게\' 칸을 입력해주세요.");
      return;
    }

    if (_costController.text.isEmpty){
      _showSnackBar("\'비용\' 칸을 입력해주세요.");
      return;
    }

    if (_RequestController.text.isEmpty){
      _showSnackBar("\'요청 사항\' 칸을 입력해주세요.");
      return;
    }

    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      String? email = getUserEmail();

      // 파이어스토어 컬렉션 'posts' 에서 이메일과 제목 찾아옴
      QuerySnapshot existingPosts = await db
          .collection('posts')
          .where('my_location', isEqualTo: _locationController.text)
          .where('user_email', isEqualTo: email)
          .get();

      if (existingPosts.docs.isNotEmpty && widget.post == null){
        _showSnackBar('동일한 제목의 게시물이 이미 존재합니다.');
      }else {
        // 새 게시물 추가 또는 기존 게시물 수정
        String documentName = widget.post?.id ?? "${_locationController.text}_${email ?? 'unknown'}";
        await db.collection('posts').doc(documentName).set({
          'my_location': _locationController.text,
          'store': _storeController.text,
          'cost': _costController.text,
          'user_email': email,
          'Request': _RequestController.text,
          'date': DateTime.now(),
        });

        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnackBar("게시물 업로드에 실패했습니다.");
    }
  }


  //스낵바를 표시하는 함수
  void _showSnackBar(String message){
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message,textAlign: TextAlign.center,),
      duration: Duration(seconds: 1),
      ),
    );
  }


  // 위젯을 빌드하는 메소드입니다.
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('게시물 작성'), // 앱 바의 타이틀을 '새 게시물 작성'으로 설정합니다.
        backgroundColor: Colors.orange,
      ),
        body: SafeArea( // SafeArea 추가
          child: SingleChildScrollView( // SingleChildScrollView 추가
            child: Padding(
              padding: EdgeInsets.all(16.0), // 전체 패딩을 설정합니다.
              child: Column(

                // 세로로 위젯들을 나열하기 위한 컬럼 위젯입니다.
                children: <Widget>[

                  TextField(
                    controller: _locationController, // 제목을 입력받기 위한 텍스트 필드입니다.
                    decoration: InputDecoration(
                      labelText: '본인 위치', // 라벨을 '제목'으로 설정합니다.
                      contentPadding: EdgeInsets.symmetric(vertical: 20.0),
                    ),
                    textInputAction: TextInputAction.next, // 다음 필드로 이동할 수 있도록 설정
                    maxLines: null, // 자동 줄바꿈을 활성화합니다.
                    maxLength: 20, // 최대 글자 수를 제한합니다.
                  ),

                  SizedBox(height: 8.0), // 위젯 사이의 간격을 주기 위한 SizedBox입니다.

                  TextField(
                    controller: _storeController, // 내용을 입력받기 위한 텍스트 필드입니다.
                    decoration: InputDecoration(
                      labelText: '주문 시킬 가게', // 라벨을 '내용'으로 설정합니다.\
                      contentPadding: EdgeInsets.symmetric(vertical: 20.0),
                    ),
                    textInputAction: TextInputAction.next, // 다음 필드로 이동할 수 있도록 설정
                    maxLines: null, // 자동 줄바꿈을 활성화합니다.
                    maxLength: 20, // 최대 글자 수를 제한합니다.
                  ),

                  SizedBox(height: 16.0), // 위젯 사이의 간격을 주기 위한 SizedBox입니다.

                  TextField(

                    controller: _costController, // 내용을 입력받기 위한 텍스트 필드입니다.
                    decoration: InputDecoration(
                      labelText: '비용', // 라벨을 '내용'으로 설정합니다.
                      contentPadding: EdgeInsets.symmetric(vertical: 20.0),
                    ),
                    textInputAction: TextInputAction.next, // 다음 필드로 이동할 수 있도록 설정
                    maxLines: null, // 자동 줄바꿈을 활성화합니다.
                    maxLength: 20, // 최대 글자 수를 제한합니다.
                  ),

                  SizedBox(height: 16.0,),

                  TextField(
                      controller: _RequestController, // 텍스트 필드의 입력값을 관리하는 컨트롤러입니다.
                      decoration: InputDecoration(
                        labelText: '요청사항', // 텍스트 필드 위에 표시될 라벨 텍스트입니다.
                        contentPadding: EdgeInsets.all(3), // 텍스트 필드 내부의 패딩 값을 설정합니다.
                        alignLabelWithHint: true, // 라벨이 힌트 텍스트와 정렬되도록 설정합니다.
                      ),
                      keyboardType: TextInputType.multiline, // 키보드 유형을 다중 줄 입력으로 설정합니다.
                      textInputAction: TextInputAction.done, // 키보드에 '완료' 버튼을 표시합니다.
                    minLines: 13, // 최소 5줄의 높이를 가지는 텍스트 필드로 시작합니다.
                    maxLines: null, // 입력에 따라 늘어나는 줄 수에 제한을 두지 않습니다.
                    maxLength: 100, // 최대 글자 수를 100으로 제한합니다.

                    onSubmitted: (value){
                      FocusScope.of(context).requestFocus(_buttonFocusNode);
                    }
                  ),


                  SizedBox(height: 16.0,),

                  SizedBox(
                    width: 150,
                    height: 40,
                    child: ElevatedButton(
                      focusNode: _buttonFocusNode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: Text('게시하기'), // 버튼의 텍스트를 '게시하기'로 설정합니다.
                      onPressed: _uploadPost, // 버튼이 눌렸을 때 _uploadPost 함수를 실행합니다.
                    ),
                  ),
               ],
              ),
            ),
         ),
       ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      // widget.post에서 데이터를 사용하여 필드를 초기화
      _locationController.text = widget.post!['my_location'] ?? '';
      _storeController.text = widget.post!['store'] ?? '';
      _costController.text = widget.post!['cost'] ?? '';
      _RequestController.text = widget.post!['Request'] ?? '';
    }
  }
}