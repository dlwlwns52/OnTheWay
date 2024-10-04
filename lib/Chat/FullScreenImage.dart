import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class FullScreenImage extends StatefulWidget {
  String photoUrl; // 표시할 이미지의 URL

  FullScreenImage({required this.photoUrl}); // 생성자로 이미지 URL을 받음

  _FullScreenImageState createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async{
        return true;
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details){
          if (details.primaryVelocity! >  0){
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
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
                        backgroundColor: Colors.transparent, // 배경색을 흰색으로 설정
                        leading: Container(
                          decoration: BoxDecoration(
                            color: Colors.white, // Container 배경색을 흰색으로 설정
                            shape: BoxShape.circle, // 원형으로 표시
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3), // 그림자 색상과 투명도 설정
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: Offset(0, 1), // 그림자의 위치 조정
                              ),
                            ],
                          ),
                          margin: EdgeInsets.all(8), // Container의 바깥쪽 여백 설정
                          child: IconButton(
                            icon: Icon(Icons.close, color: Colors.black), // 이미지 닫기 버튼
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);

                            },// 이미지 화면 닫기
                          ),
                        ),
                      )

                    ],
                  ),
                )
              ],
            ),
          ),
    ),
    ),
    );
  }
}
