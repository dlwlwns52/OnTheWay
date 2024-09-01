import 'dart:io';

import 'package:OnTheWay/Profile/DeleteMember.dart';
import 'package:OnTheWay/login/LoginScreen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../Alarm/Grade.dart';
import '../Board/UiBoard.dart';
import '../Chat/AllUsersScreen.dart';
import '../Chat/FullScreenImage.dart';
import '../HanbatSchoolBoard/HanbatSchoolBoard.dart';
import '../Pay/PaymentScreen.dart';
import '../Ranking/SchoolRanking.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  String? nickname;
  double? grade;
  String? bank;
  String? accountNumber;
  int feedbackCount = 0;
  DateTime? lastFeedbackTime;
  int _selectedIndex = 4; // 기본 선택된 항목을 '프로필'으로 설정
  String botton_email = ""; // 사용자의 이메일을 저장할 변수
  String botton_domain = ""; // 사용자의 도메인을 저장할 변수

  //프로필 사진 이미지 변환
  File? _image;
  final picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;



  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    if (user != null) {
      _fetchUserNickname(user!.email);
    }
    botton_email = _auth.currentUser?.email ?? "";
    botton_domain = botton_email.split('@').last.toLowerCase();

  }


  // 닉네임 가져옴
  Future<void> _fetchUserNickname(String? email) async {
    if (email == null) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          nickname = data['nickname'];
          bank = data['bank'];
          accountNumber = data['accountNumber'];
          grade = (data['grade'] as num).toDouble();
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }


  //로그아웃시 로그인창으로 이동
  Future<void> _logout() async {
    HapticFeedback.lightImpact();
    // 자동 로그인 지우기

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null)  // 사용자가 로그인되어 있지 않으면 함수 종료
        {
          final String? email = currentUser.email;

          final FirebaseFirestore firestore = FirebaseFirestore.instance;
          QuerySnapshot querySnapshot = await firestore.collection('users')
              .where('email', isEqualTo: email)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            // 해당 이메일을 가진 사용자 문서가 존재하는 경우
            DocumentSnapshot userDoc = querySnapshot.docs.first;
            // 해당 이메일을 가진 사용자 문서가 존재하는 경우
            String userId = userDoc.id;

            // // 해당 사용자 문서에 토큰을 저장합니다.
            await firestore.collection('users').doc(userId).set({
              'isAutoLogin': false,
              'token': FieldValue.delete(),
            }, SetOptions(merge: true));
          }
          else {
            print('No user found with email: $email');
          }

          // FirebaseAuth에서 로그아웃
          await FirebaseAuth.instance.signOut();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }



  // 개발자에게 건의사항 전송
  Future<void> _submitFeedback(String feedback) async {
    if (user != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(nickname);
      final userData = await userRef.get();

      int feedbackCount = userData.exists && userData.data()?.containsKey('feedbackCount') == true
          ? userData['feedbackCount']
          : 0;
      DateTime? lastFeedbackTime = userData.exists && userData.data()?.containsKey('lastFeedbackTime') == true
          ? (userData['lastFeedbackTime'] as Timestamp?)?.toDate()
          : null;

      if (lastFeedbackTime != null && DateTime.now().difference(lastFeedbackTime).inDays >= 1){
        feedbackCount = 0;
      }

      if (feedbackCount > 3){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('의견을 보내주셔서 대단히 감사합니다.\n건의사항은 하루에 최대 3번까지 \n접수할 수 있음을 알려드립니다.'
              , textAlign: TextAlign.center,),
            duration: Duration(seconds: 2),),
        );
        return; // 피드백 전송을 중단하고 함수 종료
      }

      // 피드백 카운트를 증가
      feedbackCount += 1;

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final documentName = '${nickname}_${user!.email}_$timestamp';

      await FirebaseFirestore.instance.collection('feedback').doc(documentName).set({
        'nickname': nickname,
        'email': user!.email,
        'feedback': feedback,
        'timestamp': DateTime.now(),
      });
      // 사용자 데이터에 피드백 카운트와 마지막 피드백 시간을 업데이트
      await userRef.update({
        'feedbackCount': feedbackCount,
        'lastFeedbackTime': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('소중한 의견을 주셔서 감사합니다. \n답변은 이메일로 보내드리겠습니다!'
          , textAlign: TextAlign.center,),
          duration: Duration(seconds: 2),
        ),
      );

    }
  }

  // 건의사항 다이어로그
  void _showFeedbackDialog() {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      barrierDismissible: false, // 바깥을 눌러도 다이어로그가 닫히지 않게 설정
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.feedback, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  '개발자에게 하고 싶은 말',
                  style: TextStyle(
                    fontFamily: 'NanumSquareRound',
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    color: Colors.indigo,
                  ),
                ),
                SizedBox(width: 8),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
            width: MediaQuery.of(context).size.width * 1, // 다이얼로그 너비 설정
              child: TextField(
              controller: feedbackController,
              maxLines: 7,
              decoration: InputDecoration(
                hintText: '건의사항을 입력해주세요.',
                hintStyle: TextStyle(
                  fontFamily: 'NanumSquareRound',
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: Colors.black45,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.indigo), // 포커스 시 색상 변경
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
            SizedBox(height: 15,),

            Text('※ 소중한 의견에 대한 답변은 이메일을 통해 보내드리도록 하겠습니다.',
              style: TextStyle(
                fontFamily: 'NanumSquareRound',
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.indigo,
                height: 1.5
              ),
            ),
          ],),

          actions: [
            ElevatedButton(
              onPressed: () {
                if (feedbackController.text.isNotEmpty) {
                  _submitFeedback(feedbackController.text);
                  Navigator.of(context).pop();
                }
                else{
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('건의사항을 입력해주세요.'
                      , textAlign: TextAlign.center,),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text('전송'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        );
      },
    );
  }



  // 계정 삭제할지 물어보는 다이어로그
  void _checkNicknameAvailability() async {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              title: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_outlined, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text(
                      '알림',
                      style: TextStyle(
                        fontFamily: 'NanumSquareRound',
                        fontWeight: FontWeight.w700,
                        fontSize: 25,
                        color: Colors.indigo,
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                ),
              ),
              content: Text(
                '정말 해당 계정을 삭제 하시겠습니까? \n\n삭제 버튼을 누르시면\n계정의 정보가 모두 삭제됩니다.',
                style: TextStyle(
                  fontFamily: 'NanumSquareRound',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "길게 누르시면 계정이 삭제 됩니다.",
                            textAlign: TextAlign.center,
                          ),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    onLongPress: () {
                      _deleteAccount();
                      Navigator.of(context).pop();
                    },
                    child: Text('삭제'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      shape: RoundedRectangleBorder(
                        borderRadius:  BorderRadius.circular(30)
                      )
                    )
                ),
                // SizedBox(width: 5,),

                ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('취소'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[400],
                        shape: RoundedRectangleBorder(
                        borderRadius:  BorderRadius.circular(30)
                        )
                    )
                ),
              ],
            );
          },
        );
  }

  //계정 삭제하는 함수
  Future<void> _deleteAccount() async {
    HapticFeedback.lightImpact();

    DeleteMember member = DeleteMember(botton_email ,nickname!); // 회원탈퇴 로직 추가 필요
    await member.deleteMember();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
    );

  }


  //바텀바 구조
  Widget _buildBottomNavItem({
    required String iconPath,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: isActive ? 26 : 24,
              height: isActive ? 26 : 24,
              color: isActive ? Colors.indigo : Colors.black,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                fontSize: isActive ? 14 : 12,
                color: isActive ? Colors.indigo : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }


  //사진고르기
  Future<void> _pickImage() async{
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File? croppedFile = await _cropImage(pickedFile.path);
      if (croppedFile != null) {
        setState(() {
          _image = croppedFile;
          _uploadImage();
        });
      }
    } else {
      print('No image selected.');
    }
  }


  Future<File?> _cropImage(String path) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
      cropStyle: CropStyle.circle,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '사진 자르기',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          hideBottomControls: true,
        ),
        IOSUiSettings(
          title: '사진 자르기',
        ),
      ],
    );
    return croppedFile != null ? File(croppedFile.path) : null;
  }

  //이미지 업로드
  Future<void> _uploadImage() async {
    if(_image == null)
      return;

    try{
      //파이어베이스 스토리지 업로드
      final storageRef = _storage.ref().child('profile_images/${nickname}.jpg');
      await storageRef.putFile(_image!);

      //이미지의 다운로드 url 가져오기
      final downloadURL = await storageRef.getDownloadURL();

      //파이어스토어에 url 저장
      await _firestore.collection('users').doc(nickname).update({
        'profilePhotoURL': downloadURL,
      });

      // 상태 업데이트
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '프로필 사진이 변경되었습니다.',
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 2),
        )
      );
    } catch (e) {
      print('Error occurred while uploading the image: $e');
    }
  }


  void _showProfileEditDeleteDialog(BuildContext context, String? photoURL) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFFFFFFFF),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 15, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(1, 0, 0, 43),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFE3E3E3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  width: 44,
                  height: 4,
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(0, 0, 0, 37),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // 수정 기능 호출
                        HapticFeedback.lightImpact();
                        if(photoURL!.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FullScreenImage(photoUrl: photoURL!),
                            ),
                          );
                        }
                        else{
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '기본 프로필 사진입니다.',
                                textAlign: TextAlign.center,
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color(0xFFFFFFFF),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0A000000),
                              offset: Offset(0, 4),
                              blurRadius: 7.5,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(1, 17, 0, 17),
                        child: Center(
                          child: Text(
                            '사진 보기',
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
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // 수정 기능 호출
                        HapticFeedback.lightImpact();
                        _pickImage();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color(0xFFFFFFFF),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0A000000),
                              offset: Offset(0, 4),
                              blurRadius: 7.5,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(1, 17, 0, 17),
                        child: Center(
                          child: Text(
                            '프로필 사진 변경',
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
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        // Firestore에서 photoURL을 null로 업데이트
                        await _firestore.collection('users').doc(nickname).update({
                          'profilePhotoURL': '',
                        });
                        Navigator.of(context).pop();
                        setState(() {});
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color(0xFFFFFFFF),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0A000000),
                              offset: Offset(0, 4),
                              blurRadius: 7.5,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(1, 17, 0, 17),
                        child: Center(
                          child: Text(
                            '프로필 사진 삭제',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              height: 1,
                              letterSpacing: -0.4,
                              color:Color(0xFF222222),
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop(); // 취소 버튼 클릭 시 모달 닫기
                      },
                      child: Container(
                        margin: EdgeInsets.only(top: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Color(0xFFFFFFFF),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0D000000),
                              offset: Offset(0, 4),
                              blurRadius: 7.5,
                            ),
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(1, 17, 0, 17),
                        child: Center(
                          child: Text(
                            '취소',
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
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildProfileHeader() {
    return FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('users').doc(nickname).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox.shrink(); // 아무것도 표시하지 않음
          }

          if (!snapshot.hasData) {
            return Text('No user data found');
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          var photoURL = userData['profilePhotoURL'] as String?;

          return Center(
            child: Column(
              children: [
                InkWell(
                  onTap: (){
                    HapticFeedback.lightImpact();
                    _showProfileEditDeleteDialog(context, photoURL);
                    }, //이미지 선택
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    child: photoURL != null  && photoURL.isNotEmpty
                        ? null
                        : Icon(Icons.account_circle, size: 100, color: Colors.indigo,),
                    backgroundImage: photoURL != null  && photoURL.isNotEmpty
                        ? NetworkImage(photoURL)
                        : null,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  nickname ?? '사용자 이름',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  user?.email ?? '이메일 없음',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
      );
  }



  Widget _buildProfileInfoCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value),
        leading: Icon(Icons.info_outline),
      ),
    );
  }

  Widget _buildProfileAccount(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(value),
          leading: Icon(Icons.account_balance_outlined),
          onTap: (){
            HapticFeedback.lightImpact();
            _updateBankAccountInfo();
          }
      ),
    );
  }

  void _updateBankAccountInfo() async {
    TextEditingController _bankController = TextEditingController();
    TextEditingController _accountNumberController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  '계좌 정보 수정',
                  style: TextStyle(
                    fontFamily: 'NanumSquareRound',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.indigo,
                  ),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _bankController,
                decoration: InputDecoration(
                  labelText: '은행명',
                  labelStyle: TextStyle(
                    fontFamily: 'NanumSquareRound',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(
                      color: Colors.indigo,
                    )
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _accountNumberController,
                decoration: InputDecoration(
                  labelText: '계좌번호',
                  labelStyle: TextStyle(
                    fontFamily: 'NanumSquareRound',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Colors.indigo,
                      )
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.lightImpact();
                String newBank = _bankController.text.trim();
                String newAccountNumber = _accountNumberController.text.trim();

                if (newBank.isNotEmpty && newAccountNumber.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(nickname) // Firestore에서 사용자 문서를 업데이트합니다.
                      .update({
                    'bank': newBank,
                    'accountNumber': newAccountNumber,
                  });

                  setState(() {
                    bank = newBank;
                    accountNumber = newAccountNumber;
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '계좌 정보가 성공적으로 업데이트되었습니다.',
                        textAlign: TextAlign.center,
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '모든 필드를 채워주세요.',
                        textAlign: TextAlign.center,
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text('수정'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
              child: Text('취소'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildGradeCard(Grade? grade) {
    if (grade == null) {
      return _buildProfileInfoCard('성적', '설정되지 않음');
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: grade.border.top.color, width: grade.border.top.width),
      ),
      child: ListTile(
        title: Text(
          '성적',
          style: TextStyle(color: grade.color2, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${grade.letter} :   ${grade.value.toStringAsFixed(2)}',
        style: TextStyle(color: grade.color2) ,),
        leading: Icon(Icons.grade, color: grade.color2),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton(String text, VoidCallback onPressed, Color color) {
    return Container(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 15,
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    Grade? userGrade = grade != null ? Grade(grade!) : null;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading : false, // '<' 이 뒤로가기 버튼 삭제
        title: Text('프로필', style:
        TextStyle(color: Colors.black, fontSize: 25, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        centerTitle: true,
      ),


      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(),
              SizedBox(height: 20),
              _buildProfileInfoCard('닉네임', nickname ?? '설정되지 않음'),
              _buildProfileInfoCard('이메일', user?.email ?? '설정되지 않음'),
              _buildProfileAccount('${bank}', accountNumber ?? '설정되지 않음'),
              _buildGradeCard(userGrade),
              SizedBox(height: 40),
              _buildButton('로그아웃', _logout, Colors.indigo.shade300),
              _buildTextButton('개발자에게 하고 싶은 말', _showFeedbackDialog, Colors.blue), // 추가된 부분
              _buildTextButton('회원탈퇴', _checkNicknameAvailability, Colors.red),
            ],
          ),
        ),
      ),


      bottomNavigationBar: Padding(
        padding: Platform.isAndroid ?  EdgeInsets.only(bottom: 8, top: 8): const EdgeInsets.only(bottom: 30, top: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(
                  iconPath: 'assets/pigma/chatbubbles.svg',
                  label: '채팅',
                  isActive: _selectedIndex == 0,
                  onTap: () {
                    if (_selectedIndex != 0) {
                      setState(() {
                        _selectedIndex = 0;
                      });
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AllUsersScreen()),
                      );
                    }
                  },
                ),
                _buildBottomNavItem(
                  iconPath: 'assets/pigma/footsteps.svg',
                  label: '진행상황',
                  isActive: _selectedIndex == 1,
                  onTap: () {
                    if (_selectedIndex != 1) {
                      setState(() {
                        _selectedIndex = 1;
                      });
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PaymentStatusScreen()),
                      );
                    }
                  },
                ),
                _buildBottomNavItem(
                  iconPath: 'assets/pigma/book.svg',
                  label: '게시판',
                  isActive: _selectedIndex == 2,
                  onTap: () {
                    if (_selectedIndex != 2) {
                      setState(() {
                        _selectedIndex = 2;
                      });
                      HapticFeedback.lightImpact();
                      switch (botton_domain) {
                        case 'naver.com':
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HanbatBoardPage()),
                          );
                          break;
                        default:
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => BoardPage()),
                          );
                          break;
                      }
                    }
                  },
                ),
                _buildBottomNavItem(
                  iconPath: 'assets/pigma/school.svg',
                  label: '학교랭킹',
                  isActive: _selectedIndex == 3,
                  onTap: () {
                    if (_selectedIndex != 3) {
                      setState(() {
                        _selectedIndex = 3;
                      });
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SchoolRankingScreen()),
                      );
                    }
                  },
                ),
                _buildBottomNavItem(
                  iconPath: 'assets/pigma/person.svg',
                  label: '프로필',
                  isActive: _selectedIndex == 4,
                  onTap: () {
                    if (_selectedIndex != 4) {
                      setState(() {
                        _selectedIndex = 4;
                      });
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserProfileScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),

    );
  }
}
