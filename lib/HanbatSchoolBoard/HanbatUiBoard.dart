import 'dart:async';

import 'package:OnTheWay/Chat/AllUsersScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // 플러터의 머티리얼 디자인 위젯을 사용하기 위한 임포트입니다.
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 데이터베이스를 사용하기 위한 임포트입니다.
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../Alarm/AlarmUi.dart';

import '../Board/UiBoard.dart';
import '../Pay/PaymentScreen.dart';
import '../Profile/Profile.dart';
import '../Ranking/SchoolRanking.dart';
import 'HanbatWriteBoard.dart';
import 'HanbatPostManager.dart';
import '../Alarm/Alarm.dart';
import 'package:OnTheWay/Map/PostMap/PostStoreMap.dart';
import 'package:OnTheWay/Map/PostMap/PostCurrentMap.dart';
import 'dart:io' show Platform;
import 'package:lottie/lottie.dart';

// BoardPage 클래스는 게시판 화면의 상태를 관리하는 StatefulWidget 입니다.
class HanbatBoardPage extends StatefulWidget {
  @override
  _HanbatBoardPageState createState() => _HanbatBoardPageState(); // 상태(State) 객체를 생성합니다.
}

// _BoardPageState 클래스는 BoardPage의 상태를 관리합니다.
class _HanbatBoardPageState extends State<HanbatBoardPage> {
  // Firestore 인스턴스를 생성하여 데이터베이스에 접근할 수락 있게 합니다.
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  // PostManager 인스턴스 생성
  final postManager = HanbatPostManager();

  // NaverAlarm 인스턴스를 생성합니다.
  late Alarm alarm;

  // 도와주기시 애니메이션 클릭
  bool _pushHelp = false;

  // 바텀 네비게이션 인덱스
  int _selectedIndex = 2; // 기본 선택된 항목을 '게시판'으로 설정
  String botton_email = ""; // 사용자의 이메일을 저장할 변수
  String botton_domain = ""; // 사용자의 도메인을 저장할 변수

  //닉네임 가져오기
  late Future<String?> _nickname;

  @override
  void initState() {
    super.initState();
    alarm = Alarm(FirebaseAuth.instance.currentUser?.email ?? '', () => setState(() {}), context,);

    // 로그인 시 설정된 이메일 및 도메인 가져오기 -> 바텀 네비게이션 이용시 사용
    final FirebaseAuth _auth = FirebaseAuth.instance;
    botton_email = _auth.currentUser?.email ?? "";
    botton_domain = botton_email.split('@').last.toLowerCase();

    //닉네임 가져옴
    _nickname = getNickname();

  }



  void _pushHelpButton(bool value) {
    setState(() {
      _pushHelp = value;
    });
  }

  // Firestore의 'posts' 컬렉션으로부터 게시글 목록을 스트림 형태로 불러오는 함수입니다.
  Stream<List<DocumentSnapshot>> getPosts() {
    return firestore.collection('naver_posts').snapshots().map((snapshot) {
      return snapshot.docs.toList(); // 스냅샷의 문서들을 리스트로 변환하여 반환합니다.
    });
  }

  // 현재 로그인한 사용자의 이메일을 반환하는 메서드로그인이 필요합니다
  String? currentUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email;
  }

  //ios, 안드로이드 기기 텍스트 크기 다르게 하기
  double getTextSize(bool isMyPost) {
    if (Platform.isIOS) { // ios
      return isMyPost ? 18 : 18;
    } else if (Platform.isAndroid) { // Android
      return isMyPost ? 16 : 16;
    } else {
      return isMyPost ? 16 : 16; // 기본 텍스트 크기
    }
  }

  //랭킹 페이지로 이동시 아이디 확인 안되면 새엇ㅇ
  void showCustomSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "아이디를 확인할 수 없습니다. \n다시 로그인 해주세요.",
          textAlign: TextAlign.center,
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

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



  // build 함수는 위젯을 렌더링하는 데 사용됩니다.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Stack(
          children: [
            Positioned.fill(
              child: Lottie.asset(
                'assets/lottie/blue2.json',
                fit: BoxFit.fill,
              ),
            ),
            AppBar(
              automaticallyImplyLeading : false, // '<' 이 뒤로가기 버튼 삭제
              backgroundColor: Colors.transparent,
              title: Text('광주교대 게시판',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'NanumSquareRound',
                ),
              ),
              centerTitle: true,
              actions: <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: 10.0),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: <Widget>[

                      FutureBuilder<String?>(
                        future: _nickname,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return IconButton(
                              icon: Icon(Icons.notifications),
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
                          } else if (!snapshot.hasData || snapshot.data == null) {
                            return IconButton(
                              icon: Icon(Icons.notifications),
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
                            icon: Icon(Icons.notifications),
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
                      // if (messageCount > 0)
                      FutureBuilder<String?>(
                        future: _nickname,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            return Container();
                          } else if (!snapshot.hasData || snapshot.data == null) {
                            return Container();
                          }

                          String ownerNickname = snapshot.data!;
                          return StreamBuilder<DocumentSnapshot>(
                            stream: getMessageCountStream(ownerNickname),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || !snapshot.data!.exists) {
                                return Container();
                              }
                              var data = snapshot.data!.data() as Map<String, dynamic>;
                              int messageCount = data['messageCount'] ?? 0;

                              return Positioned(
                                right: 11,
                                top: 11,
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
                                    ),
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
          ],
        ),
      ),

      //게시판 몸통
      body: Stack(
          children: [
            Column(
              children: <Widget>[
                SizedBox(height: 10), // AppBar와 Row 사이에 20픽셀의 높이를 가진 공간을 추가합니다.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.store,),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("가게 위치 입니다.", textAlign: TextAlign.center,),
                            // behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.location_on,), // 원하는 색상으로 설정
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "상대방이 있는 위치 입니다.",
                              textAlign: TextAlign.center,
                            ),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.monetization_on),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("도움 비용입니다.", textAlign: TextAlign.center,),
                            // behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),

                  ],
                ),
                Flexible(
                  child: StreamBuilder<List<DocumentSnapshot>>(
                    stream: getPosts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('오류가 발생했습니다.'));
                      } else if (snapshot.hasData) {
                        final posts = snapshot.data!;
                        final myEmail = currentUserEmail();

                        posts.sort((a, b) {
                          Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
                          Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
                          bool isMyPostA = dataA['email'] == myEmail;
                          bool isMyPostB = dataB['email'] == myEmail;
                          if (isMyPostA && !isMyPostB) return -1;
                          if (!isMyPostA && isMyPostB) return 1;
                          return 0;
                        });

                        return ListView.builder(
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            DocumentSnapshot doc = posts[index];
                            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                            bool isMyPost = data['email'] == myEmail;
                            bool nextPostIsMine = false;

                            if (index + 1 < posts.length) {
                              Map<String, dynamic> nextData = posts[index + 1].data() as Map<String, dynamic>;
                              nextPostIsMine = nextData['email'] == myEmail;
                            }

                            return Column(
                              children: <Widget>[
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    postManager.helpAndExit(context, doc, _pushHelpButton);
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15.0),
                                    ),
                                    elevation: 3.0,
                                    color: isMyPost ? Colors.indigo[50] : Colors.white,
                                    child: Container(
                                      height: 100,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: Center(
                                                child: Container(
                                                  width: 80,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      if (!isMyPost) {
                                                        HapticFeedback.heavyImpact();
                                                        Navigator.of(context).push(MaterialPageRoute(
                                                          builder: (context) => PostStoreMap(documentId: doc.id),
                                                        ));
                                                      } else {
                                                        postManager.helpAndExit(context, doc, _pushHelpButton);
                                                      }
                                                    },
                                                    child: Container(
                                                      padding: EdgeInsets.all(5.0),
                                                      decoration: BoxDecoration(
                                                        color: isMyPost ? Colors.indigo[50] : Colors.white,
                                                        borderRadius: BorderRadius.circular(20),
                                                        boxShadow: isMyPost ? [] : [
                                                          BoxShadow(
                                                            color: Colors.blueGrey.withOpacity(0.25),
                                                            spreadRadius: 1,
                                                            offset: Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        data['store'] ?? '내용 없음',
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: getTextSize(isMyPost),
                                                          fontWeight: FontWeight.w800,
                                                          fontFamily: 'NanumSquareRound',
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Container(
                                                  width: 80,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      HapticFeedback.heavyImpact();
                                                      if (!isMyPost) {
                                                        Navigator.of(context).push(MaterialPageRoute(
                                                          builder: (context) => PostCurrentMap(documentId: doc.id),
                                                        ));
                                                      } else {
                                                        postManager.helpAndExit(context, doc, _pushHelpButton);
                                                      }
                                                    },
                                                    child: Container(
                                                      padding: EdgeInsets.all(5.0),
                                                      decoration: BoxDecoration(
                                                        color: isMyPost ? Colors.indigo[50] : Colors.white,
                                                        borderRadius: BorderRadius.circular(20.0),
                                                        boxShadow: isMyPost ? [] : [
                                                          BoxShadow(
                                                            color: Colors.blueGrey.withOpacity(0.25),
                                                            spreadRadius: 1,
                                                            offset: Offset(0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        data['my_location'] ?? '내용 없음',
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: getTextSize(isMyPost),
                                                          fontWeight: FontWeight.w800,
                                                          fontFamily: 'NanumSquareRound',
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                data['cost'] ?? '추가 내용 없음',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: getTextSize(isMyPost),
                                                  fontWeight: FontWeight.w800,
                                                  fontFamily: 'NanumSquareRound',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (isMyPost && !nextPostIsMine)
                                  Divider(
                                    color: Colors.indigo[50],
                                    thickness: 3.0,
                                  ),
                              ],
                            );
                          },
                        );
                      } else {
                        return Center(child: Text('게시글이 없습니다.'));
                      }
                    },
                  ),
                ),
              ],
            ),
            if (_pushHelp)
              Container(
                color: Colors.grey.withOpacity(0.5),
                child: Center(
                  child: Lottie.asset(
                    'assets/lottie/smile.json',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            Positioned(
              bottom: 20,
              right: 20,
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Container(
                    // width: 100,
                    // height: 45,
                    child: FloatingActionButton(
                      onPressed: () {
                        // 글쓰기 버튼 눌렀을 때의 동작
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => HanbatNewPostScreen()),
                        );
                      },
                      // label: Text('글쓰기'),
                      child: Icon(Icons.edit),
                      backgroundColor: Colors.indigo[300],
                      foregroundColor: Colors.white,
                      elevation: 3.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
}
