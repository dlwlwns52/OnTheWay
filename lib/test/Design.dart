import 'dart:async'; // 타이머를 위해 추가

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class PhoneAuthScreen extends StatefulWidget {
  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  String _verificationId = "";
  bool _phoneNumberHasText = false;
  bool _codeSentHasText = false;
  bool _codeSent = false;
  Timer? _timer; // 타이머 객체
  int _remainingTime = 300; // 남은 시간 (초 단위)
  String? _phoneNumberErrorText; // 계좌명 에러 메시지
  String? _codeSentErrorText; // 계좌명 에러 메시지

  bool _successAuth = false;

  @override
  void initState() {
    super.initState();

    _phoneController.addListener(_onPhoneNumberChanged);
    _codeController.addListener(_onPhoneNumberChanged);

    _phoneController.addListener(() {
      setState(() {
        _phoneNumberHasText = _phoneController.text.isNotEmpty;
      });
    });

    _codeController.addListener(() {
      setState(() {
        _codeSentHasText = _codeController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _timer?.cancel(); // 타이머 해제
    super.dispose();
  }


  _onPhoneNumberChanged() {
    String value = _phoneController.text;
    setState(() {
      if (value == null || value.trim().isEmpty) {
        _phoneNumberErrorText = '전화번호를 입력해주세요.';
      } else {
        _phoneNumberErrorText = null;
      }
    });
  }

  String formatPhoneNumber(String phoneNumber) {
    // 만약 010으로 시작하면 +82로 변경
    if (phoneNumber.startsWith('010')) {
      return phoneNumber.replaceFirst('010', '+8210');
    }
    // 그 외에는 그대로 반환
    return phoneNumber;
  }

  // 전화번호로 인증 요청
  Future<void> _verifyPhoneNumber() async {
    if(_phoneController.text.length == 11) {
      String formattedPhoneNumber = formatPhoneNumber(_phoneController.text);
      print(formattedPhoneNumber);
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // 자동 인증 성공 시
          await _auth.signInWithCredential(credential);
          print('자동 인증 성공');
        },

        verificationFailed: (FirebaseAuthException e) {
          print('인증 실패: ${e.message}');
          String errorMessage = '';
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = '잘못된 전화번호 형식입니다. \n올바른 전화번호 형식으로 입력해주세요.';
              break;
            case 'too-many-requests':
              errorMessage = '요청이 많아 처리가 지연되고 있습니다. \n잠시 후 다시 시도해 주세요!';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS 인증 한도를 초과했습니다. \n나중에 다시 시도해주세요.';
              break;
            case 'missing-phone-number':
              errorMessage = '전화번호를 입력해주세요.';
              break;
            case 'operation-not-allowed':
              errorMessage = '전화번호 인증이 비활성화되어 있습니다. \n관리자에게 문의해 주세요.';
              break;
            case 'Invalid format': // 'Invalid format'은 직접 설정한 오류 처리
              errorMessage = '잘못된 전화번호입니다. \n확인 후 다시 입력해주세요.';
              break;
            default:
              errorMessage = '알 수 없는 오류가 발생했습니다. \n잠시 후 다시 시도해주세요.';
          }

          // 스낵바로 오류 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage, textAlign: TextAlign.center),
              duration: Duration(seconds: 2),
            ),
          );
        },

        codeSent: (String verificationId, int? resendToken) {
          // 인증 코드가 성공적으로 전송됨
          print('인증 코드 전송');
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
          });

          // 타이머 시작 (5분)
          _startTimer();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    }
    else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('잘못된 전화번호입니다. \n확인 후 다시 입력해주세요.', textAlign: TextAlign.center),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 타이머 시작
  void _startTimer() {
    setState(() {
      _remainingTime = 300; // 5분(300초) 설정
    });

    _timer?.cancel(); // 기존 타이머가 있으면 취소

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer?.cancel();
          _codeSent = false; // 시간이 초과되면 코드 입력을 막고 재요청
          _verificationId = ""; // 기존 verificationId 무효화
          print("인증 시간이 초과되었습니다. 다시 시도해주세요.");
        }
      });
    });
  }

  // 사용자가 입력한 인증 코드로 로그인
// 사용자가 입력한 인증 코드로 로그인
  Future<void> _signInWithCode() async {
    if (_verificationId.isNotEmpty && _remainingTime > 0) { // 타이머가 유효할 때만 인증
      try {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId, // 저장된 verificationId 사용
          smsCode: _codeController.text,
        );
        await _auth.signInWithCredential(credential);
        print('인증 성공');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("인증이 완료되었습니다!",
                textAlign: TextAlign.center),
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {
          _successAuth = true;
        });
        _timer?.cancel();
      } on FirebaseAuthException catch (e) {

        if (e.code == 'invalid-verification-code') {
          // 인증 실패 시 스낵바 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '입력하신 인증번호가 올바르지 않습니다.\n다시 한 번 확인해 주세요.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        print('인증 실패: ${e.message}');
      } catch (e) {
        print('알 수 없는 에러 발생: $e');
      }
    } else {
      print('verificationId가 비어있거나 시간이 초과되었습니다.');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Phone Authentication")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(

          children: [
            Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        '휴대폰 인증',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          height: 1,
                          letterSpacing: -0.4,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ),
                  ),


                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFFFFF),
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: TextFormField(
                        onTap: () {
                          if(!_successAuth) {
                            HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                          }
                        },
                        enabled: !_successAuth,
                        controller: _phoneController,
                        textInputAction: TextInputAction.done,
                        cursorColor: Color(0xFF1D4786),
                        keyboardType: TextInputType.phone, // 숫자 입력 전용 키보드 설정
                        onFieldSubmitted: (value) {
                          HapticFeedback.lightImpact(); // 다음 필드로 이동할 때 햅틱 피드백
                        },
                        decoration: InputDecoration(
                          hintText: '전화번호를 입력해주세요.',
                          hintStyle: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            height: 1,
                            letterSpacing: -0.4,
                            color: Color(0xFF767676),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 12), // 내부 여백 조정
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: _phoneNumberHasText ?  Color(0xFF1D4786): Color(0xFFD0D0D0),
                            ), // 텍스트가 있으면 인디고, 없으면 회색
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF1D4786)), // 포커스 시 색상 변경
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorText: _phoneNumberErrorText,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '전화번호를 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  _codeSent
                      ? Column(
                    children: [
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFFFFF),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: TextFormField(
                            onTap: () {
                              if(!_successAuth) {
                                HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                              }
                            },
                            enabled: !_successAuth,
                            controller: _codeController,
                            textInputAction: TextInputAction.done,
                            cursorColor: Color(0xFF1D4786),
                            keyboardType: TextInputType.phone, // 숫자 입력 전용 키보드 설정
                            onFieldSubmitted: (value) {
                              HapticFeedback.lightImpact(); // 다음 필드로 이동할 때 햅틱 피드백
                            },
                            decoration: InputDecoration(
                              hintText: '인증번호를 입력해주세요.',
                              hintStyle: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                height: 1,
                                letterSpacing: -0.4,
                                color: Color(0xFF767676),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 12), // 내부 여백 조정
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: _codeSentHasText ?  Color(0xFF1D4786): Color(0xFFD0D0D0),
                                ), // 텍스트가 있으면 인디고, 없으면 회색
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF1D4786)), // 포커스 시 색상 변경
                                borderRadius: BorderRadius.circular(8),
                              ),
                              errorText: _codeSentErrorText,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '인증번호를 입력해주세요.';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                  _successAuth ? Container()
                      : Text("남은 시간: $_remainingTime 초",   style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              height: 1,
                              letterSpacing: -0.4,
                              color: Color(0xFF1D4786),
                            )
                          ),
                      SizedBox(height: 5),
                    ],
                  )
                      : Container(),

                  GestureDetector(
                    onTap:(){
                      if(_phoneController.text.isNotEmpty && !_successAuth) {
                        HapticFeedback.lightImpact();
                        _codeSent ? _signInWithCode() : _verifyPhoneNumber();
                      }
                      if(_successAuth){
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("인증이 완료되었습니다!",
                                textAlign: TextAlign.center),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: _phoneController.text.isNotEmpty ? Color(0xFF1D4786):Color(0xFFF6F7F8)),
                        borderRadius: BorderRadius.circular(8),
                        color: _phoneController.text.isNotEmpty ? Color(0xFF1D4786) : Color(0xFFF6F7F8),
                      ),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(3.3, 15, 0, 15),
                        child:
                        _successAuth ?
                        Text(
                          '인증 완료',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            height: 1,
                            letterSpacing: -0.4,
                            color: _phoneController.text.isNotEmpty ? Colors.white : Color(0xFF767676),
                          ),
                          textAlign: TextAlign.center,
                        )
                              :
                        Text(
                          _codeSent ? "인증 하기" : "인증 요청",
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            height: 1,
                            letterSpacing: -0.4,
                            color: _phoneController.text.isNotEmpty ? Colors.white : Color(0xFF767676),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
