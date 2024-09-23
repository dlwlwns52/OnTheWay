import 'dart:io';


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';

import '../Map/WriteMap/CurrentMapScreen.dart';
import '../Map/WriteMap/StoreMapScreen.dart';
import 'SchoolBoard.dart';

class HanbatNewPostScreen extends StatefulWidget {
  final DocumentSnapshot? post;

  HanbatNewPostScreen({this.post});

  @override
  _HanbatNewPostScreenState createState() => _HanbatNewPostScreenState();
}

class _HanbatNewPostScreenState extends State<HanbatNewPostScreen> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _storeController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _requestController = TextEditingController();
  final FocusNode _buttonFocusNode = FocusNode();


  //위치 관련 변수
  String? _storeSelectedLocation;
  String? _currentSelectedLocation; //위치 저장
  bool currentLocationSet = false; //버튼 활성화
  bool storeLocationSet = false;
  bool _storeHasText = false;
  bool _currentHasText = false;
  bool _costHasText = false;
  bool _requestHasText = false;

  //스낵바가 이미 표시되었는지를 추적하는 플래그
  bool _snackBarShown = false;
  bool _isUploading = false;

  // 게시하기 색상 변경
  bool _helpButtonColor = false;

  String botton_domain = ""; // 사용자의 도메인을 저장할 변수
  String collection_domain = "";


  @override
  void initState() {
    super.initState();

    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    botton_domain = currentUserEmail.split('@').last.toLowerCase();
    collection_domain = botton_domain.replaceAll('.','_');



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

    // 보더 색상 변환 -> 텍스트 있으면 indigo ddjqtdmaus grey
    _storeHasText = _storeController.text.isNotEmpty;
    _currentHasText = _locationController.text.isNotEmpty;
    _costHasText = _costController.text.isNotEmpty;
    _requestHasText = _requestController.text.isNotEmpty;

    // 보더 색상 변환 리스너 추가
    _storeController.addListener(() {
      setState(() {
        _storeHasText = _storeController.text.isNotEmpty;
      });
    });

    _locationController.addListener(() {
      setState(() {
        _currentHasText = _locationController.text.isNotEmpty;
      });
    });

    _costController.addListener(() {
      setState(() {
        _costHasText = _costController.text.isNotEmpty;
      });
    });

    _requestController.addListener(() {
      setState(() {
        _requestHasText = _requestController.text.isNotEmpty;
      });
    });

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
            '최대 ${maxLength}글자까지 입력해 주시고 \n상세내용은 채팅방을 이용하시길 권장드립니다.',
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 2),
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
    HapticFeedback.lightImpact();
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
    HapticFeedback.lightImpact();
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


  //비용 숫자로 작성하게 하기
  bool _isValidCost(String value) {
    return RegExp(r'(\d.*?){3,}').hasMatch(value);
  }



  String? getUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? user.email : '이메일 없음';
  }

  Future<void> _uploadPost() async {
    HapticFeedback.lightImpact();

    if (_storeController.text.isEmpty) {
      _showSnackBar("\'픽업 장소(가게 위치)\'를 입력해주세요.");
      return;
    }

    if (_locationController.text.isEmpty) {
      _showSnackBar("\'드랍 장소(본인 위치)\'를 입력해주세요.");
      return;
    }


    if (_costController.text.isEmpty) {
      _showSnackBar("\'금액\' 칸을 입력해주세요.");
      return;
    }

    // 비용이 올바르지 않은 경우 업로드 중단
    if (!_isValidCost(_costController.text)) {
      _showSnackBar('가격은 숫자로만 입력해주세요. ex) 2000원 o, 이천원 x');
      return;
    }

    if (_requestController.text.isEmpty) {
      _showSnackBar("\'요청 사항\' 칸을 입력해주세요.");
      return;
    }

    if(currentLocationSet == false){
      _showSnackBar("\'픽업 위치 찾기\' 을 완료해주세요.");
      return;
    }

    if(storeLocationSet == false){
      _showSnackBar("\'드랍 위치 찾기\' 을 완료해주세요.");
      return;
    }

    try {
      FirebaseFirestore db = FirebaseFirestore.instance;
      String? email = getUserEmail();
      String? nickname;

      QuerySnapshot existingPosts = await db
          .collection(collection_domain)
          .where('my_location', isEqualTo: _locationController.text)
          .where('email', isEqualTo: email)
          .get();

      QuerySnapshot nicknameSnapshot = await db
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      // 문서가 하나 이상 반환되었을 때만 접근
      if (nicknameSnapshot.docs.isNotEmpty) {
        // 첫 번째 문서에 접근 (여기서는 이메일이 유일하다고 가정)
        DocumentSnapshot documentSnapshot = nicknameSnapshot.docs.first;

        // 'nickname' 필드 값 가져오기
        nickname = documentSnapshot['nickname'];

      } else {
        print('No user found with the given email.');
      }



      if (existingPosts.docs.isNotEmpty && widget.post == null) {
        _showSnackBar('동일한 제목의 게시물이 이미 존재합니다.');
      } else {
        String documentName = widget.post?.id ?? "${_locationController.text}_${email ?? 'unknown'}";
        await db.collection(collection_domain).doc(documentName).set({
          'nickname' : nickname,
          'store_location' :_storeSelectedLocation ?? '가게 위치 미설정',
          'current_location' : _currentSelectedLocation ?? '현재 위치 미설정',
          'my_location': _locationController.text,
          'store': _storeController.text,
          'cost': _costController.text,
          'email': email,
          'Request': _requestController.text,
          'date': DateTime.now(),
        });


        //check 애니메이션
        setState(() {
          _isUploading = true;
        });


        Future.delayed(Duration(seconds: 2), () {
          Navigator.of(context).push( // 새 화면으로 이동하는 Flutter 내비게이션 함수 호출
            MaterialPageRoute(
              builder: (context) => BoardPage(),
            ),
          );

          setState(() {
            _isUploading = false;
          });


          _showSnackBar("게시물이 업로드 되었습니다.");
        });



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
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
            child: AppBar(
            title: Text(
              '게시글 작성',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 19,
                height: 1.0,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),

            centerTitle: true,
            backgroundColor: Color(0xFF1D4786),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_outlined), // '<' 모양의 뒤로가기 버튼 아이콘
              color: Colors.white, // 아이콘 색상
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context); // 뒤로가기 기능
              },
            ),
            // 상단 왼쪽 빈 공간을 만들기 위해 빈 SizedBox를 사용
            actions: [

            ],
          ),
      ),

        body: GestureDetector(
          onTap: () {
            // 화면의 다른 부분을 터치했을 때 포커스 해제
            FocusScope.of(context).unfocus();
          },
          child: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  child:Center(
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(20, 0, 20, 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 20),
                              Container(
                                margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          '픽업 장소',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            height: 1,
                                            letterSpacing: -0.4,
                                            color: Color(0xFF424242),
                                          ),
                                        ),
                                      ),
                                    ),


                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFFFFFF),
                                      ),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: TextFormField(
                                          controller: _storeController,
                                          textInputAction: TextInputAction.next,
                                          maxLines: 1,
                                          maxLength: 10,
                                          onChanged: (value) => _checkMaxLength(_storeController, 10),
                                          onFieldSubmitted: (value) => _storeChooseLocation(),
                                          cursorColor: Color(0xFF1D4786),
                                          decoration: InputDecoration(
                                            hintText: '픽업 장소를 입력해주세요.',
                                            hintStyle: TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 17,
                                              height: 1,
                                              letterSpacing: -0.4,
                                              color: Color(0xFF767676),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color: _storeHasText ? Colors.indigo : Color(0xFFD0D0D0),
                                              ), // 텍스트가 있으면 인디고, 없으면 회색
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.indigo), // 포커스 시 색상 변경
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            counterText: '', // 이 부분이 하단의 '0/10' 텍스트를 숨깁니다.
                                          ),
                                        ),
                                      ),
                                    ),




                                    InkWell(
                                      onTap: (){
                                        _storeChooseLocation();
                                      },
                                      child:
                                      Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: storeLocationSet ? Colors.indigo : Color(0xFFD0D0D0)),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Color(0xFFFFFFFF),
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.fromLTRB(0, 13, 0, 13),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 26,
                                              height: 26,
                                              child: SvgPicture.asset(
                                                'assets/pigma/write_locate.svg',
                                              ),
                                            ),
                                            SizedBox(
                                              width:5,
                                            ),
                                            Container(
                                              margin: EdgeInsets.fromLTRB(0, 4, 0, 4),
                                              child: Text(
                                                storeLocationSet ? '픽업 위치 완료' : '픽업 위치 찾기',
                                                style: TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 17,
                                                  height: 1,
                                                  letterSpacing: -0.4,
                                                  color: Color(0xFF222222),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),


                            Container(
                              margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child:
                                      RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '드랍 장소',
                                                style: TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  height: 1,
                                                  letterSpacing: -0.4,
                                                  color: Color(0xFF424242),
                                                ),
                                            ),
                                            TextSpan(
                                              text: '   ⚠️ 민감한 세부 정보는 채팅을 이용해주세요',
                                              style: TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontWeight: FontWeight.normal, // 작은 글씨는 일반적인 가중치로 설정
                                                fontSize: 13, // 작은 글씨 크기 설정
                                                color: Colors.grey, // 회색으로 설정
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),



                                  Container(
                                    margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFFFFFF),
                                    ),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: TextFormField(
                                        controller: _locationController,
                                        textInputAction: TextInputAction.next,
                                        maxLines: 1,
                                        maxLength: 10,
                                        onChanged: (value) => _checkMaxLength(_locationController, 10),
                                        onFieldSubmitted: (value) => _currentChooseLocation(),
                                        cursorColor: Color(0xFF1D4786),
                                        decoration: InputDecoration(
                                          hintText: '드랍 장소를 입력해주세요.',
                                          hintStyle: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 17,
                                            height: 1,
                                            letterSpacing: -0.4,
                                            color: Color(0xFF767676),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: _currentHasText ? Colors.indigo : Color(0xFFD0D0D0),
                                            ), // 텍스트가 있으면 인디고, 없으면 회색
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.indigo), // 포커스 시 색상 변경
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          counterText: '', // 이 부분이 하단의 '0/10' 텍스트를 숨깁니다.
                                        ),
                                      ),
                                    ),
                                  ),




                                  InkWell(
                                    onTap: (){
                                      _currentChooseLocation();
                                    },
                                    child:
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: currentLocationSet ? Colors.indigo : Color(0xFFD0D0D0)),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Color(0xFFFFFFFF),
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.fromLTRB(0, 13, 0, 13),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 26,
                                              height: 26,
                                              child: SvgPicture.asset(
                                                'assets/pigma/write_locate.svg',
                                              ),
                                            ),
                                            SizedBox(
                                              width:5,
                                            ),
                                            Container(
                                              margin: EdgeInsets.fromLTRB(0, 4, 0, 4),
                                              child: Text(
                                                currentLocationSet ? '드랍 위치 완료' : '드랍 위치 찾기',
                                                style: TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 17,
                                                  height: 1,
                                                  letterSpacing: -0.4,
                                                  color: Color(0xFF222222),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),


                            Container(
                              margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        '금액',
                                        style: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          height: 1,
                                          letterSpacing: -0.4,
                                          color: Color(0xFF424242),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFFFFFF),
                                    ),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: TextFormField(
                                        controller: _costController,
                                        textInputAction: TextInputAction.next,
                                        maxLines: 1,
                                        maxLength: 10,
                                        onChanged: (value) => _checkMaxLength(_costController, 10),
                                        cursorColor: Color(0xFF1D4786),
                                        decoration: InputDecoration(
                                          hintText: '헬퍼비를 입력해주세요.',
                                          hintStyle: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 17,
                                            height: 1,
                                            letterSpacing: -0.4,
                                            color: Color(0xFF767676),
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: _costHasText ? Colors.indigo : Color(0xFFD0D0D0),
                                            ), // 텍스트가 있으면 인디고, 없으면 회색
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(color: Colors.indigo), // 포커스 시 색상 변경
                                            borderRadius: BorderRadius.circular(8),
                                          ),

                                          errorText: !_isValidCost(_costController.text) && _costHasText
                                              ? '가격은 숫자로만 입력해주세요. ex) 이천원 x, 2000원 o'
                                              : null,
                                          counterText: '', // 이 부분이 하단의 '0/10' 텍스트를 숨깁니다.
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),


                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      '요청사항',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        height: 1,
                                        letterSpacing: -0.4,
                                        color: Color(0xFF424242),
                                      ),
                                    ),
                                  ),
                                ),




                                Container(
                                  width: double.infinity,
                                  height: MediaQuery.of(context).size.width * 0.32,
                                  margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFFFFFF),
                                  ),
                                  child: TextFormField(
                                      controller: _requestController,
                                      textInputAction: TextInputAction.done,
                                      expands: true,
                                      maxLines: null, // 여러 줄 입력 가능
                                      minLines: null, // 줄 수 제한을 제거항
                                      cursorColor: Color(0xFF1D4786),
                                      onChanged: (value) => _checkMaxLength(_requestController, 50),
                                      decoration: InputDecoration(
                                        hintText: '요청사항을 입력해주세요. \n(민감한 세부 정보는 채팅을 이용해주세요.)',
                                        hintStyle: TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 16,
                                          height: 1.4,
                                          letterSpacing: -0.4,
                                          color: Color(0xFF767676),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: _requestHasText ? Colors.indigo : Color(0xFFD0D0D0),
                                          ), // 텍스트가 있으면 인디고, 없으면 회색
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(color: Colors.indigo), // 포커스 시 색상 변경
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
               ),
             ),
              if (_isUploading)
                Container(
                  color: Colors.grey.withOpacity(0.5),
                  child: Center(
                    child: Lottie.asset(
                      'assets/lottie/check_indigo.json',
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain
                      ,
                    ),
                  ),
                ),
              ],
            ),
      ),

        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: Platform.isAndroid ? MediaQuery.of(context).size.width * 0.15 : MediaQuery.of(context).size.width * 0.20,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _uploadPost();
                },
                style: ElevatedButton.styleFrom(
                  primary: Color(0xFF1D4786), // 배경색
                  onPrimary: Colors.white, // 텍스트 색상
                  padding: EdgeInsets.symmetric(vertical: 13), // 내부 패딩 (높이 조정)
                  minimumSize: Size(double.infinity, kBottomNavigationBarHeight), // 버튼 크기 설정
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // 둥근 모서리를 제거하고 직사각형 모양으로 설정
                    side: BorderSide(color: Color(0xFF1D4786)), // 테두리 색상 설정
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center, // 아이콘과 텍스트를 중앙 정렬
                  children: [
                    Icon(
                      Icons.send, // 원하는 아이콘 선택
                      size: 24, // 아이콘 크기
                      color: Colors.white, // 아이콘 색상
                    ),
                    SizedBox(width: 13), // 아이콘과 텍스트 사이 간격
                    Text(
                      '게시하기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        fontSize: 21,
                        height: 1,
                        letterSpacing: -0.5,
                        color: Colors.white, // 텍스트 색상
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
