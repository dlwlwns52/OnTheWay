import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:OnTheWay/NaverBoard/NaverWriteBoard.dart';


class NaverPostManager {

  FirebaseFirestore db = FirebaseFirestore.instance;


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
                  primary: Colors.orangeAccent,
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
                  primary: Colors.orangeAccent,
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
                String postStore = doc['store']; // 게시물의 'store' 값을 가져옵니다.
                String? postOwnerEmail = getUserEmail(); // 현재 로그인한 사용자의 이메일을 가져옵니다.

                _deletePost(doc.id, postStore, postOwnerEmail!);// '삭제' 버튼 클릭 시 게시물 삭제 메서드 실행
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
        builder: (context) => NaverNewPostScreen(post: doc),
      ),
    ).then((_) {
      // 화면이 닫힌 후에 이 부분이 실행됩니다.
      Navigator.of(context).pop(); // 대화 상자 닫기
    });
  }


  void _deletePost(String docId,String postStore, String postOwnerEmail) async {
    try {
      print(postStore);
      print(postOwnerEmail);
      // 'naverUserHelpStatus' 컬렉션에서 문서 이름 생성
      String documentName = createDocumentName(postStore, postOwnerEmail);
      print(documentName);
      // 'naverUserHelpStatus' 컬렉션에서 해당 문서 삭제
      await FirebaseFirestore.instance.collection('naverUserHelpStatus').doc(documentName).delete();

      // 게시물 삭제
      await FirebaseFirestore.instance.collection('naver_posts').doc(docId).delete();

    } catch (e) {
      print('게시물 삭제 중 오류 발생: $e');
      // 오류 발생시 UI 로직 추가...
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView( // 긴 내용 스크롤 가능하도록
              child: Text(
                doc['Request'] ?? '요청사항 없음',
                textAlign: TextAlign.left,
              ),
            ),
            actions: <Widget>[

              ElevatedButton( //'도와주기' 버튼
                style: ElevatedButton.styleFrom(
                  primary: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // 버튼 모서리 둥글게
                  ),
                ),
                child: Text('도와주기'),
                onPressed: () {
                  helpPost(context, doc); // 도와주기 기능 실행
                },
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.orangeAccent, // 버튼 색상 변경
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20), // 버튼 모서리 둥글게
                  ),
                ),
                child: Text('닫기'),
                onPressed: () {
                  Navigator.of(context).pop(); // 대화 상자 닫기
                },
              ),
            ],
          );
        },
      );
    }
  }

  String? getUserEmail() {
    // 현재 로그인한 사용자의 이메일 반환하는 메서드 정의
    final user = FirebaseAuth.instance.currentUser; // 현재 로그인한 사용자 정보 가져오기
    return user?.email; // 사용자의 이메일 반환
  }


  void helpPost(BuildContext context, DocumentSnapshot doc) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      // currentUser가 null인 경우, 즉 사용자가 로그인하지 않았다면, 오류 메시지를 표시하고 함수를 종료합니다.
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("로그인이 필요합니다."),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      String? helperEmail = getUserEmail(); // 도와주는 사용자의 이메일 가져오기

      String postOwnerEmail = doc['user_email']; // 게시물 작성자의 이메일
      // 'naver_posts' 컬렉션에서 해당 게시물의 'store' 값을 가져옵니다.
      DocumentSnapshot postDoc = await FirebaseFirestore.instance.collection('naver_posts').doc(doc.id).get();
      String postStore = postDoc['store']; // 게시물의 'store' 필드

      // 현재 시간을 기반으로 타임스탬프 생성
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();


      // 'naverUserHelpStatus' 컬렉션에서 특정 문서(도와주기 상태)를 가져옵니다.
      // 문서 이름은 postStore와 postOwnerEmail을 결합하여 생성됩니다.
      Map<String, dynamic> helpStatus = await getUserHelpClickStatus(postStore, postOwnerEmail);

      // 가져온 문서에서 docId를 키로 하는 상태를 확인합니다.
      // 문서가 없거나 해당 키가 없으면 기본값을 사용합니다.
      var postStatus = helpStatus[helperEmail] ?? {'clickCount': 0, 'lastClickedTime': DateTime(1970)};

      int clickCount = postStatus['clickCount']; // 클릭 횟수를 가져옵니다.
      // lastClickedTime을 가져오기 위한 초기화
      DateTime lastClickedTime;

      // postStatus에서 lastClickedTime이 Timestamp 형식인지 확인합니다.
      // Timestamp 형식이면 DateTime으로 변환하고, 아니면 기본값을 사용합니다.
      if (postStatus['lastClickedTime'] is Timestamp) {
        lastClickedTime = (postStatus['lastClickedTime'] as Timestamp).toDate();
      } else {
        lastClickedTime = postStatus['lastClickedTime'] ?? DateTime(1970);
      }

// 현재 시간을 가져옵니다.
      DateTime now = DateTime.now();

// 만약 사용자가 이미 2번 이상 '도와주기'를 요청했다면, 경고 메시지를 표시하고 함수를 종료합니다. // 현재는 100번 test용
      if (clickCount >= 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("도와주기 요청은 최대 2회까지 가능합니다.", textAlign: TextAlign.center,),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

// 만약 마지막 '도와주기' 요청 이후 5초가 지나지 않았다면, 경고 메시지를 표시하고 함수를 종료합니다.
      if (now.difference(lastClickedTime).inSeconds < 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("이미 '도와주기' 요청 완료했습니다.\n다시 한 번 시도하시려면 30초 후에 다시 시도해주세요.", textAlign: TextAlign.center,),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }


      // 도와주기 버튼 누른 사람 닉네임 users 컬렉션에서 조회한 후 변수에 저ㄹ장!
      // Firestore의 'users' 컬렉션에서 helperEmail에 해당하는 사용자 문서를 조회합니다.
      final usersCollection = FirebaseFirestore.instance.collection('users');
      final userDoc = await usersCollection.where('email', isEqualTo: helperEmail).get();

      // 사용자 문서가 존재하면 닉네임을 가져옵니다.
      String helperNickname = '';
      if (userDoc.docs.isNotEmpty) {
        helperNickname = userDoc.docs.first.data()['nickname'];
      } else {
        // 사용자 문서가 없다면 에러 처리를 합니다.
        // 예를 들어, 로그를 남기거나 사용자에게 피드백을 줄 수 있습니다.
        print('User document not found for email: $helperEmail');
        return;
      }



      updateHelpClickStatus(postStore, postOwnerEmail, helperEmail!);

      // 문서 이름을 만듭니다. 예: "postStore_helperEmail_timestamp"
      String documentName = "${postStore}_${helperEmail}_$timestamp";
      // String documentName = "${postStore}_${helperEmail}";

      // Firestore에 '도와주기' 액션을 기록하면서 문서 이름을 설정합니다.
      await FirebaseFirestore.instance.collection('helpActions').doc(documentName).set({
        'University' : "naver",
        'post_id': doc.id,
        'helper_email': helperEmail,
        'helper_email_nickname' : helperNickname,
        'owner_email': postOwnerEmail,
        'timestamp': DateTime.now(),
      });

      // 대화상자를 닫고 스낵바 표시
      Navigator.of(context).pop();
      // 성공 메시지 표시
      await ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("'도와주기'요청이 전송됐습니다.",textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      ).closed;


    } catch (e) {
      // 오류 메시지 표시
      // 대화상자를 닫고 스낵바 표시
      Navigator.of(context).pop();
      await ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("도와주기'요청이 전송이 실패하였습니다: $e",textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      ).closed;
    }
  }

// 'naverUserHelpStatus' 컬렉션에서 특정 문서를 조회하는 메서드입니다.
// 조회에 성공하면 문서의 데이터를 Map 형태로 반환하고, 없으면 빈 Map을 반환합니다.
  Future<Map<String, dynamic>> getUserHelpClickStatus(String postStore, String? postOwnerEmail) async {
    String documentName = createDocumentName(postStore, postOwnerEmail);
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('naverUserHelpStatus').doc(documentName).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    }
    return {};
  }

// 'naverUserHelpStatus' 컬렉션에 사용자의 '도와주기' 상태를 업데이트하는 함수
  void updateHelpClickStatus(String postStore, String postOwnerEmail, String helperEmail) {
    // 문서 이름은 게시물을 올린 사용자의 이메일과 스토어 이름을 결합하여 생성합니다.
    String documentName = createDocumentName(postStore, postOwnerEmail);

    // 문서에 '도와주기'를 누른 사용자의 이메일을 키로 하여 클릭 카운트와 마지막 클릭 시간을 저장합니다.
    FirebaseFirestore.instance.collection('naverUserHelpStatus').doc(documentName).set({
      helperEmail: { // 키
        'clickCount': FieldValue.increment(1),
        'lastClickedTime': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));
  }


  String createDocumentName(String postStore, String? postOwnerEmail) {
    return "${postStore}_${postOwnerEmail}";
  }

}

