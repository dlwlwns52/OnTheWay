import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

import 'SocialLogin.dart';

class KakaoLogin implements SocialLogin{
  @override
  Future<bool> login() async{
    try{
      bool isInstalled = await isKakaoTalkInstalled();
      if(isInstalled){
        try{
          await UserApi.instance.loginWithKakaoTalk();
          return true;
        }
        catch (e){
          return false;
        }
      }

      else {
        try{
          await UserApi.instance.loginWithKakaoAccount();
          return true;
        }
        catch (e){
          return false;
        }
      }
    } catch (e){
      return false;
    }
  }


  @override
  Future<bool> logout() async{
    try {
      await UserApi.instance.unlink();
      print('연결 끊기 성공, SDK에서 토큰 삭제');
      return true;
    } catch (e) {
      print('연결 끊기 실패 $e');
      return false;
    }
  }
}