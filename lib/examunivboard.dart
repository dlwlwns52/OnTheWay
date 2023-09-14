import 'package:flutter/material.dart';

class BoardPage extends StatefulWidget {
  @override
  _BoardPageState createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  List<String> posts = [
    '게시글 1',
    '게시글 2',
    '게시글 3',
    '게시글 4',
  ];  // 샘플 데이터

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시판'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // 게시글 작성 로직
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(posts[index]),
            onTap: () {
              // 게시글 상세보기 로직
            },
          );
        },
      ),
    );
  }
}
