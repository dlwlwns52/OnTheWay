import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FullScreenImage extends StatefulWidget {
  final String photoUrl; // 이미지 경로 또는 URL
  final bool isLocalImage;  // 로컬 이미지 여부 (기본값은 네트워크 이미지)

  FullScreenImage({
    required this.photoUrl,
    this.isLocalImage = false,  // 기본값은 네트워크 이미지
  });

  _FullScreenImageState createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
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
                    tag: widget.photoUrl, // 이미지 고유 태그
                    child: widget.isLocalImage
                        ? Image.asset(widget.photoUrl) // 로컬 이미지 로드
                        : Image.network(widget.photoUrl), // 네트워크 이미지 로드 (기본값)
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      AppBar(
                        elevation: 0.0, // 앱 바 그림자 제거
                        backgroundColor: Colors.transparent, // 배경색 투명
                        leading: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          margin: EdgeInsets.all(8),
                          child: IconButton(
                            icon: Icon(Icons.close, color: Colors.black),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
