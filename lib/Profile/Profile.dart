import 'package:OnTheWay/login/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../Alarm/Grade.dart';

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


  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    if (user != null) {
      _fetchUserNickname(user!.email);
    }
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
  void _logout() {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  // 개발자에게 건의사항 전송
  Future<void> _submitFeedback(String feedback) async {
    if (user != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final documentName = '${nickname}_${user!.email}_$timestamp';

      await FirebaseFirestore.instance.collection('feedback').doc(documentName).set({
        'nickname': nickname,
        'email': user!.email,
        'feedback': feedback,
        'timestamp': DateTime.now(),
      });
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('소중한 의견을 주셔서 감사합니다. \n답변은 이메일로 보내드리겠습니다!'
                      , textAlign: TextAlign.center,),
                      duration: Duration(seconds: 2),
                    ),
                  );
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
