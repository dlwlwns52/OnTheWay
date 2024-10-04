import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import '../Alarm/AlarmUi.dart';

import '../Chat/AllUsersScreen.dart';

import '../Chat/FullScreenImage.dart';
import '../Progress/PaymentScreen.dart';
import '../Profile/Profile.dart';
import '../SchoolBoard/SchoolBoard.dart';

class ReportManagementScreen extends StatefulWidget {
  @override
  _ReportManagementScreenState createState() => _ReportManagementScreenState();
}

class _ReportManagementScreenState extends State<ReportManagementScreen> {

  String botton_email = ""; // 사용자의 이메일을 저장할 변수
  String botton_domain = ""; // 사용자의 도메인을 저장할 변수

  //닉네임 가져오기
  late Future<String?> _nickname;

  @override
  void initState() {
    super.initState();
    // updateSchoolLogos(); // 초기 로고 업데이트 호출

    final FirebaseAuth _auth = FirebaseAuth.instance;
    botton_email = _auth.currentUser?.email ?? "";
    botton_domain = botton_email.split('@').last.toLowerCase();

  }


  //앱바 알림기능
  //userStatus에서 본인 nickname 찾기
  Future<String?> _getNickname(String nickname) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: botton_email)
        .get();

    if (querySnapshot.docs.isNotEmpty){
      return querySnapshot.docs.first['nickname'];
    }
    return null;
  }


  //포르필 사진 기능
  Future<String?> _getProfileImage(String email) async{
    FirebaseFirestore db = FirebaseFirestore.instance;
    QuerySnapshot nicknameSnapshot = await db
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if(nicknameSnapshot.docs.isNotEmpty){
      DocumentSnapshot document = nicknameSnapshot.docs.first;
      String? profilePhotoURL = document.get('profilePhotoURL');
      return profilePhotoURL;
    }

    else {
      print("해당 이메일을 가진 사용자가 없습니다.");
      return null;
    }
  }



  // 차단 내역
  Future<List<Map<String, dynamic>>> getBlockedUsers(String userNickname) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')  // 'users' 컬렉션
        .doc(userNickname)    // 해당 사용자의 닉네임 문서
        .collection('blacklist')  // 'blacklist' 하위 컬렉션
        .where('target', isEqualTo: true)  // 'target' 필드가 true인 문서만 필터링
        .get();

    return querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }


  // 차단 해제
  Future<void> deleteBlockerUser(String userNickname, String blockedNickname) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')  // 'users' 컬렉션
        .doc(userNickname)    // 해당 사용자의 닉네임 문서
        .collection('blacklist')  // 'blacklist' 하위 컬렉션
        .where('target', isEqualTo: true)  // 'target' 필드가 true인 문서만 필터링
        .where('blockedNickname', isEqualTo: blockedNickname)  // blockedNickname 필터링 추가
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // 첫 번째로 일치하는 문서 가져오기
      DocumentSnapshot document = querySnapshot.docs.first;

      // 문서 삭제
      await document.reference.delete();
      print("차단 해제 완료: $blockedNickname");
    } else {
      print("해당 닉네임을 가진 사용자가 없습니다.");
    }
  }

  Future<void> deleteBlockedUser(String userNickname, String blockedNickname) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')  // 'users' 컬렉션
        .doc(blockedNickname)    // 해당 사용자의 닉네임 문서
        .collection('blacklist')  // 'blacklist' 하위 컬렉션
        .where('target', isEqualTo: false)  // 'target' 필드가 true인 문서만 필터링
        .where('blockerNickname', isEqualTo: userNickname)  // blockedNickname 필터링 추가
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // 첫 번째로 일치하는 문서 가져오기
      DocumentSnapshot document = querySnapshot.docs.first;

      // 문서 삭제
      await document.reference.delete();
      print("차단 해제 완료: $userNickname");
    } else {
      print("해당 닉네임을 가진 사용자가 없습니다.");
    }
  }





  //사용자 차단 해제하는 다이어로그
  void _unblockUserDialog(BuildContext context, String userNickname, String blockedNickname) {
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
                        // 차단하기 기능 호출
                        HapticFeedback.lightImpact();
                        deleteBlockerUser(userNickname, blockedNickname);
                        deleteBlockedUser(userNickname, blockedNickname);
                        Navigator.of(context).pop(); // 취소 버튼 클릭 시 모달 닫기
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "${blockedNickname} 님의 차단이 해제되었습니다",
                              textAlign: TextAlign.center,
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        setState(() {});

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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_open, // 차단하기에 알맞은 블록 아이콘
                                color: Color(0xFF1D4786),
                              ),
                              SizedBox(width: 5), // 아이콘과 텍스트 사이 간격
                              Text(
                                '차단해제',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                  height: 1,
                                  letterSpacing: -0.4,
                                  color: Color(0xFF1D4786),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
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





  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
        child: AppBar(
          title: Text(
            '차단관리',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 19,
              height: 1.0,
              // letterSpacing: -0.5,
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
          actions: [
          ],
        ),
      ),



        body: FutureBuilder(
          future: _getNickname(botton_email),
          builder: (context, nicknameSnapshot) {
            if (nicknameSnapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator(); // 닉네임 로딩 중
            } else if (nicknameSnapshot.hasError) {
              return Text("Error: ${nicknameSnapshot.error}");
            } else if (!nicknameSnapshot.hasData || nicknameSnapshot.data == null) {
              return Text('닉네임을 찾을 수 없습니다.');
            }

            String? UserNickName = nicknameSnapshot.data;

            // 차단된 사용자 목록 가져오기
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: getBlockedUsers(UserNickName!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '오류가 발생했습니다: ${snapshot.error}',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Container(
                      width: 300,
                      height: 200,
                      child: Text(
                        '차단한 사용자가 없습니다.\n 차단된 사용자는 이곳에서 관리할 수 있습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'NanumSquareRound',
                          color: Color(0xFF1D4786),
                        ),
                      ),
                    ),
                  );
                }

                List<Map<String, dynamic>> getBlackList = snapshot.data!;

                // 차단된 사용자 목록 가져오기
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      screenWidth * 0.05,
                      screenHeight * 0.01,
                      screenWidth * 0.05,
                      0,
                    ),
                    child: ListView.builder(
                      itemCount: getBlackList.length,
                      itemBuilder: (context, index) {
                        var blackUser = getBlackList[index];

                        return FutureBuilder<String?>(
                          future: _getProfileImage(blackUser['blockedEmail']),
                          builder: (context, urlSnapshot) {
                            if (urlSnapshot.connectionState == ConnectionState.waiting) {
                              return CircularProgressIndicator(); // 이미지 로딩 중
                            } else if (urlSnapshot.hasError) {
                              return Text("Error: ${urlSnapshot.error}");
                            } else if (!urlSnapshot.hasData || urlSnapshot.data == null) {
                              return Text('이미지를 찾을 수 없습니다.');
                            }

                            String? profileImageUrl = urlSnapshot.data;

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Color(0xFFEEEEEE),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            0,
                                            screenHeight * 0.025,
                                            0,
                                            screenHeight * 0.025,
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  HapticFeedback.lightImpact();
                                                  if (profileImageUrl!.isNotEmpty) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => FullScreenImage(
                                                          photoUrl: profileImageUrl,
                                                        ),
                                                      ),
                                                    );
                                                  } else {
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
                                                  margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
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
                                                        (profileImageUrl != null &&
                                                            profileImageUrl.isNotEmpty)
                                                            ? BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.1),
                                                          spreadRadius: 1,
                                                          blurRadius: 1,
                                                          offset: Offset(0, 1),
                                                        )
                                                            : BoxShadow(),
                                                      ],
                                                    ),
                                                    child: CircleAvatar(
                                                      radius: 25,
                                                      backgroundColor: Colors.grey[200],
                                                      child: (profileImageUrl != null &&
                                                          profileImageUrl.isNotEmpty)
                                                          ? null
                                                          : Icon(
                                                        Icons.account_circle,
                                                        size: 50,
                                                        color: Color(0xFF1D4786),
                                                      ),
                                                      backgroundImage: profileImageUrl != null &&
                                                          profileImageUrl.isNotEmpty
                                                          ? NetworkImage(profileImageUrl)
                                                          : null,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                                Container(
                                                margin: EdgeInsets.fromLTRB(
                                                    MediaQuery.of(context).size.width * 0.02,
                                                    0,
                                                    0,
                                                    0
                                                ),
                                                   child: Text(
                                                      '${blackUser['blockedNickname']}',
                                                      style: TextStyle(
                                                        fontFamily: 'Pretendard',
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 18,
                                                        height: 1,
                                                        letterSpacing: -0.5,
                                                        color: Color(0xFF222222),
                                                      ),
                                                    ),
                                                ),
                                              Spacer(),


                                              OutlinedButton(
                                                onPressed: () {
                                                  // 버튼 클릭 시 실행할 동작
                                                  HapticFeedback.lightImpact();
                                                  _unblockUserDialog(context,UserNickName, blackUser['blockedNickname']);
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(color: Color(0xFF1D4786), width: 1.5), // 테두리 색상과 두께
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(30), // 둥근 테두리 반지름
                                                  ),
                                                  padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10), // 패딩 조정
                                                ),
                                                child: Text(
                                                  '관리',
                                                  style: TextStyle(
                                                    color: Color(0xFF1D4786), // 텍스트 색상
                                                    fontWeight: FontWeight.bold, // 텍스트 굵기
                                                  ),
                                                ),
                                              )


                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        )

    );}
}
