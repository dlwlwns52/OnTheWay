
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:OnTheWay/Board/WriteBoard.dart';


class PostManager {

  // 필요한 상태나 컨트롤러를 정의합니다.
  void _showEditDeleteDialog(BuildContext context, DocumentSnapshot doc) {
    // 게시물 편집/삭제 대화 상자 표시 메서드
    showDialog( // Flutter에서 대화 상자를 표시하는 함수 호출
      context: context,
      builder: (context) {
        return AlertDialog( // 사용자에게 선택 옵션을 제공하는 경고 대화 상자 반환
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('선택하세요', textAlign: TextAlign.center,),
          content: Text('이 게시물을 삭제하거나 수정하시겠습니까?'),

          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20))
              ),
              child: Text(
                '수정',
                // style: TextStyle(
                //   color: Colors.orange
                // ),
              ),
              onPressed: () {
                _navigateToEditPostScreen(
                    context, doc); // '수정' 버튼 클릭 시 게시물 수정 화면으로 이동 메서드 실행
                // Navigator.of(context).pop(); // 대화 상자 닫기
              },
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20))
              ),
              child: Text(
                '삭제',
                // style: TextStyle(
                //   color: Colors.orange
                // ),
              ),
              onPressed: () {
                _deletePost(doc.id); // '삭제' 버튼 클릭 시 게시물 삭제 메서드 실행
                Navigator.of(context).pop(); // 대화 상자 닫기
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "게시물이 삭제되었습니다.", textAlign: TextAlign.center,),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }


  void _navigateToEditPostScreen(BuildContext context, DocumentSnapshot doc) {
    // 게시물 수정 화면으로 이동하는 메서드 정의
    Navigator.of(context).push( // 새 화면으로 이동하는 Flutter 내비게이션 함수 호출
      MaterialPageRoute(
        builder: (context) => NewPostScreen(post: doc),
      ),
    ).then((_) {
      // 화면이 닫힌 후에 이 부분이 실행됩니다.
      Navigator.of(context).pop(); // 대화 상자 닫기
    });
  }


  void _deletePost(String docId) async {
    // [게시물 삭제 로직]
    try {
      await FirebaseFirestore.instance.collection('posts').doc(docId).delete();
    }
    catch (e) {
      print('게시물 삭제 중 오류 발생: $e'); // 오류 발생 시 콘솔에 오류 메시지 출력
      // 여기에 사용자에게 오류 발생을 알리는 UI 로직을 추가할 수 있습니다.
      // 예: 오류 메시지를 화면에 표시하거나, 사용자에게 알림을 보내는 등
    }
  }


  void helpAndExit(BuildContext context, DocumentSnapshot doc) {
    String? userEmail = getUserEmail(); // 현재 로그인한 사용자의 이메일 가져오기
    bool isMyPost = userEmail == doc['user_email']; // 현재 게시물이 로그인한 사용자의 것인지 확인


    if (isMyPost) {
      _showEditDeleteDialog(context, doc); // 수정 및 삭제 옵션 제공

    } else {
      // 상세 정보만 표시
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // 다이얼로그 모서리 둥글게
            ),
            title: Text(
              '요청사항',
              textAlign: TextAlign.center,
              style:
              TextStyle(
                fontFamily: 'NanumSquareRound',
                fontWeight: FontWeight.w700,
                fontSize: 25,
              ),
            ),
            content: SingleChildScrollView( // 긴 내용 스크롤 가능하도록
              child: Text(
                doc['Request'] ?? '요청사항 없음',
                textAlign: TextAlign.left,
                style:
                TextStyle(
                  fontFamily: 'NanumSquareRound',
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            actions: <Widget>[

              ElevatedButton( //'도와주기' 버튼
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // 버튼 모서리 둥글게
                  ),
                ),
                child: Text('도와주기'),

                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("\n다시 접속해주세요! \n어디서 에러가 났지.. "
                        ,textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 25),),
                      duration: Duration(seconds: 2),

                    ),
                  );
                },
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent, // 버튼 색상 변경
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // 버튼 모서리 둥글게
                  ),
                ),
                child: Text('닫기'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("닫는 것도 마음대로는 힘들지요?.. \n다시 접속해주세요! \n 죄송함다..!",
                        style: TextStyle(fontSize: 25) ,textAlign: TextAlign.center),
                      duration: Duration(seconds: 2),),
                  );
                },
              ),
            ],
          );
        },
      );
    }
  }


  // void helpPost(DocumentSnapshot doc) async {
  //   String? helperEmail = getUserEmail(); // 도와주는 사용자의 이메일 가져오기
  //   String postOwnerEmail = doc['user_email']; // 게시물 작성자의 이메일
  //
  //   // Firebase Firestore에 '도와주기' 액션을 기록하거나, 작성자에게 알림 보내기
  //       String documentName = "hi";
  //       FirebaseFirestore db = FirebaseFirestore.instance;
  //       // 문서 이름을 지정하여 Firestore에 '도와주기' 액션을 기록합니다.
  //       await db.collection('helpActions').doc(documentName).set({
  //         'post_id': doc.id,
  //         'helper_email': helperEmail,
  //         'owner_email': postOwnerEmail,
  //         'timestamp': DateTime.now(),
  //       });
  //
  // }

  Future<String> getNickname(String email) async {
    var userDocument = await FirebaseFirestore.instance.collection('users').doc(email).get();
    return userDocument.data()?['nickname'] ?? '';
  }

  void helpPost(BuildContext context, DocumentSnapshot doc) async {
    String? helperEmail = getUserEmail(); // 도와주는 사용자의 이메일 가져오기
    String postOwnerEmail = doc['user_email']; // 게시물 작성자의 이메일

    try {
      // 도와주는 사람과 게시물 작성자의 닉네임을 가져옵니다.
      String helperNickname = await getNickname(helperEmail!);
      String ownerNickname = await getNickname(postOwnerEmail);

      // 문서 이름을 만듭니다. 예: "helperNickname_ownerNickname"
      String documentName = "${helperNickname}_${ownerNickname}";

      // Firestore에 '도와주기' 액션을 기록하면서 문서 이름을 설정합니다.
      await FirebaseFirestore.instance.collection('helpActions').doc(documentName).set({
        'post_id': doc.id,
        'helper_email': helperEmail,
        'owner_email': postOwnerEmail,
        'timestamp': DateTime.now(),
      });

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("도움을 성공적으로 제공하였습니다."),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("도움을 제공하는 데 실패하였습니다: $e"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }




  String? getUserEmail() {
    // 현재 로그인한 사용자의 이메일 반환하는 메서드 정의
    final user = FirebaseAuth.instance.currentUser; // 현재 로그인한 사용자 정보 가져오기
    return user?.email; // 사용자의 이메일 반환
  }


}

