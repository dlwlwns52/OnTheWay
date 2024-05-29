import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Map/WriteMap/CurrentMapScreen.dart';
import '../Map/WriteMap/StoreMapScreen.dart';

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


  //위치 관련 변수
  String? _currentSelectedLocation; //위치 저장
  String? _storeSelectedLocation;
  bool currentLocationSet = false; //버튼 활성화
  bool storeLocationSet = false;

  //스낵바가 이미 표시되었는지를 추적하는 플래그
  bool _snackBarShown = false;

//게시물 수정하기 누를때 전 정보를 불러옴
  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _locationController.text = widget.post!['my_location'] ?? '';
      _storeController.text = widget.post!['store'] ?? '';
      _costController.text = widget.post!['cost'] ?? '';
      _requestController.text = widget.post!['Request'] ?? '';
      _storeSelectedLocation = widget.post!['store_location'] ?? '';
      _currentSelectedLocation = widget.post!['current_location'] ?? '';
      // 위치 정보가 있다면 변수들을 true로 설정합니다.
      if (_storeSelectedLocation != null && _storeSelectedLocation!.isNotEmpty) {
        storeLocationSet = true;
      }
      if (_currentSelectedLocation != null && _currentSelectedLocation!.isNotEmpty) {
        currentLocationSet = true;
      }
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _storeController.dispose();
    _costController.dispose();
    _requestController.dispose();
    _buttonFocusNode.dispose();
    super.dispose();
  }

  void _checkMaxLength(TextEditingController controller, int maxLength) {
    if (controller.text.length == maxLength && !_snackBarShown) {
      controller.text = controller.text.substring(0, maxLength);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '최대 ${maxLength}글자까지 입력 가능합니다. \n 상세내용은 채팅방을 이용해주세요.',
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 10),
        ),
      );
      _snackBarShown = true;
    } else if (controller.text.length < maxLength){
      _snackBarShown = false;
    }
  }



  //현재위치 받는 메소드
  void _currentChooseLocation() async {
    // MapScreen으로부터 반환된 위치를 받습니다.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CurrentMapScreen()),
    );

    // 반환된 위치를 변수에 저장합니다.
    if (result != null) {
      setState(() {
        // LatLng 객체를 문자열 형태로 저장
        _currentSelectedLocation = "${result.latitude},${result.longitude}";
        currentLocationSet = true;
      });
    }
  }

  //가게위치 받는 메소드
  void _storeChooseLocation() async {
    // MapScreen으로부터 반환된 위치를 받습니다.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StoreMapScreen()),
    );

    // 반환된 위치를 변수에 저장합니다.
    if (result != null) {
      setState(() {
        // LatLng 객체를 문자열 형태로 저장
        _storeSelectedLocation = "${result.latitude},${result.longitude}";
        storeLocationSet = true;
      });
    }
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

    if(currentLocationSet == false){
      _showSnackBar("\'본인 위치 설정\' 을 완료해주세요.");
      return;
    }

    if(storeLocationSet == false){
      _showSnackBar("\'가게 위치 설정\' 을 완료해주세요.");
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
        String documentName = widget.post?.id ?? "${_locationController.text}_${email ?? 'unknown'}";
        await db.collection('naver_posts').doc(documentName).set({
          'store_location' :_storeSelectedLocation ?? '가게 위치 미설정',
          'current_location' : _currentSelectedLocation ?? '현재 위치 미설정',
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
      print(e);
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
        title: Text('게시물 작성',style: TextStyle(fontWeight: FontWeight.bold), ),
        backgroundColor:Color(0xFFFF8B13),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                //본인 위치 입력
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: '본인 위치',
                    // contentPadding: EdgeInsets.symmetric(vertical: 20.0),
                    contentPadding: EdgeInsets.only(top: 20.0, bottom: 8.0),
                  ),
                  textInputAction: TextInputAction.next,
                  maxLines: null,
                  maxLength: 8,
                  onChanged: (value) => _checkMaxLength(_locationController, 8),
                  onFieldSubmitted: (value) => _currentChooseLocation(),
                ),

                // 본인 위치 지도로 설정 버튼
                ElevatedButton.icon(
                  onPressed: _currentChooseLocation, // 버튼 클릭 시 _chooseLocation 함수 호출
                  icon: Icon(Icons.location_on, color: Colors.white), // 위치 아이콘 추가
                  label: Text(
                    '본인 위치 설정',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // 텍스트 색상
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: currentLocationSet ? Colors.orange : Colors.grey, // 버튼 배경색
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0), // 버튼 모서리 둥글게
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // 버튼 내부 패딩
                  ),
                ),

                SizedBox(height: 8.0),

               //주문 시킬 가게 입력
                TextFormField(
                  controller: _storeController,
                  decoration: InputDecoration(
                    labelText: '주문 시킬 가게',
                    contentPadding: EdgeInsets.only(top: 20.0, bottom: 8.0),
                  ),
                  textInputAction: TextInputAction.next,
                  maxLines: null,
                  maxLength: 8,
                  onChanged: (value) => _checkMaxLength(_storeController, 8),
                  onFieldSubmitted: (value) => _storeChooseLocation(),
                ),

                //가게 위치 지도로 설정 버튼
                ElevatedButton.icon(
                  onPressed: _storeChooseLocation, // 버튼 클릭 시 _chooseLocation 함수 호출
                  icon: Icon(Icons.location_on, color: Colors.white), // 위치 아이콘 추가
                  label: Text(
                    '가게 위치 설정',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // 텍스트 색상
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    primary: storeLocationSet ? Colors.orange : Colors.grey, // 버튼 배경색
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0), // 버튼 모서리 둥글게
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), // 버튼 내부 패딩
                  ),
                ),

                SizedBox(height: 16.0),

                TextFormField(
                  controller: _costController,
                  decoration: InputDecoration(
                    labelText: '비용',
                    contentPadding: EdgeInsets.only(top: 20.0, bottom: 8.0),
                  ),
                  textInputAction: TextInputAction.next,
                  maxLines: null,
                  maxLength: 5,
                  onChanged: (value) => _checkMaxLength(_costController, 5),
                ),

                SizedBox(height: 16.0),

                TextFormField(
                  controller: _requestController,
                  decoration: InputDecoration(
                    labelText: '요청사항',
                    contentPadding: EdgeInsets.only(top: 20.0, bottom: 8.0),
                    alignLabelWithHint: true,
                  ),
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.done,
                  minLines: 7,
                  maxLines: null,
                  maxLength: 30,
                  onChanged: (value) => _checkMaxLength(_requestController, 30),
                  // onFieldSubmitted: (value) => _uploadPost(), // 요청사항 -> 게시하기
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


}
