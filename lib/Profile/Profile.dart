import 'package:OnTheWay/login/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../Alarm/Grade.dart';
import '../Board/UiBoard.dart';
import '../Chat/AllUsersScreen.dart';
import '../HanbatSchoolBoard/HanbatUiBoard.dart';
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
  int feedbackCount = 0;
  DateTime? lastFeedbackTime;
  int _selectedIndex = 4; // 기본 선택된 항목을 '프로필'으로 설정
  String botton_email = ""; // 사용자의 이메일을 저장할 변수
  String botton_domain = ""; // 사용자의 도메인을 저장할 변수


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
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                ),
              ),
              content: Text(
                '정말 해당 계정을 삭제 하시겠습니꽝? \n\n삭제 버튼을 누르시면\n계정의 정보가 모두 삭제됩니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              actions: [
                ElevatedButton(
                    onPressed: () {
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
  void _deleteAccount() {
    HapticFeedback.lightImpact();
    // 회원탈퇴 로직 추가 필요
    print('회원탈퇴');
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
              _buildGradeCard(userGrade),
              SizedBox(height: 40),
              _buildButton('로그아웃', _logout, Colors.indigo.shade300),
              _buildTextButton('개발자에게 하고 싶은 말', _showFeedbackDialog, Colors.blue), // 추가된 부분
              _buildTextButton('회원탈퇴', _checkNicknameAvailability, Colors.red),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_rounded, color: _selectedIndex == 0 ? Colors.indigo : Colors.black),
            label: '채팅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hourglass_empty_rounded,color: _selectedIndex == 1 ? Colors.indigo : Colors.black), //search
            label: '진행 상황',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined, color: _selectedIndex == 2 ? Colors.indigo : Colors.black),
            label: '게시판',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school, color: _selectedIndex == 3 ? Colors.indigo : Colors.black),
            label: '학교 랭킹',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: _selectedIndex == 4 ? Colors.indigo : Colors.black),
            label: '프로필',
          ),
        ],
        selectedLabelStyle: TextStyle(
          fontFamily: 'NanumSquareRound',
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'NanumSquareRound',
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        selectedItemColor: Colors.indigo,    // 선택된 항목의 텍스트 색상
        unselectedItemColor: Colors.black,  // 선택되지 않은 항목의 텍스트 색상

        currentIndex: _selectedIndex,

        onTap: (index) {
          if (_selectedIndex == index) {
            // 현재 선택된 탭을 다시 눌렀을 때 아무 동작도 하지 않음
            return;
          }

          setState(() {
            _selectedIndex = index;
          });

          // 채팅방으로 이동
          if (index == 0) {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AllUsersScreen()),
            );
          }
          //진행 상황
          else if (index == 1) {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PaymentStatusScreen()),
            );
          }

          //새 게시글 만드는 곳으로 이동
          else if (index == 2) {
            HapticFeedback.lightImpact();
            switch (botton_domain) {
              case 'naver.com':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HanbatBoardPage()),
                );
                break;
            // case 'hanbat.ac.kr':
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (context) => HanbaBoardPage()),
            //   );
            //   break;
              default:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BoardPage()),
                );
                break;
            }
          }


          // 학교 랭킹
          else if (index == 3) {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SchoolRankingScreen()),
            );
          }
          // 프로필
          else if (index == 4) {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserProfileScreen()),
            );
          }
        },
      ),

    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[200],
            child: user?.photoURL != null
                ? null
                : Icon(
              Icons.account_circle,
              size: 100,
              color: Colors.grey,
            ),
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
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
}
