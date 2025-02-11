
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../Alarm/AlarmUi.dart';
import '../../Profile/Profile.dart';
import '../../Progress/PaymentScreen.dart';
import '../../Ranking/DepartmentRanking.dart';
import '../../SchoolBoard/SchoolBoard.dart';
import '../AllUsersScreen.dart';
import '../ChatScreen.dart';
import 'chat_room_viewmodel.dart';


import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_svg/svg.dart';



class ChatRoomView extends StatefulWidget {
  @override
  _ChatRoomViewState createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> {
  final ScrollController _scrollController = ScrollController();


  // 바텀 네비게이션 인덱스
  int _selectedIndex = 0; // 기본 선택된 항목을 '게시판'으로 설정
  String botton_email = ""; // 사용자의 이메일을 저장할 변수
  String botton_domain = ""; // 사용자의 도메인을 저장할 변수


  @override
  void initState() {
    super.initState();

    final viewmodel = context.read<ChatRoomViewModel>();
    viewmodel.fetchChatActions();

    final FirebaseAuth _auth = FirebaseAuth.instance;
    botton_email = _auth.currentUser?.email ?? "";
    botton_domain = botton_email.split('@').last.toLowerCase();

    //닉네임 가져옴
    viewmodel.getNickname(botton_email);

    _scrollController.addListener(() {
      if (_scrollController.position.atEdge) {
        bool isBottom = _scrollController.position.pixels != 0;
        viewmodel.isNearBottom = isBottom;
      }
    });
  }


  @override
  void dispose() {
    _scrollController.dispose();  // ScrollController 해제
    super.dispose();
  }


  void showNicknameConfirmationDialog(BuildContext context, String documentId, String ownerNickname, String helperNickname, bool isHelper) {
    final viewmodel = context.read<ChatRoomViewModel>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 35),
              Container(
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '채팅방 나가기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1D1D1D),
                      ),

                    ),
                    SizedBox(height: 13),
                    Text(
                      '⚠️ 대화내용 및 채팅 목록이 모두 삭제됩니다.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                        height: 1.5,
                        letterSpacing: -0.2,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),
              Divider(color: Colors.grey, height: 1),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop(); // 취소 버튼 클릭 시 다이얼로그 닫기
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                      ),
                      child: Center(
                        child: Text(
                          '취소',
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
                    width: 1.0, // 구분선의 두께
                    height: 60, // 구분선의 높이
                    color: Colors.grey, // 구분선의 색상
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: ()  {
                        // '나가기' 버튼을 눌렀을 때의 로직 구현
                        HapticFeedback.lightImpact();
                        if (isHelper) {
                          viewmodel.handleDeleteChatRoom(documentId, helperNickname);
                        } else {
                          viewmodel.handleDeleteChatRoom(documentId, ownerNickname);
                        }
                        viewmodel.deleteChatRoomIfBothDeleted(documentId, ownerNickname, helperNickname);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "채팅방이 삭제되었습니다.",
                              textAlign: TextAlign.center,
                            ),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                      ),
                      child: Center(
                        child: Text(
                          '나가기',
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
        );
      },
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


  @override
  Widget build(BuildContext context) {
    final viewmodel = context.watch<ChatRoomViewModel>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
        child: AppBar(
          title: Text(
            '채팅',
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
          leading: SizedBox(), // 상단 왼쪽 빈 공간을 만들기 위해 빈 SizedBox를 사용
          actions: [
            Container(
              margin: EdgeInsets.only(right: 18.7), // 오른쪽 여백 설정
              child: Stack(
                alignment: Alignment.topRight,
                children: <Widget>[

                  if(viewmodel.nicknameValue == null)
                        CircularProgressIndicator()
                  else if(viewmodel.nicknameValue != null)
                    IconButton(
                    icon: SvgPicture.asset(
                      'assets/pigma/notification_white.svg',
                      width: 25,
                      height: 25,
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final nickname = context.read<ChatRoomViewModel>().nicknameValue!;
                      await viewmodel.resetMessageCountVm(nickname);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AlarmUi(),
                          //   builder: (context) => Design(),
                        ),
                      );
                    },
                  ),

                  // 실시간 메시지 카운트
                  if (viewmodel.nicknameValue != null)
                    StreamBuilder<DocumentSnapshot>(
                      stream: viewmodel.getMessageCountStreamVm(viewmodel.nicknameValue!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Container();
                        }

                        var data = snapshot.data!.data() as Map<String, dynamic>;
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
                              messageCount > 99 ? '99+' : '$messageCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                              : Container(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),


      body: acceptedChatActions != null && acceptedChatActions.length > 0
          ? Container(
        padding: EdgeInsets.only(top: 10.0),
        child: FutureBuilder<String?>(
            future: getNickname2(botton_email),
            builder: (context, nicknameSnapshot) {
              if (nicknameSnapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (nicknameSnapshot.hasError) {
                return Text("Error: ${nicknameSnapshot.error}");
              } else if (!nicknameSnapshot.hasData || nicknameSnapshot.data == null) {
                return Text('닉네임을 찾을 수 없습니다.');
              }

              String? helperUserNickName = nicknameSnapshot.data;

              // 차단된 사용자 목록 가져오기
              return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(helperUserNickName)
                      .collection('blacklist')
                      .snapshots(),
                  builder: (context, blacklistSnapshot) {
                    if (blacklistSnapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (blacklistSnapshot.hasError) {
                      return Text("Error: ${blacklistSnapshot.error}");
                    }

                    List blockedEmails = blacklistSnapshot.data!.docs.map((doc) {
                      return doc['blockedEmail'];
                    }).toList();

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: acceptedChatActions.length,
                      itemBuilder: ((context, index) {
                        DocumentSnapshot userDoc = acceptedChatActions[index];
                        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
                        final DocumentSnapshot doc = acceptedChatActions[index];
                        final String documentName = userDoc.id; // 채팅방 문서 ID

                        // 차단된 사용자의 이메일을 필터링
                        if (blockedEmails.contains(userData['owner_email']) ||
                            blockedEmails.contains(userData['helper_email'])) {
                          return Container(); // 차단된 사용자의 채팅방 숨김
                        }


                        // 로그인한 사람 이메일 확인
                        User? currentUser = FirebaseAuth.instance.currentUser;
                        String? currentUserEmail = currentUser?.email;


                        //알림 온 시간 측정
                        final DateTime? lastMessageTime = lastMessageTimes[documentName];
                        if (lastMessageTime == null) {
                          // 마지막 메시지 시간을 아직 가져오지 않았다면, 비동기로 가져옵니다.
                          fetchLastMessage(documentName).then((timestamp) {
                            if (mounted) { // 위젯이 아직 화면에 존재하는지 확인
                              setState(() {
                                lastMessageTimes[documentName] = timestamp;
                              });
                            }
                          });
                        }

                        // 마지막 메시지 시간 또는 채팅방 생성 시간을 사용하여 시간 표시
                        final DateTime dateTime = lastMessageTime ?? userData['timestamp'].toDate();
                        final String timeAgo = getTimeAgo(dateTime);


                        // 메시지 카운트 키 생성
                        String messageCountKey = "";
                        if (userData['helper_email'] == currentUserEmail) {
                          messageCountKey = "$documentName-${userData['helper_email']}";
                        }
                        else if (userData['owner_email'] == currentUserEmail) {
                          messageCountKey = "$documentName-${userData['owner_email']}";
                        }
                        // 메시지 카운트 가져오기
                        int messageCount = messageCounts[messageCountKey] ?? 0;

                        //마지막으로 온 메시지
                        String lastMessage = userData['lastMessage'] ?? "채팅방이 개설되었습니다.";


                        //나가기 버튼 사용시 상대방 대화 안보이게 하기
                        if (userData['helper_email'] == currentUserEmail && userData['isDeleted_${userData['helper_email_nickname']}'] == true) {
                          return Container(); // 또는 적절한 '삭제됨' UI를 표시
                        }
                        else if (userData['owner_email'] == currentUserEmail && userData['isDeleted_${userData['owner_email_nickname']}'] == true) {
                          return Container(); // 또는 적절한 '삭제됨' UI를 표시
                        }

                        if(userData['helper_email'] == currentUserEmail){
                          bool isHelper = true;
                        }
                        else if(userData['owner_email'] == currentUserEmail){
                          bool isOwner = true;
                        }

                        bool isHelper = userData['helper_email'] == currentUserEmail;
                        bool isOwner = userData['owner_email'] == currentUserEmail;

                        return   Column(
                          children: [
                            if (isHelper || isOwner) ...[
                              Dismissible(
                                key: Key(doc.id),
                                confirmDismiss: (direction) async {
                                  // 스와이프 후 삭제 확인 대화상자 표시
                                  showNicknameConfirmationDialog(context, doc.id, userData['owner_email_nickname'], userData['helper_email_nickname'], true);
                                },
                                background: Container(
                                  color: Colors.red,
                                  child: Align(
                                    alignment: Alignment.center, // 왼쪽 정렬
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min, // 내용물 크기에 맞게 Row 크기 조절
                                      children: <Widget>[
                                        Icon(Icons.delete, color: Colors.white, size: 50), // 아이콘
                                        Text(
                                          ' 삭제', // 텍스트
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                child: FutureBuilder<String?>(
                                  future:  _getProfileImage(isHelper ? userData['owner_email'] : userData['helper_email'] ),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return SizedBox.shrink(); // 아무것도 표시하지 않음
                                    }
                                    if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}'); // 오류 발생 시 표시할 위젯
                                    }
                                    if (!snapshot.hasData || snapshot.data == null) {
                                      return Text('No data available'); // 데이터가 없을 때 표시할 위젯
                                    }

                                    String? profileImageUrl = snapshot.data;

                                    return GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();

                                        String senderName = isHelper ? userData['helper_email_nickname'] : userData['owner_email_nickname'];
                                        String receiverName = isHelper ? userData['owner_email_nickname'] : userData['helper_email_nickname'];
                                        String receiverUid = isHelper ? userData['ownerUid'] : userData['helperUid'];
                                        String receiverKey = isHelper ? 'messageCount_${userData['helper_email_nickname']}' : 'messageCount_${userData['owner_email_nickname']}';

                                        FirebaseFirestore.instance
                                            .collection('ChatActions')
                                            .doc(doc.id)
                                            .update({receiverKey: 0});

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatScreen(
                                              senderName: senderName,
                                              receiverName: receiverName,
                                              receiverUid: receiverUid,
                                              documentName: doc.id,
                                              photoUrl: profileImageUrl,
                                            ),
                                          ),
                                        );
                                      },

                                      onLongPress: (){
                                        HapticFeedback.heavyImpact();
                                        showNicknameConfirmationDialog(context, doc.id, userData['owner_email_nickname'], userData['helper_email_nickname'], isHelper,
                                        );
                                      },
                                      child: Container(
                                        margin: EdgeInsets.fromLTRB(20, 0, 20, 10),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Color(0xFFE3E3E3),
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.start,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          HapticFeedback.lightImpact();
                                                          if (profileImageUrl!.isNotEmpty) {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (context) => FullScreenImage(photoUrl: profileImageUrl),
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
                                                                colors: [Color(0xFF1D4786), Color(0xFF1D4786)],
                                                                begin: Alignment.topLeft,
                                                                end: Alignment.bottomRight,
                                                              ),
                                                              boxShadow: [
                                                                (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                                                    ? BoxShadow(
                                                                  color: Colors.black.withOpacity(0.1),
                                                                  spreadRadius: 1,
                                                                  blurRadius: 1,
                                                                  offset: Offset(0, 1), // 그림자 위치 조정
                                                                )
                                                                    : BoxShadow(),
                                                              ],
                                                            ),
                                                            child: CircleAvatar(
                                                              radius: 25,
                                                              backgroundColor: Colors.grey[200],
                                                              child: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                                                                  ? null
                                                                  : Icon(
                                                                Icons.account_circle,
                                                                size: 50, // 원래 코드에서 width와 height가 32였으므로 여기에 맞춤
                                                                color: Color(0xFF1D4786),
                                                              ),
                                                              backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                                                                  ? NetworkImage(profileImageUrl)
                                                                  : null,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        margin: EdgeInsets.fromLTRB(4, 10, 0, 10),
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              isHelper ? userData['owner_email_nickname'] : userData['helper_email_nickname'],
                                                              style: TextStyle(
                                                                fontFamily: 'Pretendard',
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 17,
                                                                height: 1,
                                                                letterSpacing: -0.4,
                                                                color: Color(0xFF222222),
                                                              ),
                                                            ),
                                                            SizedBox(height: 10),
                                                            Container(
                                                              width: MediaQuery.of(context).size.width * 0.5,
                                                              child: Text(
                                                                "$lastMessage",
                                                                style: TextStyle(
                                                                  fontFamily: 'Pretendard',
                                                                  fontWeight: FontWeight.w400,
                                                                  fontSize: 14,
                                                                  height: 1,
                                                                  letterSpacing: -0.4,
                                                                  color: Color(0xFF767676),
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                                maxLines: 1,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Container(
                                                    margin: EdgeInsets.fromLTRB(0, 10, 0, 2.5),
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      crossAxisAlignment: CrossAxisAlignment.end,
                                                      children: [
                                                        Container(
                                                          margin: EdgeInsets.fromLTRB(0, 0, 0, 5),
                                                          child: Text(
                                                            '$timeAgo',
                                                            style: TextStyle(
                                                              fontFamily: 'Pretendard',
                                                              fontWeight: FontWeight.w400,
                                                              fontSize: 13,
                                                              height: 1,
                                                              letterSpacing: -0.3,
                                                              color: Color(0xFF767676),
                                                            ),
                                                          ),
                                                        ),
                                                        if (messageCount == 0) ...[
                                                          Container(
                                                          ),
                                                        ]
                                                        else ...[
                                                          Container(
                                                            padding: EdgeInsets.all(8.0),  // 원형 크기 조절
                                                            decoration: BoxDecoration(
                                                              color: Color(0xFF1D4786),  // 원형 배경 색상
                                                              shape: BoxShape.circle,    // 원형 모양
                                                            ),
                                                            child: Text(
                                                              messageCount > 99 ? '99+' :'${messageCount}',
                                                              style: TextStyle(
                                                                fontFamily: 'Pretendard',
                                                                fontWeight: FontWeight.w500,
                                                                fontSize: 12,
                                                                height: 1,
                                                                letterSpacing: -0.3,
                                                                color: Color(0xFFFFFFFF),  // 텍스트 색상
                                                              ),
                                                            ),
                                                          ),
                                                        ]
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // 나머지 Container와 Row 등에도 동일하게 적용해주면 됩니다.
                                          ],
                                        ),
                                      ),

                                    );
                                  },
                                ),

                              ),
                            ],
                          ],
                        );
                      }),
                    );
                  }
              );
            }
        ),
      )
          : Center(
        child: Container(
          width: 300,
          height: 200,
          child: Text(
            '현재 활성화된 채팅방이 없습니다. \n거래가 성사시, 이곳에서 확인하실 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFamily: 'NanumSquareRound',
              color: Color(0xFF1D4786),
            ),
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
