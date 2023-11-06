import 'package:flutter/material.dart';
import 'package:ontheway_notebook/login/login_screen.dart';
// 필요한 Firestore import 구문을 추가하세요.
import 'package:cloud_firestore/cloud_firestore.dart';

class BoardPage extends StatefulWidget {
  @override
  _BoardPageState createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  // Firestore 인스턴스
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // 게시글 목록을 불러오는 함수
  Stream<List<DocumentSnapshot>> getPosts() {
    return firestore.collection('posts').snapshots().map((snapshot) {
      return snapshot.docs.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text('게시판'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => LoginScreen()));
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.create),
            onPressed: () {
              // 게시글 작성 페이지로 이동 로직
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NewPostScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: getPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다.'));
          } else if (snapshot.hasData) {
            final posts = snapshot.data!;
            return ListView(
              children: posts.map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    title: Text(data['title'] ?? '제목 없음'),
                    subtitle: Text(data['content'] ?? '내용 없음'),
                    onTap: () {
                      // 게시글 상세보기 로직
                      // Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailScreen(doc)));
                    },
                  ),
                );
              }).toList(),
            );
          } else {
            return Center(child: Text('게시글이 없습니다.'));
          }
        },
      ),
    );
  }
}

class NewPostScreen extends StatefulWidget {
  @override
  _NewPostScreenState createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  Future<void> _uploadPost() async {
    // Firestore에 게시물 업로드 로직
    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'title': _titleController.text,
        'content': _contentController.text,
        'date': DateTime.now(),
      });
      Navigator.of(context).pop(); // 업로드 후 이전 화면으로 돌아감
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시물 업로드에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('새 게시물 작성'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '제목',
              ),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: '내용',
              ),
              maxLines: 10,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              child: Text('게시하기'),
              onPressed: _uploadPost,
            ),
          ],
        ),
      ),
    );
  }
}
