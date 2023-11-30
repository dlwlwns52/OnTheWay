
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ontheway_notebook/Board/WriteBoard.dart';


class PostManager { // 필요한 상태나 컨트롤러를 정의합니다.

  void _showEditDeleteDialog(BuildContext context, DocumentSnapshot doc) { // 게시물 편집/삭제 대화 상자 표시 메서드
    showDialog( // Flutter에서 대화 상자를 표시하는 함수 호출
      context: context,
      builder: (context) {
        return AlertDialog( // 사용자에게 선택 옵션을 제공하는 경고 대화 상자 반환
          title: Text('선택하세요',textAlign: TextAlign.center,),
          content: Text('이 게시물을 삭제하거나 수정하시겠습니까?'),
          actions: <Widget>[

            OutlinedButton(
              child: Text(
                  '수정',
                style: TextStyle(
                  color: Colors.orange
                ),
              ),
              onPressed: () {
                _navigateToEditPostScreen(context, doc); // '수정' 버튼 클릭 시 게시물 수정 화면으로 이동 메서드 실행
                // Navigator.of(context).pop(); // 대화 상자 닫기
              },
            ),

            OutlinedButton(
              child: Text(
                  '삭제',
                style: TextStyle(
                  color: Colors.orange
                ),
              ),
              onPressed: () {
                _deletePost(doc.id); // '삭제' 버튼 클릭 시 게시물 삭제 메서드 실행
                Navigator.of(context).pop(); // 대화 상자 닫기
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("게시물이 삭제되었습니다.",textAlign: TextAlign.center,),
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


  void _navigateToEditPostScreen(BuildContext context, DocumentSnapshot doc) { // 게시물 수정 화면으로 이동하는 메서드 정의
    Navigator.of(context).push( // 새 화면으로 이동하는 Flutter 내비게이션 함수 호출
      MaterialPageRoute(
        builder: (context) => NewPostScreen(post: doc),
      ),
    ).then((_) {
    // 화면이 닫힌 후에 이 부분이 실행됩니다.
    Navigator.of(context).pop(); // 대화 상자 닫기
    });
  }


  void _deletePost(String docId) async {// [게시물 삭제 로직]
    try{
      await FirebaseFirestore.instance.collection('posts').doc(docId).delete();
    }
    catch(e){
      print('게시물 삭제 중 오류 발생: $e'); // 오류 발생 시 콘솔에 오류 메시지 출력
      // 여기에 사용자에게 오류 발생을 알리는 UI 로직을 추가할 수 있습니다.
      // 예: 오류 메시지를 화면에 표시하거나, 사용자에게 알림을 보내는 등
    }
  }


  void showPostDetailsOrEditDeleteDialog(BuildContext context, DocumentSnapshot doc) { // 게시물 상세 정보 표시/수정/삭제 옵션 제공 메서드 정의
    String? userEmail = getUserEmail(); // 현재 로그인한 사용자의 이메일 가져오기
    bool isMyPost = userEmail == doc['user_email']; // 현재 게시물이 로그인한 사용자의 것인지 확인

    if (isMyPost) { // 게시물이 사용자의 것일 경우
      _showEditDeleteDialog(context, doc); // 수정 및 삭제 옵션 제공
    } else { // 게시물이 다른 사용자의 것일 경우
      // 상세 정보만 표시
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('주문 시킬 내역 및 요청사항' ,textAlign: TextAlign.center,),
            content: Text(doc['Request'] ?? '요청사항 없음', textAlign: TextAlign.left,),
            actions: <Widget>[
              OutlinedButton(
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


  String? getUserEmail() { // 현재 로그인한 사용자의 이메일 반환하는 메서드 정의
    final user = FirebaseAuth.instance.currentUser; // 현재 로그인한 사용자 정보 가져오기
    return user?.email; // 사용자의 이메일 반환
  }


// 기타 필요한 메서드들...
}
