import 'package:flutter/material.dart';
import 'package:ontheway_notebook/login_screen.dart';

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
        backgroundColor: Colors.orange,
        title: Text('게시판'),
        leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
            }
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              // 게시글 작성 로직
            },
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          ...posts.map((post) => ListTile(
            title: Text(post),
            onTap: () {
              // 게시글 상세보기 로직
            },
          )).toList(),
          Divider(),  // 구분선
          ListTile(
            title: Text('Icons.money'),
            leading: Icon(Icons.money),
          ),
        ],
      ),
    );
  }
}
