import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'SocialLogin.dart';

class MainViewModel{
  final SocialLogin _socialLogin;
  bool isLogined = false;
  User? user;

  MainViewModel(this._socialLogin);

  Future login() async{
    isLogined = await _socialLogin.login();
    if(isLogined){
      user = await UserApi.instance.me();
    }
  }
}