import 'package:flutter/material.dart';
import 'package:ontheway_notebook/CreateAccount/CreateAccount.dart';

class NavigateToBoard {
  final BuildContext context;

  NavigateToBoard(this.context);

  void navigate(String email) {
    String domain = email.split('@').last; // 이메일에서 도메인 추출

    // 도메인별로 조건을 설정하여, 해당 조건에 맞는 게시판으로 이동
    switch (domain) {
      case 'naver.com':
        Navigator.pushNamed(context, '/naverBoard');
        break;
      case 'edu.hanbat.ac.kr':
        Navigator.pushNamed(context, '/hanbatBoard');
        break;
      case 'yahoo.com':
        Navigator.pushNamed(context, '/yahooBoard');
        break;
    // 이 외의 다른 도메인에 대한 케이스를 추가할 수 있습니다.
      default:
        Navigator.pushNamed(context, '/defaultBoard');
        break;
    }
  }
}
