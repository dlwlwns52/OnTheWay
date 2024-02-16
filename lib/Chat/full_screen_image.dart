//이 코드는 Flutter 애플리케이션에서 전체 화면 이미지를 표시하는 위젯을 정의하는 Dart 코드입니다.
//이 위젯은 전체 화면에 이미지를 표시하고 이미지를 닫기 위한 아이콘 버튼을 포함한 상단 앱 바도 표시합니다.

import 'package:flutter/material.dart';


class FullScreenImage extends StatefulWidget {
  String photoUrl; // 표시할 이미지의 URL

  FullScreenImage({required this.photoUrl}); // 생성자로 이미지 URL을 받음

  _FullScreenImageState createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: Hero(
                tag: widget.photoUrl, // 이미지를 고유하게 식별하는 태그
                child: Image.network(widget.photoUrl), // 네트워크에서 이미지 로드
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppBar(
                    elevation: 0.0, // 앱 바의 그림자 효과를 제거
                    backgroundColor: Colors.transparent, // 배경 투명
                    leading: IconButton(
                      icon: Icon(Icons.close, color: Colors.black), // 이미지 닫기 버튼
                      onPressed: () => Navigator.pop(context), // 이미지 화면 닫기
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
