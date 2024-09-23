import 'dart:io';

import 'package:OnTheWay/Profile/AccountInfoScreen.dart';
import 'package:OnTheWay/Profile/DeleteMember.dart';
import 'package:OnTheWay/Profile/DepartmentManager.dart';
import 'package:OnTheWay/login/LoginScreen.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../Alarm/AlarmUi.dart';
import '../Alarm/Grade.dart';

import '../Chat/AllUsersScreen.dart';
import '../Chat/FullScreenImage.dart';

import '../Progress/PaymentScreen.dart';
import '../Ranking/DepartmentRanking.dart';
import '../SchoolBoard/SchoolBoard.dart';
import 'SuggestionToAdminScreen.dart';

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  String? nickname;
  double? grade;
  String? department;
  String? bank;
  String? accountNumber;
  int feedbackCount = 0;
  DateTime? lastFeedbackTime;
  int _selectedIndex = 4; // 기본 선택된 항목을 '프로필'으로 설정
  String botton_email = ""; // 사용자의 이메일을 저장할 변수
  String botton_domain = ""; // 사용자의 도메인을 저장할 변수
  String collection_domain = "";

  //프로필 사진 이미지 변환
  File? _image;
  final picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Future<String?> _nickname;


  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    if (user != null) {
      _fetchUserNickname(user!.email);
    }
    botton_email = _auth.currentUser?.email ?? "";
    botton_domain = botton_email.split('@').last.toLowerCase();
    collection_domain = botton_domain.replaceAll('.','_');
    //닉네임 가져옴
    _nickname = getNickname();
  }


  //앱바 알림기능
  //userStatus에서 본인 nickname 찾기
  Future<String?> getNickname() async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: botton_email)
        .get();

    if (querySnapshot.docs.isNotEmpty){
      return querySnapshot.docs.first['nickname'];
    }
    return null;
  }

  // Firestore에서 messageCount 값을 실시간으로 가져오는 메서드
  Stream<DocumentSnapshot> getMessageCountStream(String nickname) {
    return FirebaseFirestore.instance
        .collection('userStatus')
        .doc(nickname)
        .snapshots();
  }

  //userStatus messageCount 값 초기화
  Future<void> resetMessageCount(String nickname) async {
    DocumentReference docRef = FirebaseFirestore.instance.collection('userStatus').doc(nickname);

    await docRef.set({'messageCount': 0}, SetOptions(merge: true));

  }


  Widget _buildMenuItem(BuildContext context, String title, String leadingIcon, {String? trailingIcon, bool isFirstItem = false}) {
    return Container(
      margin: isFirstItem
          ? EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.025)
          : EdgeInsets.fromLTRB(
        0,
        MediaQuery.of(context).size.height * 0.023,
        0,
        MediaQuery.of(context).size.height * 0.023,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.02),
                width: 20,
                height: 20,
                child: SvgPicture.asset(leadingIcon),
              ),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  height: 1,
                  letterSpacing: -0.4,
                  color: Color(0xFF222222),
                ),
              ),
            ],
          ),
          if (trailingIcon != null)
            Container(
              width: 20,
              height: 20,
              child: SvgPicture.asset(trailingIcon),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: Colors.grey, // 구분선 색상 설정
      // thickness: MediaQuery.of(context).size.height * 0.001, // 구분선 두께를 화면 높이에 비례하게 설정
      height: MediaQuery.of(context).size.height * 0.01, // 구분선과 항목 사이의 간격
    );
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
          department =  data['department'] ?? '';
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

  void logoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(
            left: MediaQuery.of(context).size.width * 0.03,
            right: MediaQuery.of(context).size.width * 0.03,
          ),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(
                    0,
                    MediaQuery.of(context).size.height * 0.04,
                    0,
                    MediaQuery.of(context).size.height * 0.025,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF1D4786),
                      borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.width * 0.15,
                      ),
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.2,
                      height: MediaQuery.of(context).size.width * 0.2,
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.1,
                        height: MediaQuery.of(context).size.width * 0.1,
                        child: SvgPicture.asset(
                          'assets/pigma/exit_white.svg',
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '정말 로그아웃을 하시겠어요?',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1,
                          letterSpacing: -0.4,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Divider(color: Colors.grey, height: 1),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _logout();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                        ),
                        child: Center(
                          child: Text(
                            '로그아웃',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF636666),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 0.5, // 구분선의 두께
                      height: 55, // 구분선의 높이
                      color: Colors.grey, // 구분선의 색상
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                        ),
                        child: Center(
                          child: Text(
                            '다음에',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1D4786),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }







  // 계정 삭제할지 물어보는 다이어로그
  void accountDeletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.only(
            left: MediaQuery.of(context).size.width * 0.03,
            right: MediaQuery.of(context).size.width * 0.03,
          ),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(
                    0,
                    MediaQuery.of(context).size.height * 0.04,
                    0,
                    MediaQuery.of(context).size.height * 0.025,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF1D4786),
                      borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.width * 0.15,
                      ),
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.2,
                      height: MediaQuery.of(context).size.width * 0.2,
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width * 0.05,
                      ),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.1,
                        height: MediaQuery.of(context).size.width * 0.1,
                        child: SvgPicture.asset(
                          'assets/pigma/exit_white.svg',
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '정말 해당 계정을 삭제하시겠어요?',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1,
                          letterSpacing: -0.4,
                          color: Color(0xFF222222),
                        ),
                      ),
                      TextSpan(
                        text: '\n\n⚠️탈퇴 시 정보가 모두 삭제됩니다.',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.normal, // 작은 글씨는 일반적인 가중치로 설정
                          fontSize: 14, // 작은 글씨 크기 설정
                          color: Colors.grey, // 회색으로 설정
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                Divider(color: Colors.grey, height: 1),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
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
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                        ),
                        child: Center(
                          child: Text(
                            '회원탈퇴',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF636666),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 0.5, // 구분선의 두께
                      height: 55, // 구분선의 높이
                      color: Colors.grey, // 구분선의 색상
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                        ),
                        child: Center(
                          child: Text(
                            '다음에',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1D4786),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //계정 삭제하는 함수
  Future<void> _deleteAccount() async {
    HapticFeedback.lightImpact();

    DeleteMember member = DeleteMember(botton_email ,nickname!, collection_domain); // 회원탈퇴 로직 추가 필요
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


  Widget _buildGradeCard(Grade? grade, String? nickname) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Color(0xFFE8EFF8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: grade?.border.top.color ?? Colors.black, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.person, color: Color(0xFF1D4786), size: 24.0), // 아이콘 추가
                SizedBox(width: 8.0), // 간격 추가
                Text(
                  '${nickname ?? "사용자"} 님의 평점',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF222222),
                  ),
                ),
              ],
            ),
            if (grade != null)
              Row(
                children: [
                  Container(
                    // decoration: BoxDecoration(
                    //   border: Border.all(color: grade.color2, width: 1.5),
                    //   borderRadius: BorderRadius.circular(5),
                    //   color: Color(0xFFE8EFF8),
                    // ),
                    child:
                    Container(
                      padding: EdgeInsets.fromLTRB(13, 2.5, 13, 2.5),
                      child: Row(
                        children: [
                          // Icon(Icons.school_outlined, color: grade.color),

                          Text(
                            '${grade.letterProfile}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: grade.color2,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(width: 7),
                          // Column(
                          //   children: [
                          //     SizedBox(height: 12),
                          Text(
                            '(${grade.value.toStringAsFixed(2)})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: grade.color2,
                              fontSize: 18,
                            ),
                          ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),
                  )
                ],
              )
            else
              Text(
                '설정되지 않음',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF888888),
                ),
              ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    Grade? userGrade = grade != null ? Grade(grade!) : null;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
        child: AppBar(
          title: Text(
            '프로필',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 19,
              height: 1.0,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          backgroundColor: Color(0xFF1D4786),
          elevation: 0,
          leading: SizedBox(), // 상단 왼쪽 빈 공간을 만들기 위해 빈 SizedBox를 사용
          actions: [
            Container(
              margin: EdgeInsets.only(right: 18.7), // 오른쪽 여백 설정
              child: Stack(
                alignment: Alignment.topRight,
                children: <Widget>[
                  FutureBuilder<String?>(
                    future: _nickname,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data == null) {
                        return IconButton(
                          icon: SvgPicture.asset(
                            'assets/pigma/notification_white.svg',
                            width: 24,
                            height: 24,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "아이디를 확인할 수 없습니다. \n다시 로그인 해주세요.",
                                  textAlign: TextAlign.center,
                                ),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        );
                      }

                      String ownerNickname = snapshot.data!;
                      return IconButton(
                        icon: SvgPicture.asset(
                          'assets/pigma/notification_white.svg',
                          width: 25,
                          height: 25,
                        ),
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await resetMessageCount(ownerNickname);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AlarmUi(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  FutureBuilder<String?>(
                    future: _nickname,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data == null) {
                        return Container();
                      }

                      String ownerNickname = snapshot.data!;
                      return StreamBuilder<DocumentSnapshot>(
                        stream: getMessageCountStream(ownerNickname),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return Container();
                          }
                          var data = snapshot.data!.data()
                          as Map<String, dynamic>;
                          int messageCount = data['messageCount'] ?? 0;

                          return Positioned(
                            right: 9,
                            top: 9,
                            child: messageCount > 0
                                ? Container(
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
                                '$messageCount',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            )
                                : Container(),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(
              0,
              0,
              0,
              MediaQuery.of(context).size.height * 0.04,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF1D4786),
              ),
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FutureBuilder<DocumentSnapshot>(
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
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _showProfileEditDeleteDialog(context, photoURL);
                                }, //이미지 선택
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF1D4786),
                                        Color(0xFF1D4786)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      (photoURL != null && photoURL.isNotEmpty)
                                          ? BoxShadow(
                                        color:
                                        Colors.black.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 1,
                                        offset: Offset(0, 1), // 그림자 위치 조정
                                      )
                                          : BoxShadow(),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.grey[200],
                                    child: photoURL != null && photoURL.isNotEmpty
                                        ? null
                                        : SvgPicture.asset(
                                      'assets/pigma/person_indigo.svg',
                                      width: 50,  // 필요한 크기로 조정합니다.
                                      height: 50,  // 필요한 크기로 조정합니다.
                                      // color: Colors.indigo,

                                    ),
                                    backgroundImage: photoURL != null &&
                                        photoURL.isNotEmpty
                                        ? NetworkImage(photoURL)
                                        : null
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(
                        0,
                        MediaQuery.of(context).size.height * 0.02,
                        1,
                        MediaQuery.of(context).size.height * 0.01,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.fromLTRB(0, 0, 0, 6),
                            child: Text(
                              '${nickname}',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                height: 1,
                                letterSpacing: -0.4,
                                color: Color(0xFFFFFFFF),
                              ),
                            ),
                          ),

                          Text(
                            '${user?.email}',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              height: 1,
                              letterSpacing: -0.4,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildGradeCard(userGrade, nickname)
                  ],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Container(
              margin: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width * 0.05,
                0,
                MediaQuery.of(context).size.width * 0.05,
                0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 알림 설정 Row
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountInfoScreen(
                            nickname: nickname ?? '재 로그인 해주세요.',
                            oldBank: bank ?? '재 로그인 해주세요.',
                            oldAccountNumber:
                            accountNumber ?? '재 로그인 해주세요.',
                          ),
                        ),
                      );
                    },
                    child: _buildMenuItem(
                      context,
                      '계좌정보',
                      'assets/pigma/bank.svg',
                      trailingIcon: 'assets/pigma/arrow.svg',
                      isFirstItem: true,
                    ),
                  ),
                  _buildDivider(context),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DepartmentManager(
                            nickname: nickname ?? '앱 종료 후 다시 시작해주세요.',
                            department: department ?? '앱 종료 후 다시 시작해주세요.',
                            email: botton_email ?? '재 로그인 해주세요.',
                          ),
                        ),
                      );
                    },
                    child: _buildMenuItem(
                      context,
                      '학과정보',
                      'assets/pigma/school_indigo.svg',
                      trailingIcon: 'assets/pigma/arrow.svg',
                    ),
                  ),
                  _buildDivider(context),



                  // 건의하기 Row
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SuggestionToAdminScreen(
                            nickname: nickname ?? '앱 종료 후 다시 시작해주세요.',
                            email: botton_email ?? '재 로그인 해주세요.',
                          ),
                        ),
                      );
                    },
                    child: _buildMenuItem(
                      context,
                      '건의하기',
                      'assets/pigma/chatbubbles_indigo.svg',
                      trailingIcon: 'assets/pigma/arrow.svg',
                    ),
                  ),
                  _buildDivider(context),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      logoutDialog(context);
                    },
                    child: _buildMenuItem(
                      context,
                      '로그아웃',
                      'assets/pigma/exit_indigo.svg',
                    ),
                  ),
                  _buildDivider(context),
                  // 회원탈퇴 Row
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      accountDeletionDialog(context);
                    },
                    child: _buildMenuItem(
                      context,
                      '회원탈퇴',
                      'assets/pigma/trash-bin_indigo.svg',
                    ),
                  ),
                  _buildDivider(context),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: Platform.isAndroid
            ? EdgeInsets.only(bottom: 8, top: 8)
            : const EdgeInsets.only(bottom: 30, top: 10),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BoardPage()),
                      );
                    }
                  },
                ),
                _buildBottomNavItem(
                  iconPath: 'assets/pigma/school.svg',
                  label: '학과랭킹',
                  isActive: _selectedIndex == 3,
                  onTap: () {
                    if (_selectedIndex != 3) {
                      setState(() {
                        _selectedIndex = 3;
                      });
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DepartmentRankingScreen()),
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
