import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'WriteBoard.dart';

class PostManager {
  // 필요한 상태나 컨트롤러를 정의합니다.
  void _showEditDeleteDialog(BuildContext context, DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('선택하세요'),
          content: Text('이 게시물을 삭제하거나 수정하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              child: Text('삭제'),
              onPressed: () {
                _deletePost(doc.id);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('수정'),
              onPressed: () {
                _navigateToEditPostScreen(context, doc);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deletePost(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(docId).delete();
      // 성공적으로 삭제 후 UI 업데이트 로직 (옵션)
    } catch (e) {
      // 오류 처리
    }
  }

  void _navigateToEditPostScreen(BuildContext context, DocumentSnapshot doc) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewPostScreen(post: doc),
      ),
    );
  }

  void showPostDetailsOrEditDeleteDialog(BuildContext context, DocumentSnapshot doc) {
    String? userEmail = getUserEmail();
    bool isMyPost = userEmail == doc['user_email'];

    if (isMyPost) {
      // 내 게시물인 경우: 수정 및 삭제 옵션
      _showEditDeleteDialog(context, doc);
    } else {
      // 다른 사람의 게시물인 경우: 요청사항 보기
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('주문 시킬 내역 및 요청사항'),
            content: Text(doc['Request'] ?? '요청사항 없음'),
            actions: <Widget>[
              TextButton(
                child: Text('닫기'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  String? getUserEmail() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email;
  }
// 기타 필요한 메서드들...
}
