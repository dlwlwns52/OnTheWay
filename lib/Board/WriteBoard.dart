import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


// 새 게시글을 작성하는 화면을 위한 StatefulWidget입니다.
class NewPostScreen extends StatefulWidget {
  @override
  _NewPostScreenState createState() => _NewPostScreenState(); // 상태 객체를 생성합니다.
}

// NewPostScreen의 상태를 관리하는 클래스입니다.
class _NewPostScreenState extends State<NewPostScreen> {
  // 사용자 입력을 관리하기 위한 컨트롤러들입니다.
  final TextEditingController _locationController = TextEditingController(); //사용자 위치 필드를 위한 컨트롤러입니다.
  final TextEditingController _storeController = TextEditingController(); // 주문 시킬 가게를 위한 컨트롤러입니다.
  final TextEditingController _costController = TextEditingController(); // 비용을 위한 컨트롤러 입니다.
  final TextEditingController _RequestController = TextEditingController(); // 요청사항을 위한 컨트롤러 입니다.

// 사용자의 이메일을 가져오는 함수입니다.
  String? getUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? user.email : '이메일 없음';
  }

  // 게시물을 업로드하는 함수입니다.
  Future<void> _uploadPost() async {
    try {
      // Firestore의 'posts' 컬렉션에 새 문서를 추가합니다.

      // 현재 로그인된 사용자의 이메일을 가져옵니다.
      String? email = getUserEmail();

      // 문서 이름을 'my_location' 필드와 'user_email' 필드로 설정
      String documentName = "${_locationController.text}_${email ?? 'unknown'}";

      await FirebaseFirestore.instance.collection('posts').doc(documentName).set({
        'my_location': _locationController.text, // 제목 필드
        'store': _storeController.text, // 내용 필드
        'cost': _costController.text, // 새로운 필드 추가
        'user_email': email, // 사용자 이메일 필드 추가
        'Request' : _RequestController.text,
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
              controller: _locationController, // 제목을 입력받기 위한 텍스트 필드입니다.
              decoration: InputDecoration(
                labelText: '본인 위치', // 라벨을 '제목'으로 설정합니다.
                contentPadding: EdgeInsets.symmetric(vertical: 20.0),
              ),
              textInputAction: TextInputAction.next, // 다음 필드로 이동할 수 있도록 설정
            ),

            SizedBox(height: 8.0), // 위젯 사이의 간격을 주기 위한 SizedBox입니다.

            TextField(
              controller: _storeController, // 내용을 입력받기 위한 텍스트 필드입니다.
              decoration: InputDecoration(
                labelText: '주문 시킬 가게', // 라벨을 '내용'으로 설정합니다.\
                contentPadding: EdgeInsets.symmetric(vertical: 20.0),
              ),
              textInputAction: TextInputAction.next, // 다음 필드로 이동할 수 있도록 설정
            ),

            SizedBox(height: 16.0), // 위젯 사이의 간격을 주기 위한 SizedBox입니다.

            TextField(

              controller: _costController, // 내용을 입력받기 위한 텍스트 필드입니다.
              decoration: InputDecoration(
                labelText: '비용', // 라벨을 '내용'으로 설정합니다.
                contentPadding: EdgeInsets.symmetric(vertical: 20.0),
              ),
              textInputAction: TextInputAction.next, // 다음 필드로 이동할 수 있도록 설정
            ),

            SizedBox(height: 16.0,),

            TextField(
              controller: _RequestController, // 내용을 입력받기 위한 텍스트 필드입니다.
              decoration: InputDecoration(
                labelText: '요청사항', // 라벨을 '내용'으로 설정합니다.
                contentPadding: EdgeInsets.symmetric(vertical: 100.0),
              ),
              textInputAction: TextInputAction.next, // 다음 필드로 이동할 수 있도록 설정
            ),

            SizedBox(height: 16.0,),


            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,

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
