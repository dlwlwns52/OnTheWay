import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NaverNewPostScreen extends StatefulWidget {
  final DocumentSnapshot? post;

  NaverNewPostScreen({this.post});

  @override
  _NaverNewPostScreenState createState() => _NaverNewPostScreenState();
}

class _NaverNewPostScreenState extends State<NaverNewPostScreen> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _storeController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _requestController = TextEditingController();
  final FocusNode _buttonFocusNode = FocusNode();

  @override
  void dispose() {
    _locationController.dispose();
    _storeController.dispose();
    _costController.dispose();
    _requestController.dispose();
    _buttonFocusNode.dispose();
    super.dispose();
  }

  String? getUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? user.email : '이메일 없음';
  }

  Future<void> _uploadPost() async {
    if (_locationController.text.isEmpty) {
      _showSnackBar("\'본인 위치\' 칸을 입력해주세요.");
      return;
    }

    if (_storeController.text.isEmpty) {
      _showSnackBar("\'주문 시킬 가게\' 칸을 입력해주세요.");
      return;
    }

    if (_costController.text.isEmpty) {
      _showSnackBar("\'비용\' 칸을 입력해주세요.");
      return;
    }

    if (_requestController.text.isEmpty) {
      _showSnackBar("\'요청 사항\' 칸을 입력해주세요.");
      return;
    }

    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      String? email = getUserEmail();

      QuerySnapshot existingPosts = await db
          .collection('naver_posts')
          .where('my_location', isEqualTo: _locationController.text)
          .where('user_email', isEqualTo: email)
          .get();

      if (existingPosts.docs.isNotEmpty && widget.post == null) {
        _showSnackBar('동일한 제목의 게시물이 이미 존재합니다.');
      } else {
        String documentName =
            widget.post?.id ?? "${_locationController.text}_${email ?? 'unknown'}";
        await db.collection('naver_posts').doc(documentName).set({
          'my_location': _locationController.text,
          'store': _storeController.text,
          'cost': _costController.text,
          'user_email': email,
          'Request': _requestController.text,
          'date': DateTime.now(),
        });

        Navigator.of(context).pop();
      }
    } catch (e) {
      _showSnackBar("게시물 업로드에 실패했습니다.");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시물 작성'),
        backgroundColor: Colors.orange,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: '본인 위치',
                    contentPadding: EdgeInsets.symmetric(vertical: 20.0),
                  ),
                  textInputAction: TextInputAction.next,
                  maxLines: null,
                  maxLength: 20,
                ),
                SizedBox(height: 8.0),
                TextField(
                  controller: _storeController,
                  decoration: InputDecoration(
                    labelText: '주문 시킬 가게',
                    contentPadding: EdgeInsets.symmetric(vertical: 20.0),
                  ),
                  textInputAction: TextInputAction.next,
                  maxLines: null,
                  maxLength: 20,
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: _costController,
                  decoration: InputDecoration(
                    labelText: '비용',
                    contentPadding: EdgeInsets.symmetric(vertical: 20.0),
                  ),
                  textInputAction: TextInputAction.next,
                  maxLines: null,
                  maxLength: 20,
                ),
                SizedBox(height: 16.0),
                TextField(
                  controller: _requestController,
                  decoration: InputDecoration(
                    labelText: '요청사항',
                    contentPadding: EdgeInsets.all(3),
                    alignLabelWithHint: true,
                  ),
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.done,
                  minLines: 13,
                  maxLines: null,
                  maxLength: 100,
                  onSubmitted: (value) {
                    FocusScope.of(context).requestFocus(_buttonFocusNode);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        // color: Colors.transparent, // 배경 색상을 투명하게 설정
        child: Container(
          margin: EdgeInsets.all(16.0), // 여백 추가
          decoration: BoxDecoration(
            color: Colors.orange, // 버튼 배경색
            borderRadius: BorderRadius.circular(10.0), // 버튼 모서리를 둥글게 만듦

          ),
          child: ElevatedButton.icon(
            onPressed: _uploadPost,
            icon: Icon(Icons.send), // 버튼 아이콘
            label: Text(
              '게시하기',
              style: TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              primary: Colors.transparent, // 버튼 색상 투명하게 설정
              shadowColor: Colors.transparent, // 그림자 색상 투명하게 설정
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
      _locationController.text = widget.post!['my_location'] ?? '';
      _storeController.text = widget.post!['store'] ?? '';
      _costController.text = widget.post!['cost'] ?? '';
      _requestController.text = widget.post!['Request'] ?? '';
    }
  }
}
