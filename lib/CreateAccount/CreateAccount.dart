import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import '../login/LoginScreen.dart';
import 'DepartmentList.dart';
import 'NicknameValidator.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'ReferralCodeManager.dart';

class CreateAccount extends StatefulWidget {

  @override
  _CreateAccountState createState() => _CreateAccountState();

}

class _CreateAccountState extends State<CreateAccount> with WidgetsBindingObserver{

// TextEditingControllers (입력 컨트롤러)
  TextEditingController _nicknameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController(); // 비밀번호 입력
  TextEditingController _confirmPasswordController = TextEditingController(); // 비밀번호 확인
  TextEditingController _emailUserController = TextEditingController(); // 이메일 입력
  TextEditingController _accountNameController = TextEditingController(); // 계좌명 입력
  TextEditingController _accountNumberController = TextEditingController(); // 계좌번호 입력
  TextEditingController _searchController = TextEditingController(); // 검색 입력
  TextEditingController _departmentSearchController = TextEditingController(); // 학과 검색 입력
  TextEditingController _phoneController = TextEditingController(); // 휴대폰 번호 입력
  TextEditingController _codeController = TextEditingController(); // 인증 코드 입력
  TextEditingController _referralCodeController = TextEditingController(); // 추천인 코드 입력

// 상태 및 플래그 변수
  bool _isNicknameAvailable = false; // 닉네임 중복 확인 상태
  bool _snackBarShown = false; // 스낵바 표시 여부
  bool _emailHasText = false; // 이메일 입력 여부
  bool _nicknameHasText = false; // 닉네임 입력 여부
  bool _passwordHasText = false; // 비밀번호 입력 여부
  bool _confirmPasswordHasText = false; // 비밀번호 확인 입력 여부
  bool _accountNumberHasText = false; // 계좌번호 입력 여부
  bool _obscureText1 = true; // 비밀번호 가리기 (별표 처리)
  bool _obscureText2 = true; // 비밀번호 확인 가리기 (별표 처리)
  bool isEmailVerified = false; // 이메일 인증 여부
  bool _isEULAChecked = false; // EULA 동의 여부
  bool _isPrivacyPolicyChecked = false; // 개인정보 처리방침 동의 여부
  bool _phoneNumberHasText = false; // 휴대폰 번호 입력 여부
  bool _successAuth = false; // 인증 성공 여부
  bool _codeSentHasText = false; // 인증 코드 입력 여부
  bool _codeSent = false; // 인증 코드 전송 여부
  bool _referralCodeHasText = false; // 추천인 코드 입력 여부
// 추천인 코드 인증 상태를 저장하는 변수
  bool isReferralCodeVerified = false; // 초기값은 false로 설정

  //이메일인증 관련
  bool _emailIsNotGoogle = false; // 인증 코드 전송 여부
  bool _emailCodeSent = false;
  int _remainingVerificationTime = 300;
  Timer? _verificationTimer;


// 버튼 관련 상태
  String _buttonText = '중복확인'; // 버튼 텍스트

// 에러 메시지 상태
  String? _usernicknameErrorText; // 닉네임 에러 메시지
  String? _userpasswordErrorText; // 비밀번호 에러 메시지
  String? _confirmPasswordErrorText; // 비밀번호 확인 에러 메시지
  String? _userEmailErrorText; // 이메일 에러 메시지
  String? _accountNameErrorText; // 계좌명 에러 메시지
  String? _accountNumberErrorText; // 계좌번호 에러 메시지
  String? _phoneNumberErrorText; // 휴대폰 번호 에러 메시지
  String? _codeSentErrorText; // 인증 코드 에러 메시지


// Firebase 및 OAuth 관련
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth 인스턴스
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Google Sign-In 인스턴스

// Dropdown 및 선택 관련 상태
  String? _dropdownValue; // 드롭다운 선택값
  String? _bankName; // 은행 이름
  String? _selectedDepartment; // 선택된 학과

// 도메인 데이터
  List<Map<String, String>> _domains = [
    {'name': '전북대학교', 'domain': 'jbnu.ac.kr'},
    {'name': '충남대학교', 'domain': 'o.cnu.ac.kr'},
    {'name': '서울대학교', 'domain': 'snu.ac.kr'},
    {'name': '부산대학교', 'domain': 'pusan.ac.kr'},
    {'name': '충북대학교', 'domain': 'cberi.go.kr'},
    {'name': '한남대학교', 'domain': 'm365.hnu.ac.kr'},

    // {'name': 'test3', 'domain': 'edu.hanbat.ac.kr'},
    {'name': '한밭대학교', 'domain': 'edu.hanbat.ac.kr'},
    // {'name': 'test', 'domain': 'gmail.com'},
  ];
  List<Map<String, String>> _filteredDomains = []; // 필터링된 도메인 목록

// 휴대폰 인증 관련
  String _verificationId = "";
  Timer? _timer; // 타이머 객체
  int _remainingTime = 300; // 남은 시간 (초 단위)
// 추천인 코드 무작위 생성
  final ReferralCodeManager _referralCodeManager = ReferralCodeManager();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 전화번호 휴대폰 인증 한 번씩만
  bool _isPhoneButtonEnabled = true;
  bool _isEmailButtonEnabled = true;


  @override
  void initState() {
    super.initState();
    _filteredDomains = _domains;
    _nicknameController.addListener(_onNicknameChanged);
    _passwordController.addListener(_onpasswordChanged);
    _confirmPasswordController.addListener(_confirmPasswordChanged);
    _emailUserController.addListener(_onEmaildChanged);
    _accountNameController.addListener(_onAccountNameChanged);
    _accountNumberController.addListener(_onAccountNumberChanged);
    // _phoneController.addListener(_onPhoneNumberChanged);
    // _codeController.addListener(_onPhoneNumberChanged);



    _emailUserController.addListener(() {
      setState(() {
        _emailHasText = _emailUserController.text.isNotEmpty;
      });
    });

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

    _nicknameController.addListener(() {
      setState(() {
        _nicknameHasText = _nicknameController.text.isNotEmpty;
      });
    });

    _passwordController.addListener(() {
      setState(() {
        _passwordHasText = _passwordController.text.isNotEmpty;
      });
    });

    _confirmPasswordController.addListener(() {
      setState(() {
        _confirmPasswordHasText = _confirmPasswordController.text.isNotEmpty;
      });
    });

    _accountNumberController.addListener(() {
      setState(() {
        _accountNumberHasText = _accountNumberController.text.isNotEmpty;
      });
    });


    _referralCodeController.addListener(() {
      setState(() {
        _referralCodeHasText = _referralCodeController.text.isNotEmpty;
      });
    });


  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailUserController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _referralCodeController.dispose();
    _timer?.cancel(); // 타이머 해제
    super.dispose();
  }


  //추천인 +1
  Future<void> incrementReferralCount(String referralCode) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    // 추천인 코드로 해당 사용자를 찾음
    QuerySnapshot querySnapshot = await firestore
        .collection('users')
        .where('referralCode', isEqualTo: referralCode)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // 해당 추천 코드를 가진 사용자의 문서 ID 가져오기
      DocumentReference userRef = querySnapshot.docs.first.reference;

      // 현재 추천 카운트를 읽음
      DocumentSnapshot snapshot = await userRef.get();

      if (snapshot.exists) {
        // snapshot.data()를 Map<String, dynamic>으로 변환하여 사용
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;

        if (data != null) {
          // referralCount 필드가 있으면 값을 가져오고, 없으면 0으로 초기화
          int currentCount = data['referralCount'] ?? 0;

          // referralCount를 1 증가시키는 로직
          await userRef.update({'referralCount': currentCount + 1});
        }
      }
    }
  }



  //해당 추천인 코드를 가진 사용자가 있는지 확인
  Future<bool> checkReferralCode(String referralCode) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('referralCode', isEqualTo: referralCode)
        .get();

    // Firestore에서 같은 추천 코드가 없으면 중복되지 않은 것으로 간주
    return querySnapshot.docs.isNotEmpty;
  }



  // 사용자를 위한 추천 코드를 생성하고 저장하는 함수
  Future<void> createAndAssignReferralCode(String userId) async {
    // 고유한 추천 코드 생성
    String referralCode = await _referralCodeManager.generateUniqueReferralCode();

    // 추천 코드를 Firestore에 저장
    await _referralCodeManager.saveReferralCodeToUser(userId, referralCode);

    print('추천 코드가 성공적으로 생성되고 저장되었습니다: $referralCode');
  }

//스낵바 형식능
  void buildCustomHelpDialog() async {
    final nickname = _nicknameController.text.trim();
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(nickname)
        .get();

    // 중복된 이증
    if (snapshot.exists && snapshot.data()?['nickname'] == nickname) {
      setState(() {
        _buttonText = '중복확인';
        _isNicknameAvailable = false;
      });
    }
    else {
      // 사용 가능한 이름
      setState(() {
        _buttonText = '사용가능';
        _isNicknameAvailable = true;
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 45),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: _isNicknameAvailable
                          ? '사용 가능한 이름입니다.\n이 닉네임을 사용하시겠습니까?'
                          : '다른 사용자가 사용하고 있는 이름입니다.\n다른 닉네임을 사용해 주시길 바랍니다.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF222222),
                      ),
                    ),
                    TextSpan(
                      text: _isNicknameAvailable
                          ? '\n\n\n⚠️ 닉네임은 한 번 설정하시면 변경이 '
                          : '',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.normal,
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    TextSpan(
                      text: _isNicknameAvailable
                          ? '불가'
                          : '',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.normal,
                        fontSize: 10,
                        color: Color(0xFF1D4786),
                      ),
                    ),
                    TextSpan(
                      text: _isNicknameAvailable
                          ? '하니 신중히 선택해 주세요.\n⚠️ 다른 닉네임을 선택하려면, '
                          : '',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.normal,
                        fontSize: 10,
                        color: Colors.grey
                      ),
                    ),
                    TextSpan(
                      text: _isNicknameAvailable
                          ? '취소'
                          : '',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.normal,
                        fontSize: 10,
                        color: Color(0xFF1D4786),
                      ),
                    ),
                    TextSpan(
                      text: _isNicknameAvailable
                          ? ' 버튼을 눌러 주세요.'
                          : '',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.normal,
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              Divider(color: Colors.grey, height: 1,),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _isNicknameAvailable= false;
                        });
                        _nicknameController.clear();
                        Navigator.of(context).pop(); // 취소 버튼 클릭 시 다이얼로그 닫기
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                      ),
                      child: Center(
                        child: Text(
                          '취소',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color(0xFF636666),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1.0, // 구분선의 두께
                    height: 60, // 구분선의 높이
                    color: Colors.grey, // 구분선의 색상
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        if (_isNicknameAvailable) {
                          _nicknameController.text = nickname;
                        } else {
                          _nicknameController.clear();
                          print('닉네임이 사용 중입니다.'); // 디버깅을 위한 메세지 추가
                        }
                        Navigator.of(context).pop();

                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                      ),
                      child: Center(
                        child: Text(
                          '확인',
                          style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF1D4786)
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  //EULA 동의 여부 다이어로그
  void _acceptTermsDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(child:
        Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(15, 25, 15, 0),
            child : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '최종 사용자 사용권 계약 (EULA)',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF222222),
                  ),
                ),
                SizedBox(height: 20,),
                Text(
                  '본 계약은 귀하(이하 "사용자")와 온더웨이(이하 "회사") 간의 소프트웨어 사용에 대한 법적 계약을 정의합니다. 사용자는 온더웨이 앱을 설치하고 사용함으로써 본 계약의 모든 조항에 동의한 것으로 간주됩니다.\n\n'
                      '1. 사용권 부여\n'
                      '회사는 사용자가 온더웨이 애플리케이션(이하 "앱")을 비독점적이고 양도 불가한 방식으로 사용할 수 있는 권한을 부여합니다. '
                      '본 앱은 사용자의 개인적인 용도로만 사용할 수 있으며, 상업적 목적이나 다른 사람에게 임대, 양도할 수 없습니다. '
                      '사용자는 본 앱을 대한민국 내에서만 사용할 수 있습니다.\n\n'
                      '2. 사용자의 의무\n'
                      '사용자는 앱을 불법적 목적으로 사용하거나, 회사 또는 타인의 지적 재산권을 침해해서는 안 됩니다. '
                      '사용자는 본 앱 내에서 타인의 개인정보를 무단으로 수집, 저장, 배포하는 행위를 해서는 안 됩니다. '
                      '사용자는 온더웨이에서 제공하는 게시물, 채팅 등에서 **불법적이거나 부적절한 콘텐츠(예: 비속어, 음란물, 혐오 발언)**를 게시할 수 없습니다. '
                      '사용자는 본 앱의 소스 코드 또는 소프트웨어를 역설계, 분해, 복제, 수정, 배포할 수 없습니다. 이러한 행위는 회사의 명시적 허가가 없는 한 금지됩니다.\n\n'
                      '3. 지적 재산권\n'
                      '본 앱에 포함된 모든 자료, 소스 코드, 상표, 디자인, 아이콘, 서비스 이름 등은 회사의 독점적 자산이며, 회사의 사전 서면 동의 없이 이를 복제, 수정, 배포, 상업적으로 이용할 수 없습니다. '
                      '사용자 생성 콘텐츠(게시물, 리뷰 등)에 대한 저작권은 사용자에게 귀속되지만, 사용자는 해당 콘텐츠가 온더웨이 내에서 광고 및 홍보 목적으로 사용될 수 있음을 동의합니다.\n\n'
                      '4. 책임 한계\n'
                      '회사는 온더웨이 앱 사용 중 발생할 수 있는 직접적, 간접적 손해에 대해 법적 책임을 지지 않습니다. 이는 다음과 같은 경우를 포함하나 이에 국한되지 않습니다: '
                      '사용자가 앱을 잘못 사용하여 발생한 손해, 제3자가 사용자 계정에 불법적으로 접근하여 발생한 손해, 네트워크 장애, 서버 오류, 또는 기타 기술적 문제로 인해 발생한 손해. '
                      '회사는 앱의 기능이 모든 환경에서 완벽하게 작동한다는 보장을 하지 않습니다. 또한 앱 사용 중 발생할 수 있는 버그나 오류에 대한 책임은 회사에 있지 않습니다.\n\n'
                      '5. 사용권 제한\n'
                      '사용자가 본 계약의 조항을 위반할 경우, 회사는 사전 통지 없이 사용자의 앱 사용 권리를 제한하거나 계정을 삭제할 수 있습니다. '
                      '사용자는 본 계약의 조항을 위반한 경우, 회사에 발생한 모든 손해에 대해 배상할 책임이 있습니다.\n\n'
                      '6. 개인정보 보호\n'
                      '회사는 사용자의 개인정보를 대한민국 개인정보 보호법에 따라 보호합니다. 사용자의 개인정보는 사용자가 동의한 목적과 범위 내에서만 사용되며, 사용자의 동의 없이 제3자에게 제공되지 않습니다. '
                      '회사는 개인정보 처리방침에 따라 사용자의 정보를 보호하며, 해당 방침은 앱 내 설정 메뉴에서 확인할 수 있습니다.\n\n'
                      '7. 라이선스의 종료\n'
                      '사용자가 본 계약을 위반하거나, 회사의 서비스 이용 정책을 위반한 경우, 회사는 사용자의 라이선스를 즉시 종료할 수 있습니다. '
                      '사용자는 언제든지 앱 사용을 중단할 수 있으며, 앱 삭제 시 사용자의 모든 권한은 즉시 종료됩니다.\n\n'
                      '8. 서비스 중단 및 수정\n'
                      '회사는 언제든지 사전 공지 없이 앱의 기능을 수정, 추가 또는 제거할 수 있습니다. '
                      '회사는 사용자가 제공하는 서비스에 대해 보장을 하지 않으며, 필요에 따라 일시적으로 서비스를 중단할 수 있습니다. 이 경우 사용자에게 사전에 통지합니다.\n\n'
                      '9. 준거법 및 분쟁 해결\n'
                      '본 계약은 대한민국 법률에 따라 해석되며, 서비스와 관련된 모든 분쟁은 서울중앙지방법원을 전속 관할 법원으로 합니다.',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.normal,
                    fontSize: 12, // 작은 글씨 크기 설정
                    color: Colors.grey, // 회색으로 설정
                  ),
                ),


                SizedBox(height: 40),
                Divider(color: Colors.grey, height: 1,),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // 다이얼로그가 닫히기 전에 포커스를 해제하여 키보드가 올라오지 않게 함
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _isEULAChecked = false;
                          });
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                        ),
                        child: Center(
                          child: Text(
                            '취소',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF636666),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1.0, // 구분선의 두께
                      height: 60, // 구분선의 높이
                      color: Colors.grey, // 구분선의 색상
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // 다이얼로그가 닫히기 전에 포커스를 해제하여 키보드가 올라오지 않게 함
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _isEULAChecked = true;
                          });
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                        ),
                        child: Center(
                          child: Text(
                            '동의',
                            style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFF1D4786)
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }


  //개인정보 처리방침 동의 여부 다이어로그
  void _isPrivacyPolicyCheckdialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(child:
        Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(15, 25, 15, 0),
            child : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '개인정보 처리방침',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF222222),
                  ),
                ),
                SizedBox(height: 20,),
                Text(
                  '온더웨이 개인정보 처리방침\n\n'
                      '온더웨이는 이용자의 개인정보를 매우 중요하게 여기며, 대한민국 「개인정보 보호법」에 따라 개인정보를 안전하게 처리하고 보호하기 위해 최선을 다하고 있습니다. 본 개인정보 처리방침은 이용자가 제공한 개인정보가 어떻게 수집되고 이용되며, 어떤 방식으로 보호되고 있는지 안내하기 위한 것입니다.\n\n'
                      '이 방침은 2024년 9월 26일부터 적용됩니다.\n\n'
                      '제1조(개인정보의 처리 목적)\n'
                      '온더웨이는 다음의 목적을 위하여 개인정보를 처리합니다. 처리된 개인정보는 아래 목적 외의 용도로는 사용되지 않으며, 이용 목적이 변경되는 경우에는 별도의 동의를 받을 예정입니다.\n\n'
                      '- 회원가입 및 관리: 회원 가입의사 확인, 서비스 제공에 따른 본인 식별·인증, 회원자격 유지 및 관리 등을 목적으로 개인정보를 처리합니다.\n'
                      '- 결제 처리: 결제 서비스 이용을 위해 아임포트를 통한 KakaoPay, TossPay 등과 연동하여 결제 정보가 처리됩니다.\n'
                      '- 알림 서비스: 주문 상태 및 도와주기 요청 등과 같은 알림 전송을 위해 개인정보를 처리합니다.\n'
                      '- 위치 정보 제공: 도와주는 헬퍼의 위치 추적 및 안내를 위한 위치 정보를 처리합니다.\n\n'
                      '제2조(개인정보의 처리 및 보유 기간)\n'
                      '온더웨이는 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 동의받은 개인정보 보유·이용기간 내에서 개인정보를 처리 및 보유합니다.\n\n'
                      '- 회원가입 및 관리: 회원 탈퇴 시까지\n'
                      '- 결제 정보: 결제 및 거래 관련 정보는 5년간 보유 (전자상거래 등에서의 소비자보호에 관한 법률에 근거)\n'
                      '- 위치 정보: 위치 추적 종료 시 즉시 삭제\n\n'
                      '제3조(처리하는 개인정보의 항목)\n'
                      '온더웨이는 다음의 개인정보 항목을 처리하고 있습니다.\n\n'
                      '- 필수 항목: 이메일, 위치 정보, 결제 정보, UID(파이어베이스 사용자 식별자)\n'
                      '- 선택 항목: 프로필 사진, 학과 정보\n\n'
                      '제4조(개인정보의 제3자 제공)\n'
                      '온더웨이는 이용자의 동의, 법률의 특별한 규정 등 개인정보 보호법에 따라 개인정보를 제3자에게 제공할 수 있습니다. 온더웨이는 **아임포트(Iamport)**를 통해 KakaoPay 및 TossPay와 연동하여 결제 처리를 합니다. 해당 결제 서비스 제공업체에 결제 관련 정보를 제공할 수 있습니다.\n\n'
                      '- 제공받는 자: KakaoPay, TossPay\n'
                      '- 제공 목적: 결제 서비스 제공 및 처리\n'
                      '- 제공 항목: 결제 정보, 이메일\n'
                      '- 보유 및 이용 기간: 결제 후 5년간 보관\n\n'
                      '제5조(개인정보 처리 업무의 위탁)\n'
                      '온더웨이는 원활한 개인정보 업무 처리를 위하여 다음과 같이 개인정보 처리 업무를 외부에 위탁하고 있습니다.\n\n'
                      '- 수탁자: Firebase (Google)\n'
                      '- 위탁하는 업무의 내용: 데이터 보관 및 서비스 제공을 위한 클라우드 인프라\n\n'
                      '제6조(개인정보의 파기 절차 및 파기방법)\n'
                      '온더웨이는 개인정보 보유 기간의 경과, 처리 목적 달성 등 개인정보가 불필요하게 되었을 때에는 지체 없이 해당 개인정보를 파기합니다. 파기 절차 및 방법은 다음과 같습니다.\n\n'
                      '- 파기 절차: 보유 기간이 경과한 개인정보는 내부 방침 및 관련 법령에 따라 파기합니다.\n'
                      '- 파기 방법: 전자적 파일 형태로 저장된 개인정보는 기록을 복구할 수 없도록 기술적 방법을 사용하여 삭제합니다. 종이로 출력된 개인정보는 분쇄기로 파기합니다.\n\n'
                      '제7조(정보주체와 법정대리인의 권리·의무 및 그 행사방법)\n'
                      '정보주체는 언제든지 자신의 개인정보에 대한 열람, 정정, 삭제, 처리정지 등을 요구할 수 있습니다. 정보주체의 권리는 본인의 프로필 설정을 통해 확인 및 수정할 수 있으며, 이를 위한 절차는 다음과 같습니다.\n\n'
                      '- 권리 행사 절차: 개인정보 보호책임자에게 전자우편(dwlwns52@naver.com)을 통해 열람 및 수정 요청\n\n'
                      '제8조(개인정보의 안전성 확보조치)\n'
                      '온더웨이는 개인정보의 안전성을 확보하기 위해 다음과 같은 조치를 취하고 있습니다.\n\n'
                      '- 개인정보의 암호화: 사용자의 비밀번호는 암호화되어 저장 및 관리되며, 중요한 데이터는 암호화하여 보관하고 있습니다.\n'
                      '- 접근 제한: 개인정보 처리 시스템에 대한 접근 권한을 부여하고 이를 철저히 관리합니다.\n'
                      '- 보안 프로그램 설치: 해킹 등 외부 침입에 대비하여 보안 프로그램을 설치하고 주기적으로 점검 및 갱신합니다.\n\n'
                      '제9조(개인정보 보호책임자에 관한 사항)\n'
                      '온더웨이는 개인정보 처리에 관한 업무를 총괄해서 책임지고, 개인정보 처리와 관련한 정보주체의 불만처리 및 피해구제 등을 위해 아래와 같이 개인정보 보호책임자를 지정하고 있습니다.\n\n'
                      '- 개인정보 보호책임자: 이지준\n'
                      '- 연락처: dlwlwns52@naver.com\n\n'
                      '제10조(정보주체의 권익침해에 대한 구제방법)\n'
                      '정보주체는 개인정보침해로 인한 구제를 받기 위해 아래 기관에 문의할 수 있습니다.\n\n'
                      '- 개인정보침해신고센터 : (국번없이) 118 (privacy.kisa.or.kr)\n'
                      '- 개인정보분쟁조정위원회 : (국번없이) 1833-6972 (www.kopico.go.kr)\n'
                      '- 대검찰청 : (국번없이) 1301 (www.spo.go.kr)\n'
                      '- 경찰청 : (국번없이) 182 (ecrm.cyber.go.kr)\n\n'
                      '제11조(개인정보 처리방침의 변경)\n'
                      '이 개인정보처리방침은 2024년 9월 26일부터 적용됩니다. 법령 및 내부 방침의 변경에 따라 내용의 추가, 삭제 및 수정이 있을 시에는 변경 사항의 시행 7일 전에 앱 내 공지사항을 통하여 고지할 것입니다.',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.normal,
                    fontSize: 12, // 작은 글씨 크기 설정
                    color: Colors.grey, // 회색으로 설정
                  ),
                ),



                SizedBox(height: 40),
                Divider(color: Colors.grey, height: 1,),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // 다이얼로그가 닫히기 전에 포커스를 해제하여 키보드가 올라오지 않게 함
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _isPrivacyPolicyChecked = false;
                          });
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                        ),
                        child: Center(
                          child: Text(
                            '취소',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF636666),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1.0, // 구분선의 두께
                      height: 60, // 구분선의 높이
                      color: Colors.grey, // 구분선의 색상
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // 다이얼로그가 닫히기 전에 포커스를 해제하여 키보드가 올라오지 않게 함
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _isPrivacyPolicyChecked = true;
                          });
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                        ),
                        child: Center(
                          child: Text(
                            '동의',
                            style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFF1D4786)
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }



  void _onDomainSelected(String domain) {

    setState(() {
      _dropdownValue = domain;
    });
    print(_emailIsNotGoogle);
  }


  void _onDepartmentSelected(String domain) {
    setState(() {
      _selectedDepartment = domain;
    });
  }


  void _filterDomains(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDomains = _domains;
      } else {
        _filteredDomains = _domains.where((domain) {
          return domain['name']!.toLowerCase().contains(query.toLowerCase()) ||
              domain['domain']!.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }


  void _onBankNameSelected(String bankname) {
    setState(() {
      _bankName = bankname;
    });
  }

  //이메일 선택 다이어로그
  void showCustomBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      backgroundColor: Colors.transparent, // 투명 배경을 설정하여 모서리 둥근 부분을 표시
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return GestureDetector(
              onTap: () {
                // 화면의 다른 부분을 터치했을 때 포커스 해제
                FocusScope.of(context).unfocus();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // 내용물에 따라 높이가 조절되도록 설정
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(1, 0, 0, 40),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFE3E3E3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(20, 0, 20, 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.fromLTRB(0, 0, 0, 30),
                                child: Text(
                                  '본인 학교의 웹메일을 선택해주세요.',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    height: 1,
                                    letterSpacing: -0.5,
                                    color: Color(0xFF1D4786),
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.fromLTRB(0, 0, 0, 20),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          // TextFormField의 너비를 Row의 남은 공간으로 확장
                                          child: Container(
                                            color: Color(0xFFFFFFFF),
                                            margin: EdgeInsets.fromLTRB(0, 2, 0, 2),
                                            child: TextFormField(
                                              cursorColor: Color(0xFF1D4786),
                                              controller: _searchController,
                                              textInputAction: TextInputAction.done,
                                              onTap: () {
                                                HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                                              },
                                              decoration: InputDecoration(
                                                contentPadding: EdgeInsets.fromLTRB(15, 15, 15, 15),
                                                hintText: '학교 메일을 검색하세요.',
                                                hintStyle: TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 16,
                                                  height: 1,
                                                  letterSpacing: -0.4,
                                                  color: Color(0xFF767676),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: _emailHasText ? Color(0xFF1D4786) : Color(0xFFD0D0D0),
                                                  ),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(color: Color(0xFF1D4786)),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                counterText: '', // 하단의 '0/10' 텍스트를 숨김
                                                prefixIcon: Padding(
                                                  padding: const EdgeInsets.all(12.0), // 아이콘 사이즈 조정
                                                  child: SvgPicture.asset(
                                                    'assets/pigma/Serch.svg',
                                                    width: 20,
                                                    height: 20,
                                                  ),
                                                ),
                                                suffixIcon: Padding(
                                                  padding: const EdgeInsets.all(12.0), // 아이콘 사이즈 조정
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      _searchController.clear(); // 텍스트 필드 내용 삭제
                                                      _filterDomains('');
                                                      FocusScope.of(context).unfocus(); // 포커스 해제
                                                    },
                                                    child: SvgPicture.asset(
                                                      'assets/pigma/x.svg',
                                                      width: 20,
                                                      height: 20,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  _filterDomains(value);
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    height: MediaQuery.of(context).size.height * 0.4,
                                    child: ListView(
                                      children: _filteredDomains.map((domain) {
                                        return GestureDetector(
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            print(domain['name']);


                                            // 학교 추가하면 여기에 추가
                                            // 학교 추가하면 여기에 추가
                                            if (domain['name'] == '충남대학교' || domain['domain'] == 'o.cnu.ac.kr') {
                                              _onDomainSelected(domain['domain']!); // onSelected 함수 호출
                                              setState(() {
                                                _emailIsNotGoogle = true;
                                              });
                                            }
                                            else if (domain['name'] == '한남대학교' || domain['domain'] == 'm365.hnu.ac.kr') {
                                              _onDomainSelected(
                                                  domain['domain']!); // onSelected 함수 호출
                                              setState(() {
                                                _emailIsNotGoogle = true;
                                              });
                                            }
                                            else if (domain['name'] == '한밭대학교' || domain['domain'] == 'edu.hanbat.ac.kr') {
                                              _onDomainSelected(domain['domain']!); // onSelected 함수 호출
                                              setState(() {
                                                _emailIsNotGoogle = false;
                                              });
                                            }
                                            else if (domain['name'] == '전북대학교' || domain['domain'] == 'jbnu.ac.kr') {
                                              _onDomainSelected(domain['domain']!); // onSelected 함수 호출
                                              setState(() {
                                                _emailIsNotGoogle = false;
                                              });
                                            }


                                            // else if(domain['name'] == 'test' || domain['domain'] == 'edu.hanbat.ac.kr') {
                                            //   setState(() {
                                            //     _emailIsNotGoogle = false;
                                            //   });
                                            //   _onDomainSelected(domain['domain']!); // onSelected 함수 호출
                                            //
                                            // }


                                            else{
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '곧 출시될 학교입니다.',
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  duration: Duration(seconds: 1),
                                                ),
                                              );
                                              _onDomainSelected('출시 예정입니다.'); // onSelected 함수 호출
                                              setState(() {
                                                _emailIsNotGoogle = false;
                                              });
                                            }

                                            Navigator.pop(context);
                                          },
                                          child: Container(
                                            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Color(0xFFD0D0D0)),
                                              borderRadius: BorderRadius.circular(12),
                                              color: Color(0xFFFFFFFF),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.fromLTRB(15, 17, 17, 17),
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    margin: EdgeInsets.fromLTRB(0, 2, 8, 2),
                                                    child: Text(
                                                      '${domain['name']} (${domain['domain']})',
                                                      style: TextStyle(
                                                        fontFamily: 'Pretendard',
                                                        fontWeight: FontWeight.w400,
                                                        fontSize: 16,
                                                        height: 1,
                                                        letterSpacing: -0.4,
                                                        color: Color(0xFF222222),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      // 취소 버튼이 탭되었을 때의 동작 추가
                                      HapticFeedback.lightImpact();
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Color(0xFFF6F7F8)),
                                        color: Color(0xFFF6F7F8),
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.fromLTRB(0, 20, 1, 25), // 버튼 높이 조정
                                        child: Text(
                                          '취소',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                            height: 1,
                                            letterSpacing: -0.5,
                                            color: Color(0xFF222222),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  // 이메일 선택 바텀시트
  void DepartmentSelectionBottomSheet(BuildContext context, String domain) {
    List<String> departments = DepartmentList.getDepartmentsByDomain(domain);
    List<String> filteredDepartments = departments;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      backgroundColor: Colors.transparent, // 투명 배경을 설정하여 모서리 둥근 부분을 표시
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {

            void _filterDepartments(String query) {
              setState(() {
                if (query.isEmpty) {
                  filteredDepartments = departments;
                } else {
                  filteredDepartments = departments
                      .where((department) => department
                      .toLowerCase()
                      .contains(query.trim().toLowerCase())) // 대소문자 구분 없이, 공백 제거
                      .toList();
                }
              });
            }

            return GestureDetector(
              onTap: () {
                // 화면의 다른 부분을 터치했을 때 포커스 해제

                FocusScope.of(context).unfocus();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // 내용물에 따라 높이가 조절되도록 설정
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 모달 상단의 드래그 표시
                        Container(
                          margin: EdgeInsets.fromLTRB(1, 0, 0, 40),
                          decoration: BoxDecoration(
                            color: Color(0xFFE3E3E3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          width: 44,
                          height: 4,
                        ),
                        // 검색 필드
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 20),
                          child: TextFormField(
                            cursorColor: Color(0xFF1D4786),
                            controller: _departmentSearchController,
                            onTap: () {
                              HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                            },
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.all(15),
                              hintText: '학과를 검색하세요.',
                              hintStyle: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                color: Color(0xFF767676),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFD0D0D0),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF1D4786)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Icon(Icons.search, color: Color(0xFF1D4786)),
                              ),
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  _departmentSearchController.clear();
                                  _filterDepartments('');
                                  FocusScope.of(context).unfocus(); // 포커스 해제
                                },
                                child: Icon(Icons.clear, color: Color(0xFF1D4786)),
                              ),
                            ),
                            onChanged: (value) {
                              _filterDepartments(value);
                            },
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          height: MediaQuery.of(context).size.height * 0.4,
                          width:  MediaQuery.of(context).size.width * 0.95,
                          child: ListView(
                            children: filteredDepartments.map((domain) {
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  _onDepartmentSelected(domain);
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Color(0xFFD0D0D0)),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Color(0xFFFFFFFF),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(15, 17, 17, 17),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: EdgeInsets.fromLTRB(0, 2, 8, 2),
                                          child: Text(
                                            '${domain}',
                                            style: TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w400,
                                              fontSize: 16,
                                              height: 1,
                                              letterSpacing: -0.4,
                                              color: Color(0xFF222222),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        // 취소 버튼
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      // 취소 버튼이 탭되었을 때의 동작 추가
                                      HapticFeedback.lightImpact();
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Color(0xFFF6F7F8)),
                                        color: Color(0xFFF6F7F8),
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.fromLTRB(0, 20, 1, 25), // 버튼 높이 조정
                                        child: Text(
                                          '취소',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                            height: 1,
                                            letterSpacing: -0.5,
                                            color: Color(0xFF222222),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }



// 은행 명 바텀시트
  void showBankSelectionSheet(BuildContext context) {
    String _bankName = ''; // 상태를 여기에 저장
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      isScrollControlled: true, // 키보드가 올라올 때 전체 화면을 차지하도록 설정
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void _onBankSelected(String bankname) {
              setState(() {
                _bankName = bankname;
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // 키보드에 의해 가려지는 부분을 고려한 패딩
              ),
              child: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(1, 0, 0, 40),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFE3E3E3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            width: 44,
                            height: 4,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(20, 0, 20, 30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                margin: EdgeInsets.fromLTRB(0, 0, 0, 30),
                                child: Text(
                                  '은행을 선택해주세요.',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                    height: 1,
                                    letterSpacing: -0.5,
                                    color: Color(0xFF1D4786),
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildBankRow(
                                    context,
                                    ['NH농협', '카카오뱅크', 'KB국민'],
                                    _bankName,
                                    _onBankSelected,
                                  ),
                                  _buildBankRow(
                                    context,
                                    ['신한', '우리', '토스뱅크'],
                                    _bankName,
                                    _onBankSelected,
                                  ),
                                  _buildBankRow(
                                    context,
                                    ['IBK기업', '하나', '새마을'],
                                    _bankName,
                                    _onBankSelected,
                                  ),
                                  _buildBankRow(
                                    context,
                                    ['부산', '대구', '케이뱅크'],
                                    _bankName,
                                    _onBankSelected,
                                  ),
                                  _buildBankRow(
                                    context,
                                    ['신협', '우체국', 'SC제일'],
                                    _bankName,
                                    _onBankSelected,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    '⚠️해당하는 은행이 위에 없을 경우 아래에 직접 입력해주세요!',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.normal,
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  TextField(
                                    onChanged: (value) {
                                      setState(() {
                                        _bankName = value;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: '여기에 입력해주세요.',
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 10,
                                        horizontal: 12,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(color: Color(0xFF1D4786)), // 포커스 시 색상 변경
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusColor: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Color(0xFFF6F7F8)),
                                    color: Color(0xFFF6F7F8),
                                  ),
                                  padding: EdgeInsets.fromLTRB(0, 14, 1, 32),
                                  child: Text(
                                    '취소',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      height: 1,
                                      letterSpacing: -0.5,
                                      color: Color(0xFF222222),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  _onBankNameSelected(_bankName);
                                  HapticFeedback.lightImpact();
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Color(0xFF1D4786)),
                                    color: Color(0xFF1D4786),
                                  ),
                                  padding: EdgeInsets.fromLTRB(0, 14, 0, 32),
                                  child: Text(
                                    '확인',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      height: 1,
                                      letterSpacing: -0.5,
                                      color: Color(0xFFFFFFFF),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


// 은행명 구조
  Widget _buildBankRow(
      BuildContext context,
      List<String> bankNames,
      String selectedBank,
      void Function(String) onBankSelected,
      ) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: bankNames.map((bankName) {
          final bool isTapped = selectedBank == bankName;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                onBankSelected(bankName);
                HapticFeedback.lightImpact();
              },
              child: Container(
                margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                decoration: BoxDecoration(
                  color: isTapped ? Color(0xFF1D4786) : Color(0xFFF6F7F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(
                  padding: EdgeInsets.fromLTRB(0, 23, 1, 24),
                  child: Text(
                    bankName,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      height: 1,
                      letterSpacing: -0.4,
                      color: isTapped ? Color(0xFFFFFFFF) : Color(0xFF222222),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


  //회원가입 완료 다이어로그

  void _onSignUpButtonPressed(BuildContext context) async {
    HapticFeedback.lightImpact();
    if (_validateFields()) {
      bool emailAvailable = await _checkEmailAvailability();
      if (!emailAvailable) return;

      User? currentUser = FirebaseAuth.instance.currentUser;

      final rootContext = context;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 45),
                Text(
                  '회원가입을 완료 하시겠습니까?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF222222),
                  ),
                ),
                SizedBox(height: 40),
                Divider(color: Colors.grey, height: 1,),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop(); // 취소 버튼 클릭 시 다이얼로그 닫기
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                        ),
                        child: Center(
                          child: Text(
                            '취소',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Color(0xFF636666),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1.0, // 구분선의 두께
                      height: 60, // 구분선의 높이
                      color: Colors.grey, // 구분선의 색상
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          HapticFeedback.lightImpact();

                          String nickname = _nicknameController.text;
                          String email = _emailUserController.text + "@" + _dropdownValue!;
                          String accountNumber = _accountNumberController.text;
                          String password = _passwordController.text;
                          try {

                            User? currentUser = FirebaseAuth.instance.currentUser;

                            // 비밀번호 추가하기
                            if (currentUser != null) {
                              // 이메일이 null일 경우 수동으로 업데이트
                              if (currentUser.email == null) {
                                Navigator.pop(context);
                                setState(() {
                                  isEmailVerified = false;
                                  _emailCodeSent = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '안전한 보안을 위해 이메일 인증이 한 번 더 필요합니다.\n\'이메일 인증\' 버튼을 눌러 다시 한 번 인증 부탁드립니다.',
                                      textAlign: TextAlign.center,
                                    ),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                return;
                              }
                              else{
                                await currentUser.updatePassword(password);
                                print('비밀번호 추가2 : ${password}');
                              }

                            } else {

                              // Firebase Authentication에 이메일과 비밀번호로 새 사용자 생성
                              UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                email: email,
                                password: password,  // 비밀번호 추가
                              );
                              currentUser = userCredential.user;
                            }

                            String userUid = currentUser?.uid ?? '';


                            DateTime now = DateTime.now();
                            String formattedDate = DateFormat('yyyy-MM-dd').format(now);


                            final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
                            await usersCollection.doc(nickname).set({
                              'uid': userUid,
                              'nickname': nickname,
                              'email': email,
                              'joined_date': formattedDate,
                              'grade': 3.0,
                              'bank' : _bankName,
                              'department' : _selectedDepartment,
                              'accountNumber' : accountNumber,
                              'profilePhotoURL' : '',
                              'phoneNumber' : _phoneController.text,
                            });

                            await createAndAssignReferralCode(nickname);

                            if(isReferralCodeVerified){
                              print(isReferralCodeVerified);
                              await incrementReferralCount(_referralCodeController.text);

                            }

                            else(isReferralCodeVerified){
                              print(isReferralCodeVerified);

                            };


                            // 다이어로그를 닫음
                            Navigator.pop(context);


                            Future.delayed(Duration(milliseconds: 0), () async {


                              // ScaffoldMessenger 호출을 여기서 안전하게 실행
                              WidgetsBinding.instance?.addPostFrameCallback((_) {
                                if (mounted) {
                                  ScaffoldMessenger.of(rootContext).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '축하합니다!. \n회원가입이 완료되었습니다.',
                                        textAlign: TextAlign.center,
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              });

                              Navigator.pushReplacement(
                                rootContext,
                                MaterialPageRoute(builder: (context) => LoginScreen()), // 로그인 화면으로 이동
                              );
                            });

                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '회원가입 도중 에러가 발생하였습니다. \n다시 시도해 주세요.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                            print("회원가입 실패: $e");
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero, // 여백을 제거하여 Divider와 붙도록 설정
                        ),
                        child: Center(
                          child: Text(
                            '확인',
                            style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFF1D4786)
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }
  }

  //휴대전화 인증
  // _onPhoneNumberChanged() {
  //   String value = _phoneController.text;
  //   setState(() {
  //     if (value == null || value.trim().isEmpty) {
  //       _phoneNumberErrorText = '전화번호를 입력해주세요.';
  //     } else {
  //       _phoneNumberErrorText = null;
  //     }
  //   });
  // }
  //
  // String formatPhoneNumber(String phoneNumber) {
  //   // 만약 010으로 시작하면 +82로 변경
  //   if (phoneNumber.startsWith('010')) {
  //     return phoneNumber.replaceFirst('010', '+8210');
  //   }
  //   // 그 외에는 그대로 반환
  //   return phoneNumber;
  // }
  //
  //
  // // 전화번호로 인증 요청
  // Future<void> _verifyPhoneNumber() async {
  //   if (!_isPhoneButtonEnabled) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("잠시만 기다려 주세요!", textAlign: TextAlign.center),
  //         duration: Duration(seconds: 1),
  //       ),
  //     );
  //     return; // 버튼이 비활성화되어 있으면 아무것도 하지 않음
  //   }
  //
  //   if (_phoneController.text.length == 11) {
  //     setState(() {
  //       _isPhoneButtonEnabled = false; // 버튼 비활성화
  //     });
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("인증번호를 전송하고 있습니다.", textAlign: TextAlign.center),
  //         duration: Duration(seconds: 1),
  //       ),
  //     );
  //
  //     String formattedPhoneNumber = formatPhoneNumber(_phoneController.text);
  //     await _auth.verifyPhoneNumber(
  //       phoneNumber: formattedPhoneNumber,
  //       verificationCompleted: (PhoneAuthCredential credential) async {
  //         await _auth.signInWithCredential(credential);
  //         print('자동 인증 성공');
  //         User? currentUser = FirebaseAuth.instance.currentUser;
  //         setState(() {
  //           _isPhoneButtonEnabled = true; // 인증 성공 시 버튼 재활성화
  //         });
  //       },
  //
  //       verificationFailed: (FirebaseAuthException e) {
  //         print('인증 실패: ${e.message}');
  //         String errorMessage = '';
  //         switch (e.code) {
  //           case 'invalid-phone-number':
  //             errorMessage = '잘못된 전화번호 형식입니다. \n올바른 전화번호 형식으로 입력해주세요.';
  //             break;
  //           case 'too-many-requests':
  //             errorMessage = 'SMS 인증 한도(일일 5회)를 초과했습니다. \n다음 날에 다시 시도해주세요.';
  //             break;
  //           case 'quota-exceeded':
  //             errorMessage = 'SMS 인증 한도를 초과했습니다. \n나중에 다시 시도해주세요.';
  //             break;
  //           case 'missing-phone-number':
  //             errorMessage = '전화번호를 입력해주세요.';
  //             break;
  //           case 'operation-not-allowed':
  //             errorMessage = '전화번호 인증이 비활성화되어 있습니다. \n관리자에게 문의해 주세요.';
  //             break;
  //           case 'Invalid format':
  //             errorMessage = '잘못된 전화번호입니다. \n확인 후 다시 입력해주세요.';
  //             break;
  //           default:
  //             errorMessage = '${e.code}';
  //         }
  //
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(errorMessage, textAlign: TextAlign.center),
  //             duration: Duration(seconds: 2),
  //           ),
  //         );
  //
  //         setState(() {
  //           _isPhoneButtonEnabled = true; // 인증 실패 시 버튼 재활성화
  //         });
  //       },
  //
  //       codeSent: (String verificationId, int? resendToken) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text("인증번호가 전송되었습니다!", textAlign: TextAlign.center),
  //             duration: Duration(seconds: 2),
  //           ),
  //         );
  //         print('인증 코드 전송');
  //         setState(() {
  //           _verificationId = verificationId;
  //           _codeSent = true;
  //         });
  //
  //         _startTimer();
  //         setState(() {
  //           _isPhoneButtonEnabled = true; // 인증 코드 전송 시 버튼 재활성화
  //         });
  //       },
  //
  //       codeAutoRetrievalTimeout: (String verificationId) {
  //         _verificationId = verificationId;
  //         setState(() {
  //           _isPhoneButtonEnabled = true; // 인증 시간 초과 시 버튼 재활성화
  //         });
  //       },
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('잘못된 전화번호입니다. \n확인 후 다시 입력해주세요.', textAlign: TextAlign.center),
  //         duration: Duration(seconds: 2),
  //       ),
  //     );
  //   }
  // }
  //
  //
  // // 타이머 시작
  // void _startTimer() {
  //   setState(() {
  //     _remainingTime = 300; // 5분(300초) 설정
  //   });
  //
  //   _timer?.cancel(); // 기존 타이머가 있으면 취소
  //
  //   _timer = Timer.periodic(Duration(seconds: 1), (timer) {
  //     setState(() {
  //       if (_remainingTime > 0) {
  //         _remainingTime--;
  //       } else {
  //         _timer?.cancel();
  //         _codeSent = false; // 시간이 초과되면 코드 입력을 막고 재요청
  //         _verificationId = ""; // 기존 verificationId 무효화
  //         print("인증 시간이 초과되었습니다. 다시 시도해주세요.");
  //       }
  //     });
  //   });
  // }
  //
  // // 사용자가 입력한 인증 코드로 로그인
  // Future<void> _signInWithCode() async {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(
  //         '인증번호 확인 중입니다! \n잠시만 기다려주세요.',
  //         textAlign: TextAlign.center,
  //       ),
  //       duration: Duration(seconds: 2),
  //     ),
  //   );
  //
  //   if (_verificationId.isNotEmpty && _remainingTime > 0) { // 타이머가 유효할 때만 인증
  //     try {
  //       User? currentUser = FirebaseAuth.instance.currentUser;
  //
  //       PhoneAuthCredential credential = PhoneAuthProvider.credential(
  //         verificationId: _verificationId, // 저장된 verificationId 사용
  //         smsCode: _codeController.text,
  //       );
  //
  //       // 현재 사용자가 이메일 계정으로 로그인된 상태라면, 전화번호를 연동
  //       if (currentUser != null && currentUser.email != null) {
  //         // 이미 이메일로 로그인한 상태에서 전화번호 인증을 진행
  //         await currentUser.updatePhoneNumber(credential); // 이메일 계정에 전화번호를 연동
  //         print('전화번호와 이메일 계정이 성공적으로 연동되었습니다.');
  //       }
  //
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text("인증이 완료되었습니다!",
  //               textAlign: TextAlign.center),
  //           duration: Duration(seconds: 2),
  //         ),
  //       );
  //       setState(() {
  //         _successAuth= true;
  //       });
  //       _timer?.cancel();
  //
  //     } on FirebaseAuthException catch (e) {
  //
  //       if (e.code == 'invalid-verification-code') {
  //         // 인증 실패 시 스낵바 표시
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(
  //               '입력하신 인증번호가 올바르지 않습니다.\n다시 한 번 확인해 주세요.',
  //               textAlign: TextAlign.center,
  //             ),
  //             duration: Duration(seconds: 2),
  //
  //           ),
  //         );
  //       }
  //       else if (e.code == 'credential-already-in-use') {
  //         // 인증 실패 시 스낵바 표시
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text(
  //               '해당 전화번호는 이미 사용 중입니다. \n다른 번호로 시도해 주세요.',
  //               textAlign: TextAlign.center,
  //             ),
  //             duration: Duration(seconds: 2),
  //
  //           ),
  //         );
  //       }
  //
  //
  //       print('인증 실패: ${e.message}');
  //     }catch (e) {
  //       print('인증 실패: $e');
  //     }
  //   } else {
  //     print('verificationId가 비어있거나 시간이 초과되었습니다.');
  //   }
  // }


  _onNicknameChanged() {
    RegExp onlyConsonants = RegExp(r'^[ㄱ-ㅎ]+$');
    RegExp onlyVowels = RegExp(r'^[ㅏ-ㅣ]+$');
    String pattern = r'^[a-zA-Zㄱ-ㅎ가-힣0-9]+$';
    RegExp regex = RegExp(pattern);
    String value = _nicknameController.text;
    setState(() {
      if (value == null || value.trim().isEmpty) {
        _usernicknameErrorText = '닉네임을 입력해주세요.';
      } else if (!regex.hasMatch(value)) {
        _usernicknameErrorText = '닉네임은 영문, 한글, 숫자만 \n사용 가능합니다.';
      } else if(onlyConsonants.hasMatch(_nicknameController.text) || onlyVowels.hasMatch(_nicknameController.text)){
        _usernicknameErrorText = '자음, 모음만으로는 \n구성될 수 없습니다.';
      } else {
        _usernicknameErrorText = null;
        // _isNicknameAvailable = false;
        // _buttonText = '중복확인';
      }
    });
  }

  _onpasswordChanged() {
    String pattern = r'^(?=.*[@$!%*#?&_-])[A-Za-z\d@$!%*#?&_-]{8,16}$';
    RegExp regex = new RegExp(pattern);
    String value = _passwordController.text;
    setState(() {
      if (value == null || value.trim().isEmpty) {
        _userpasswordErrorText = '비밀번호를 입력해주세요.';
      } else if (!regex.hasMatch(value)) {
        _userpasswordErrorText = '8~16자의 영문 대/소문자, 숫자, 적어도 한개의 특수문자만 사용 가능합니다.';
      } else {
        _userpasswordErrorText = null;
      }
    });
  }

  _confirmPasswordChanged() {
    String value = _confirmPasswordController.text;
    setState(() {
      if (value == null || value.trim().isEmpty) {
        _confirmPasswordErrorText = '비밀번호를 입력해주세요.';
      }
      else if (  _confirmPasswordController.text != _passwordController.text) {
        _confirmPasswordErrorText =  '비밀번호가 일치하지 않습니다.';
      }
      else {
        _confirmPasswordErrorText = null;
      }
    });
  }

  _onEmaildChanged() {
    String pattern = r"^[a-zA-Z0-9]+$";// 영문과 또는 숫자를 포함해야 함
    RegExp regex = new RegExp(pattern);
    String value = _emailUserController.text;
    setState(() {
      if (value == null || value.trim().isEmpty) {
        _userEmailErrorText = '아이디를 입력해주세요.';
      } else if (!regex.hasMatch(value)) {
        _userEmailErrorText = "영문과 숫자만 가능합니다.";
      } else {
        _userEmailErrorText = null;
      }
      isEmailVerified = false; // 이메일 필드가 변경되면 인증 상태를 false로 설정
    });
  }


  _onAccountNameChanged() {
    String value = _accountNameController.text;
    setState(() {
      if (value == null || value.trim().isEmpty) {
        _accountNameErrorText = '계좌명을 입력해주세요.';
      } else {
        _accountNameErrorText = null;
      }
    });
  }

  _onAccountNumberChanged() {
    String value = _accountNumberController.text;
    setState(() {
      if (value == null || value.trim().isEmpty) {
        _accountNumberErrorText = '계좌번호를 입력해주세요.';
      } else {
        _accountNumberErrorText = null;
      }
    });
  }

// 이메일 중복 여부 확인
  Future<bool> _checkEmailAvailability() async {
    final email = _emailUserController.text.trim() + "@" + _dropdownValue!;

    try {
      // 이 코드에서 await는 FirebaseFirestore.instance.collection('users').where('email', isEqualTo: email).get() 작업이 완료될 때까지 다음 코드로 넘어가지 않게 합니다. 이 get() 메서드는 네트워크를 통해 Firebase의 Firestore 데이터베이스에서 데이터를 가져오는 작업이므로, 이 작업이 얼마나 걸릴지 확실하지 않습니다.
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('현재 존재하는 이메일 입니다.', textAlign: TextAlign.center,),
            // behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
        return false;
      }
      return true;
    } catch (e) {
      print('이메일 확인 오류: $e');
      return false;
    }
  }

  bool _nicknameValidateFields() {
    RegExp onlyConsonants = RegExp(r'^[ㄱ-ㅎ]+$');
    RegExp onlyVowels = RegExp(r'^[ㅏ-ㅣ]+$');

    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('닉네임을 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    } else if (onlyConsonants.hasMatch(_nicknameController.text) || onlyVowels.hasMatch(_nicknameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('자음, 모음만으로는 구성될 수 없습니다.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    } else if (!RegExp(r'^[a-zA-Zㄱ-ㅎ가-힣0-9]+$').hasMatch(_nicknameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('닉네임은 영문, 한글, 숫자만 사용 가능합니다.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }

    // 4. 닉네임이 금지된 목록에 있을 때
    if (!NicknameValidator.isNicknameValid(_nicknameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('사용할 수 없는 닉네임입니다.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }

    return true;
  }


//닉네임 맥스 length
  void _checkMaxLength(TextEditingController controller, int maxLength) {
    if (controller.text.length == maxLength && !_snackBarShown) {
      controller.text = controller.text.substring(0, maxLength);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '최대 ${maxLength}글자까지 입력 가능합니다!',
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 1),
        ),
      );
      _snackBarShown = true;
    } else if (controller.text.length < maxLength){
      _snackBarShown = false;
    }
  }

  void _checkNicknameAvailabilityAndValidate() {
    HapticFeedback.lightImpact();
    if(_nicknameValidateFields()) {
      buildCustomHelpDialog();
    }
  }


  bool _validateFields() {

    if(_isNicknameAvailable == false){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('중복확인을 진행해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }

    if (_emailUserController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일을 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('전화번호를 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }

    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('인증번호를 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }


    if(isEmailVerified == false){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이메일 인증을 완료해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }

    if(_successAuth == false){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('휴대전화 인증을 완료해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }

    if(_isEULAChecked == false || _isPrivacyPolicyChecked == false){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이용 약관 및 개인정보 처리방침에 동의해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }



    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('닉네임을 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }


    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호를 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }

    if (!RegExp(r'^(?=.*[@$!%*#?&_-])[A-Za-z\d@$!%*#?&_-]{8,16}$').hasMatch(_passwordController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호는 8~16자의 문자, 숫자, 적어도 한개의 특수기호를 사용해야 합니다.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }


    if (_confirmPasswordController.text != _passwordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호가 일치하지 않습니다.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }


    if (_dropdownValue == '학교 메일 선택') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('학교 메일을 선택해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }

    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('학과명을 입력해주세요. \n학과별 랭킹을 위해 사용됩니다.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }

    if (_bankName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('계좌명을 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }

    if (_accountNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('계좌번호를 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }
    return true;
  }




  //구글로그인 인증
  Future<void> _signInWithGoogle() async {
    try {
      // 이전에 로그인한 계정 로그아웃
      await _googleSignIn.signOut();

      String userEmail = _emailUserController.text.trim();
      if (_dropdownValue == null) {
        setState(() {
          _userEmailErrorText = '학교 메일을 선택해 주세요';
        });
        return;
      }

      String fullEmail = '$userEmail@$_dropdownValue';

      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // 사용자가 로그인 취소
        return;
      }

      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );


      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      // 성공적으로 로그인
      if (user != null && user.email == fullEmail) {
        setState(() {
          isEmailVerified = true;
          _userEmailErrorText = null; // 이메일 인증 성공 시 오류 메시지 제거
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일 인증이 완료되었습니다.', textAlign: TextAlign.center,),
            duration: Duration(seconds: 2),
          ),
        );

      } else {
        // 이메일이 일치하지 않으면 로그아웃
        await _auth.signOut();
        setState(() {
          _userEmailErrorText = "다시 시도해주세요.";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일이 일치하지 않습니다.', textAlign: TextAlign.center,),
            // behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }

    } catch (e) {
      // 로그인 오류 처리
      print(e);
    }
  }


// 이메일 인증
  Future<void> _requestEmailVerification() async {
    if (!_isEmailButtonEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("잠시만 기다려 주세요!", textAlign: TextAlign.center),
          duration: Duration(seconds: 1),
        ),
      );
      return; // 버튼이 비활성화되어 있으면 아무것도 하지 않음
    }

    try {
      setState(() {
        _isEmailButtonEnabled = false; // 버튼 비활성화
      });

      String email = _emailUserController.text.trim();
      String password = "T3mp0r@ryP@ssw0rd#2024!";

      if (_dropdownValue == null) {
        setState(() {
          _userEmailErrorText = '학교 메일을 선택해 주세요';
          _isEmailButtonEnabled = true; // 버튼 재활성화
        });
        return;
      }

      String fullEmail = '$email@$_dropdownValue';
      print(fullEmail);

      try {
        // 이미 존재하는 계정에 로그인 시도
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: fullEmail,
          password: password,
        );

        User? currentUser = userCredential.user;
        if (currentUser != null) {
          await currentUser.delete();

          UserCredential newUserCredential = await _auth.createUserWithEmailAndPassword(
            email: fullEmail,
            password: password,
          );

          await newUserCredential.user!.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '이메일 인증 링크가 전송되었습니다!',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                      ),
                    ),
                    TextSpan(
                      text: '\n\n⚠️구글을 통해 발송된 해외 메일이므로 \n인증 메일이 스팸메일함에 있을 수 있습니다.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              duration: Duration(seconds: 3),
            ),
          );

          setState(() {
            _emailCodeSent = true;
            _isEmailButtonEnabled = true; // 버튼 재활성화
          });
          _startEmailVerificationTimer();

          return;
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
            email: fullEmail,
            password: password,
          );
          await userCredential.user!.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '이메일 인증 링크가 전송되었습니다!',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                      ),
                    ),
                    TextSpan(
                      text: '\n\n⚠️구글을 통해 발송된 해외 메일이므로 \n인증 메일이 스팸메일함에 있을 수 있습니다.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              duration: Duration(seconds: 2),
            ),
          );
          setState(() {
            _emailCodeSent = true;
            _isEmailButtonEnabled = true; // 버튼 재활성화
          });
          _startEmailVerificationTimer();
        }  else if (e.code == 'wrong-password') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('이미 존재하는 계정입니다. \n다른 이메일을 사용해 주세요.', textAlign: TextAlign.center),
              duration: Duration(seconds: 2),
            ),
          );
          setState(() {
            _isEmailButtonEnabled = true; // 버튼 재활성화
          });
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('이메일 인증 요청에 실패했습니다. 다시 시도해주세요. \n${e.code}', textAlign: TextAlign.center),
              duration: Duration(seconds: 2),
            ),
          );
          setState(() {
            _isEmailButtonEnabled = true; // 버튼 재활성화
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이메일 인증 요청에 실패했습니다. 다시 시도해주세요.', textAlign: TextAlign.center),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _isEmailButtonEnabled = true; // 버튼 재활성화
      });
    }
  }


  void _startEmailVerificationTimer() {
    setState(() {
      _remainingVerificationTime = 300; // 5분(300초) 설정
    });

    _verificationTimer?.cancel(); // 기존 타이머가 있으면 취소

    _verificationTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingVerificationTime > 0) {
          _remainingVerificationTime--; // 남은 시간을 1초씩 감소
        } else {
          _verificationTimer?.cancel(); // 시간이 초과되면 타이머를 취소
          _emailCodeSent = false; // 인증 요청을 다시 할 수 있도록 설정
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("인증 시간이 초과되었습니다. \n다시 시도해주세요.", textAlign: TextAlign.center),
              duration: Duration(seconds: 2),
            ),
          );
        }

      });
    });
  }

  Future<void> _confirmEmailVerification() async {
    try {
      await _auth.currentUser!.reload(); // 사용자 정보를 새로 고침하여 인증 상태 확인
      if (_auth.currentUser!.emailVerified) {
        setState(() {
          isEmailVerified = true; // 이메일 인증 상태를 true로 변경
          _verificationTimer?.cancel(); // 타이머를 취소
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("이메일 인증이 완료되었습니다!", textAlign: TextAlign.center),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // 인증이 완료되지 않은 경우
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("이메일 인증이 완료되지 않았습니다.", textAlign: TextAlign.center),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // 인증 확인 실패 예외 처리
      print('이메일 인증 확인 실패: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
        child: AppBar(
          title: Text(
            '회원가입',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 19,
              height: 1.0,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),

          centerTitle: true,
          backgroundColor: Color(0xFF1D4786),
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_outlined), // '<' 모양의 뒤로가기 버튼 아이콘
            color: Colors.white, // 아이콘 색상
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context); // 뒤로가기 기능
            },
          ),
          // 상단 왼쪽 빈 공간을 만들기 위해 빈 SizedBox를 사용
          actions: [

          ],
        ),
      ),

      body: GestureDetector(
        onTap: () {
          // 화면의 다른 부분을 터치했을 때 포커스 해제
          FocusScope.of(context).unfocus();
        },
        child: Container(
          height: double.infinity,
          color: Color(0xFFFFFFFF),
          child: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.fromLTRB(20, 0, 18, 88),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.fromLTRB(0, 0, 2, 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 20),
                                          Container(
                                            margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                            child: Align(
                                              alignment: Alignment.topLeft,
                                              child: RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: '이메일', // 원래 텍스트
                                                      style: TextStyle(
                                                        fontFamily: 'Pretendard',
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 15,
                                                        height: 1,
                                                        letterSpacing: -0.4,
                                                        color: Color(0xFF424242),
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: '  본인 학교 웹메일로 진행해주세요!', // 더 작고 옅은 텍스트
                                                      style: TextStyle(
                                                        fontFamily: 'Pretendard',
                                                        fontWeight: FontWeight.w400,
                                                        fontSize: 12, // 더 작은 크기
                                                        height: 1.5,
                                                        letterSpacing: -0.4,
                                                        color: Color(0xFF767676), // 더 옅은 색상
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  color: Color(0xFFFFFFFF),
                                                  margin: EdgeInsets.fromLTRB(0, 0, 6, 0), // 상단 컨테이너와 동일한 마진
                                                  child: Align(
                                                    alignment: Alignment.topLeft,
                                                    child: TextFormField(
                                                      cursorColor: Color(0xFF1D4786),
                                                      controller: _emailUserController,
                                                      textInputAction: TextInputAction.next,
                                                      onTap: () {
                                                        HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                                                      },
                                                      decoration: InputDecoration(
                                                        contentPadding: EdgeInsets.fromLTRB(15, 15, 15, 15), // 상단 컨테이너의 패딩과 일치시킴
                                                        hintText: '이메일 입력',
                                                        hintStyle: TextStyle(
                                                          fontFamily: 'Pretendard',
                                                          fontWeight: FontWeight.w400, // 상단 텍스트 스타일과 동일하게 설정
                                                          fontSize: 16, // 상단 텍스트 스타일과 동일하게 설정
                                                          height: 1,
                                                          letterSpacing: -0.4,
                                                          color: Color(0xFF767676),

                                                        ),
                                                        enabled: !isEmailVerified,
                                                        errorText: _userEmailErrorText,
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(8), // 동일한 테두리 반경
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: _emailHasText ? Color(0xFF1D4786) : Color(0xFFD0D0D0),
                                                          ), // 텍스트가 있으면 인디고, 없으면 회색
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(color: Color(0xFF1D4786)), // 포커스 시 색상 변경
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        counterText: '', // 하단의 '0/10' 텍스트를 숨김
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                margin: EdgeInsets.fromLTRB(0, 16, 8.7, 16),
                                                child: Text(
                                                  '@',
                                                  style: TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 16,
                                                    height: 1,
                                                    letterSpacing: -0.4,
                                                    color: Color(0xFF767676),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () {
                                                    HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                                                    isEmailVerified
                                                        ?  ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '이메일 인증이 완료된 도메인입니다.',
                                                          textAlign: TextAlign.center,
                                                        ),
                                                        duration: Duration(seconds: 1),
                                                      ),
                                                    )
                                                        : showCustomBottomSheet(context);
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: _dropdownValue != null ? Color(0xFF1D4786) : Color(0xFFD0D0D0)),
                                                      borderRadius: BorderRadius.circular(8),
                                                      color: Color(0xFFFFFFFF),
                                                    ),
                                                    child: Container(
                                                      padding: EdgeInsets.fromLTRB(15, 15, 15, 15),


                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              _dropdownValue ?? '선택',
                                                              style: TextStyle(
                                                                fontFamily: 'Pretendard',
                                                                fontWeight: FontWeight.w400,
                                                                fontSize: 16,
                                                                height: 1,
                                                                letterSpacing: -0.4,
                                                                color: _dropdownValue != null ? Color(0xFF222222): Color(0xFF767676),
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                          Container(
                                                            margin: EdgeInsets.fromLTRB(0, 4, 0, 4),
                                                            child: ClipRRect(
                                                              borderRadius: BorderRadius.circular(1),
                                                              child: SizedBox(
                                                                width: 12,
                                                                height: 8,
                                                                child: SvgPicture.asset(
                                                                    'assets/pigma/Polygon.svg',
                                                                    color: _dropdownValue != null ? Color(0xFF1D4786) : Color(0xFF424242)
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),


                                    _emailIsNotGoogle && _emailCodeSent
                                        ?
                                    // 구글로그인이 아닐때
                                    Column(
                                      children: [
                                        isEmailVerified
                                            ? Container()
                                            : Column(
                                          children: [
                                            Center(
                                              child: Text(
                                                "남은 시간: $_remainingVerificationTime 초",
                                                style: TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  height: 1,
                                                  letterSpacing: -0.4,
                                                  color: Color(0xFF1D4786),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                            Center(
                                              child: Text(
                                                "혹시 메일함에서 찾을 수 없으시다면, 스팸메일함도 한 번 확인해 주세요!",
                                                style: TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 11,
                                                  height: 1,
                                                  letterSpacing: -0.4,
                                                  color: Color(0xFF767676), // 더 옅은 색상
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 5),
                                          ],
                                        ),
                                      ],
                                    )


                                        : Container(),

                                    GestureDetector(
                                      onTap:(){
                                        // 이메일 인증
                                        if(_emailIsNotGoogle){
                                          HapticFeedback.lightImpact();

                                          if(_emailCodeSent) { //이메일 전송
                                            _emailUserController.text.isNotEmpty
                                                ? _confirmEmailVerification()
                                                : null;
                                          }

                                          else{ //이메일 전송 안됨
                                            _emailUserController.text.isNotEmpty
                                                ? _requestEmailVerification()
                                                : null;
                                          }
                                        }

                                        //구글 인증
                                        else if(!_emailIsNotGoogle) {
                                          HapticFeedback.lightImpact();
                                          _emailUserController.text.isNotEmpty
                                              ? _signInWithGoogle()
                                              : null;
                                        }
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: _emailUserController.text.isNotEmpty ? Color(0xFF1D4786):Color(0xFFF6F7F8)),
                                          borderRadius: BorderRadius.circular(8),
                                          color: _emailUserController.text.isNotEmpty ? Color(0xFF1D4786) : Color(0xFFF6F7F8),
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.fromLTRB(3.3, 15, 0, 15),
                                          child:
                                          _emailCodeSent
                                              ?
                                          Text(
                                            isEmailVerified ? '인증 완료' :'인증 하기',
                                            style: TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                              height: 1,
                                              letterSpacing: -0.4,
                                              color: _emailUserController.text.isNotEmpty ? Colors.white : Color(0xFF767676),
                                            ),
                                            textAlign: TextAlign.center,
                                          )
                                              :
                                          Text(
                                            isEmailVerified ? '인증 완료' :'이메일 인증',
                                            style: TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                              height: 1,
                                              letterSpacing: -0.4,
                                              color: _emailUserController.text.isNotEmpty ? Colors.white : Color(0xFF767676),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),




                              //휴대전화 인증
                              // Container(
                              //   margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                              //   child: Column(
                              //     mainAxisAlignment: MainAxisAlignment.start,
                              //     crossAxisAlignment: CrossAxisAlignment.start,
                              //     children: [
                              //       Container(
                              //         margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                              //         child: Align(
                              //           alignment: Alignment.topLeft,
                              //           child: Text(
                              //             '휴대폰 인증',
                              //             style: TextStyle(
                              //               fontFamily: 'Pretendard',
                              //               fontWeight: FontWeight.w600,
                              //               fontSize: 15,
                              //               height: 1,
                              //               letterSpacing: -0.4,
                              //               color: Color(0xFF424242),
                              //             ),
                              //           ),
                              //         ),
                              //       ),
                              //
                              //
                              //       Container(
                              //         width: double.infinity,
                              //         margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                              //         decoration: BoxDecoration(
                              //           color: Color(0xFFFFFFFF),
                              //         ),
                              //         child: Align(
                              //           alignment: Alignment.topLeft,
                              //           child: TextFormField(
                              //             onTap: () {
                              //               if(isEmailVerified == false){
                              //                 HapticFeedback.lightImpact(); // 햅틱 피드백
                              //                 ScaffoldMessenger.of(context).showSnackBar(
                              //                   SnackBar(
                              //                     content: Text(
                              //                       '이메일 인증을 먼저 완료해주세요.',
                              //                       textAlign: TextAlign.center,
                              //                     ),
                              //                     duration: Duration(seconds: 2),
                              //                   ),
                              //                 );
                              //               }
                              //               if(!_successAuth) {
                              //                 HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                              //               }
                              //             },
                              //             enabled: !_successAuth && !_codeSent && isEmailVerified,
                              //             controller: _phoneController,
                              //             textInputAction: TextInputAction.done,
                              //             cursorColor: Color(0xFF1D4786),
                              //             keyboardType: TextInputType.phone, // 숫자 입력 전용 키보드 설정
                              //             onFieldSubmitted: (value) {
                              //               HapticFeedback.lightImpact(); // 다음 필드로 이동할 때 햅틱 피드백
                              //             },
                              //             decoration: InputDecoration(
                              //               hintText: isEmailVerified ? '전화번호를 입력해주세요.' : '이메일 인증을 먼저 완료해주세요.',
                              //               hintStyle: TextStyle(
                              //                 fontFamily: 'Pretendard',
                              //                 fontWeight: FontWeight.w500,
                              //                 fontSize: 16,
                              //                 height: 1,
                              //                 letterSpacing: -0.4,
                              //                 color: Color(0xFF767676),
                              //               ),
                              //               contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12), // 내부 여백 조정
                              //               border: OutlineInputBorder(
                              //                 borderRadius: BorderRadius.circular(10),
                              //               ),
                              //               enabledBorder: OutlineInputBorder(
                              //                 borderSide: BorderSide(
                              //                   color: _phoneNumberHasText ?  Color(0xFF1D4786): Color(0xFFD0D0D0),
                              //                 ), // 텍스트가 있으면 인디고, 없으면 회색
                              //                 borderRadius: BorderRadius.circular(8),
                              //               ),
                              //               focusedBorder: OutlineInputBorder(
                              //                 borderSide: BorderSide(color: Color(0xFF1D4786)), // 포커스 시 색상 변경
                              //                 borderRadius: BorderRadius.circular(8),
                              //               ),
                              //               errorText: _phoneNumberErrorText,
                              //             ),
                              //             validator: (value) {
                              //               if (value == null || value.trim().isEmpty) {
                              //                 return '전화번호를 입력해주세요.';
                              //               }
                              //               return null;
                              //             },
                              //           ),
                              //         ),
                              //       ),
                              //
                              //       _codeSent
                              //           ? Column(
                              //         children: [
                              //           Container(
                              //             width: double.infinity,
                              //             margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                              //             decoration: BoxDecoration(
                              //               color: Color(0xFFFFFFFF),
                              //             ),
                              //             child: Align(
                              //               alignment: Alignment.topLeft,
                              //               child: TextFormField(
                              //                 onTap: () {
                              //                   if(!_successAuth) {
                              //                     HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                              //                   }
                              //                 },
                              //                 enabled: !_successAuth,
                              //                 controller: _codeController,
                              //                 textInputAction: TextInputAction.done,
                              //                 cursorColor: Color(0xFF1D4786),
                              //                 keyboardType: TextInputType.phone, // 숫자 입력 전용 키보드 설정
                              //                 onFieldSubmitted: (value) {
                              //                   HapticFeedback.lightImpact(); // 다음 필드로 이동할 때 햅틱 피드백
                              //                 },
                              //                 decoration: InputDecoration(
                              //                   hintText: '인증번호를 입력해주세요.',
                              //                   hintStyle: TextStyle(
                              //                     fontFamily: 'Pretendard',
                              //                     fontWeight: FontWeight.w500,
                              //                     fontSize: 16,
                              //                     height: 1,
                              //                     letterSpacing: -0.4,
                              //                     color: Color(0xFF767676),
                              //                   ),
                              //                   contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 12), // 내부 여백 조정
                              //                   border: OutlineInputBorder(
                              //                     borderRadius: BorderRadius.circular(10),
                              //                   ),
                              //                   enabledBorder: OutlineInputBorder(
                              //                     borderSide: BorderSide(
                              //                       color: _codeSentHasText ?  Color(0xFF1D4786): Color(0xFFD0D0D0),
                              //                     ), // 텍스트가 있으면 인디고, 없으면 회색
                              //                     borderRadius: BorderRadius.circular(8),
                              //                   ),
                              //                   focusedBorder: OutlineInputBorder(
                              //                     borderSide: BorderSide(color: Color(0xFF1D4786)), // 포커스 시 색상 변경
                              //                     borderRadius: BorderRadius.circular(8),
                              //                   ),
                              //                   errorText: _codeSentErrorText,
                              //                 ),
                              //                 validator: (value) {
                              //                   if (value == null || value.trim().isEmpty) {
                              //                     return '인증번호를 입력해주세요.';
                              //                   }
                              //                   return null;
                              //                 },
                              //               ),
                              //             ),
                              //           ),
                              //           _successAuth ? Container()
                              //               : Text("남은 시간: $_remainingTime 초",   style: TextStyle(
                              //             fontFamily: 'Pretendard',
                              //             fontWeight: FontWeight.w600,
                              //             fontSize: 13,
                              //             height: 1,
                              //             letterSpacing: -0.4,
                              //             color: Color(0xFF1D4786),
                              //           )
                              //           ),
                              //           SizedBox(height: 5),
                              //         ],
                              //       )
                              //           : Container(),
                              //
                              //       GestureDetector(
                              //         onTap:(){
                              //           if(_phoneController.text.isNotEmpty && !_successAuth) {
                              //             HapticFeedback.lightImpact();
                              //             _codeSent ? _signInWithCode() : _verifyPhoneNumber();
                              //           }
                              //           if(_successAuth){
                              //             HapticFeedback.lightImpact();
                              //             ScaffoldMessenger.of(context).showSnackBar(
                              //               SnackBar(
                              //                 content: Text("인증이 완료되었습니다!",
                              //                     textAlign: TextAlign.center),
                              //                 duration: Duration(seconds: 3),
                              //               ),
                              //             );
                              //           }
                              //         },
                              //         child: Container(
                              //           width: double.infinity,
                              //           decoration: BoxDecoration(
                              //             border: Border.all(color: _phoneController.text.isNotEmpty ? Color(0xFF1D4786):Color(0xFFF6F7F8)),
                              //             borderRadius: BorderRadius.circular(8),
                              //             color: _phoneController.text.isNotEmpty ? Color(0xFF1D4786) : Color(0xFFF6F7F8),
                              //           ),
                              //           child: Container(
                              //             padding: EdgeInsets.fromLTRB(3.3, 15, 0, 15),
                              //             child:
                              //             _successAuth ?
                              //             Text(
                              //               '인증 완료',
                              //               style: TextStyle(
                              //                 fontFamily: 'Pretendard',
                              //                 fontWeight: FontWeight.w500,
                              //                 fontSize: 16,
                              //                 height: 1,
                              //                 letterSpacing: -0.4,
                              //                 color: _phoneController.text.isNotEmpty ? Colors.white : Color(0xFF767676),
                              //               ),
                              //               textAlign: TextAlign.center,
                              //             )
                              //                 :
                              //             Text(
                              //               _codeSent ? "인증 하기" : "인증 요청",
                              //               style: TextStyle(
                              //                 fontFamily: 'Pretendard',
                              //                 fontWeight: FontWeight.w500,
                              //                 fontSize: 16,
                              //                 height: 1,
                              //                 letterSpacing: -0.4,
                              //                 color: _phoneController.text.isNotEmpty ? Colors.white : Color(0xFF767676),
                              //               ),
                              //               textAlign: TextAlign.center,
                              //             ),
                              //           ),
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              // ),


                              //닉네임

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
                                          '닉네임',
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



                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            color: Color(0xFFFFFFFF),
                                            margin: EdgeInsets.fromLTRB(0, 0, 10, 0), // 상단 컨테이너와 동일한 마진
                                            child: Align(
                                              alignment: Alignment.topLeft,
                                              child: TextFormField(
                                                cursorColor: Color(0xFF1D4786),
                                                controller: _nicknameController,
                                                textInputAction: TextInputAction.done,
                                                enabled: !_isNicknameAvailable,
                                                onTap: () {
                                                  HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                                                },
                                                onFieldSubmitted: (value) {
                                                  _checkNicknameAvailabilityAndValidate();  // '다음'을 누르면 GestureDetector의 기능 실행
                                                },
                                                decoration: InputDecoration(
                                                  contentPadding: EdgeInsets.fromLTRB(15, 18, 15, 15), // 상단 컨테이너의 패딩과 일치시킴
                                                  hintText: '닉네임을 입력해주세요.',
                                                  hintStyle: TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    fontWeight: FontWeight.w400, // 상단 텍스트 스타일과 동일하게 설정
                                                    fontSize: 16, // 상단 텍스트 스타일과 동일하게 설정
                                                    height: 1,
                                                    letterSpacing: -0.4,
                                                    color: Color(0xFF767676),

                                                  ),
                                                  errorText: _usernicknameErrorText,
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8), // 동일한 테두리 반경
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: _nicknameHasText ? Color(0xFF1D4786) : Color(0xFFD0D0D0),
                                                    ), // 텍스트가 있으면 인디고, 없으면 회색
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(color: Color(0xFF1D4786)), // 포커스 시 색상 변경
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  counterText: '', // 하단의 '0/10' 텍스트를 숨김
                                                ),
                                                maxLength: 7,
                                                validator: (value) {
                                                  String pattern = r'[a-zA-Zㄱ-ㅎ가-힣-0-9]';
                                                  RegExp regex = RegExp(pattern);
                                                  if (value == null || value.trim().isEmpty) {
                                                    return '닉네임을 입력해주세요.';
                                                  }
                                                  return null;
                                                },
                                                onChanged: (value) {
                                                  setState(() {
                                                    _checkMaxLength(_nicknameController, 7);
                                                    _buttonText = '중복확인';

                                                  });
                                                },
                                              ),
                                            ),
                                          ),
                                        ),

                                        GestureDetector(
                                          onTap : (){
                                            _checkNicknameAvailabilityAndValidate();
                                          },
                                          child: Container(
                                            height: MediaQuery.of(context).size.height *0.065,
                                            width : MediaQuery.of(context).size.width * 0.23,
                                            decoration: BoxDecoration(
                                                border: Border.all(color: _nicknameController.text.isNotEmpty ? Color(0xFF1D4786): Color(0xFFE8EFF8)),
                                                borderRadius: BorderRadius.circular(8),
                                                color: _nicknameController.text.isNotEmpty ? Color(0xFF1D4786): Color(0xFFE8EFF8)
                                            ),
                                            child: Center(
                                              child: Text(
                                                _buttonText,
                                                style: TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                  height: 1,
                                                  letterSpacing: -0.4,
                                                  color: Color(0xFFFFFFFF),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              //비밀번호
                              Container(
                                margin: EdgeInsets.fromLTRB(0, 2, 2, 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          '비밀번호',
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
                                      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFFFFFF),
                                      ),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: TextFormField(
                                          onTap: () {
                                            HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                                          },
                                          controller: _passwordController,
                                          obscureText: _obscureText1,
                                          textInputAction: TextInputAction.next,
                                          cursorColor: Color(0xFF1D4786),
                                          onFieldSubmitted: (value) {
                                            HapticFeedback.lightImpact(); // 다음 필드로 이동할 때 햅틱 피드백

                                          },
                                          decoration: InputDecoration(
                                              hintText: '비밀번호를 입력해주세요.',
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
                                                  color: _passwordHasText ?  Color(0xFF1D4786): Color(0xFFD0D0D0),
                                                ), // 텍스트가 있으면 인디고, 없으면 회색
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: Color(0xFF1D4786)), // 포커스 시 색상 변경
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              errorText: _userpasswordErrorText,
                                              suffixIcon: GestureDetector(
                                                onTap: () {
                                                  HapticFeedback.lightImpact();
                                                  setState(() {
                                                    _obscureText1 = !_obscureText1;
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.fromLTRB(9, 9, 9, 9),
                                                  child: SvgPicture.asset(
                                                    _obscureText1
                                                        ? 'assets/pigma/close_eye.svg'  // 숨김 상태 아이콘
                                                        : 'assets/pigma/open_eye.svg',   // 표시 상태 아이콘
                                                    // fit: BoxFit.contain,  // 크기 조정 방식을 명시적으로 설정
                                                  ),
                                                ),
                                              )
                                          ),
                                          validator: (value) {
                                            String pattern = r'^[[A-Za-z\d@$!%*#?&_-]{8,16}$`';
                                            RegExp regex = RegExp(pattern);
                                            if (value == null || value.trim().isEmpty) {
                                              return '비밀번호를 입력해주세요.';
                                            } else if (!regex.hasMatch(value)) {
                                              return '비밀번호는 5~18자의 영문 소문자, 숫자, 특수기호(_)만 사용 가능합니다.';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),





                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFFFFFF),
                                      ),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: TextFormField(
                                          onTap: () {
                                            HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                                          },
                                          controller: _confirmPasswordController,
                                          obscureText: _obscureText2,
                                          textInputAction: TextInputAction.next,
                                          cursorColor: Color(0xFF1D4786),
                                          onFieldSubmitted: (value) {
                                            HapticFeedback.lightImpact(); // 다음 필드로 이동할 때 햅틱 피드백

                                          },
                                          decoration: InputDecoration(
                                              hintText: '비밀번호를 재입력해주세요.',
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
                                                  color: _confirmPasswordHasText ?  Color(0xFF1D4786): Color(0xFFD0D0D0),
                                                ), // 텍스트가 있으면 인디고, 없으면 회색
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: Color(0xFF1D4786)), // 포커스 시 색상 변경
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              errorText: _confirmPasswordErrorText,
                                              suffixIcon: GestureDetector(
                                                onTap: () {
                                                  HapticFeedback.lightImpact();
                                                  setState(() {
                                                    _obscureText2 = !_obscureText2;
                                                  });
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.fromLTRB(9, 9, 9, 9),
                                                  child: SvgPicture.asset(
                                                    _obscureText2
                                                        ? 'assets/pigma/close_eye.svg'  // 숨김 상태 아이콘
                                                        : 'assets/pigma/open_eye.svg',   // 표시 상태 아이콘
                                                    // fit: BoxFit.contain,  // 크기 조정 방식을 명시적으로 설정
                                                  ),
                                                ),
                                              )
                                          ),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return '비밀번호를 다시 확인해주세요.';
                                            } else if (value != _passwordController.text) {
                                              return '비밀번호가 일치하지 않습니다.';
                                            }
                                            return '비밀번호가 일치합니다.';
                                          },
                                        ),
                                      ),
                                    ),

                                  ],
                                ),
                              ),


                              // 학과
                              Container(
                                margin: EdgeInsets.fromLTRB(0, 0, 2, 10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [


                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          '학과',
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



                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                                        DepartmentSelectionBottomSheet(context, '$_dropdownValue');
                                      },
                                      child: Container(
                                        margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: _selectedDepartment != null ? Color(0xFF1D4786) : Color(0xFFD0D0D0)),
                                          borderRadius: BorderRadius.circular(8),
                                          color: Color(0xFFFFFFFF),
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.fromLTRB(15, 15, 15, 15),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                child:
                                                Text(
                                                  _selectedDepartment ?? '학과명',
                                                  style: TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 16,
                                                    height: 1,
                                                    letterSpacing: -0.4,
                                                    color: _selectedDepartment != null ? Color(0xFF222222): Color(0xFF767676),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                margin: EdgeInsets.fromLTRB(0, 4, 0, 4),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(1),
                                                  child: SizedBox(
                                                    width: 12,
                                                    height: 8,
                                                    child: SvgPicture.asset(
                                                        'assets/pigma/Polygon.svg',
                                                        color: _selectedDepartment != null ? Color(0xFF1D4786) : Color(0xFF424242)
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                  ],
                                ),
                              ),


                              //은행
                              Container(
                                margin: EdgeInsets.fromLTRB(0, 0, 2, 0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [


                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          '은행',
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



                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                                        showBankSelectionSheet(context);
                                      },
                                      child: Container(
                                        margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: _bankName != null ? Color(0xFF1D4786) : Color(0xFFD0D0D0)),
                                          borderRadius: BorderRadius.circular(8),
                                          color: Color(0xFFFFFFFF),
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.fromLTRB(15, 15, 15, 15),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                child:
                                                Text(
                                                  _bankName ?? '은행명',
                                                  style: TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 16,
                                                    height: 1,
                                                    letterSpacing: -0.4,
                                                    color: _bankName != null ? Color(0xFF222222): Color(0xFF767676),
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                margin: EdgeInsets.fromLTRB(0, 4, 0, 4),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(1),
                                                  child: SizedBox(
                                                    width: 12,
                                                    height: 8,
                                                    child: SvgPicture.asset(
                                                        'assets/pigma/Polygon.svg',
                                                        color: _bankName != null ? Color(0xFF1D4786) : Color(0xFF424242)
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
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
                                            HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                                          },
                                          controller: _accountNumberController,
                                          textInputAction: TextInputAction.done,
                                          cursorColor: Color(0xFF1D4786),
                                          keyboardType: TextInputType.number, // 숫자 입력 전용 키보드 설정
                                          onFieldSubmitted: (value) {
                                            HapticFeedback.lightImpact(); // 다음 필드로 이동할 때 햅틱 피드백
                                          },
                                          decoration: InputDecoration(
                                            hintText: '계좌번호를 입력해주세요.',
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
                                                color: _accountNumberHasText ?  Color(0xFF1D4786): Color(0xFFD0D0D0),
                                              ), // 텍스트가 있으면 인디고, 없으면 회색
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: Color(0xFF1D4786)), // 포커스 시 색상 변경
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            errorText: _accountNumberErrorText,
                                          ),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return '계좌 번호를 입력해주세요.';
                                            }
                                            // 숫자만 포함하는지 확인
                                            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                              return '계좌번호는 숫자만 포함해야 합니다.';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),



                              //추천인
                              Container(
                                margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          '추천인',
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



                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Container(
                                            color: Color(0xFFFFFFFF),
                                            margin: EdgeInsets.fromLTRB(0, 0, 10, 0), // 상단 컨테이너와 동일한 마진
                                            child: Align(
                                              alignment: Alignment.topLeft,
                                              child: TextFormField(
                                                cursorColor: Color(0xFF1D4786),
                                                controller: _referralCodeController,
                                                textInputAction: TextInputAction.done,
                                                textCapitalization: TextCapitalization.characters,
                                                keyboardType: TextInputType.visiblePassword,
                                                onTap: () {
                                                  HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                                                },
                                                onChanged: (value) {
                                                  _referralCodeController.value = _referralCodeController.value.copyWith(
                                                    text: value.toUpperCase(), // 입력된 값을 대문자로 변환
                                                    selection: TextSelection.fromPosition( // 커서 위치 유지
                                                      TextPosition(offset: value.length),
                                                    ),
                                                  );
                                                },
                                                enabled : !isReferralCodeVerified,
                                                decoration: InputDecoration(
                                                  hintText: '추천인 코드를 입력해주세요.',
                                                  hintStyle: TextStyle(
                                                    fontFamily: 'Pretendard',
                                                    fontWeight: FontWeight.w400, // 상단 텍스트 스타일과 동일하게 설정
                                                    fontSize: 16, // 상단 텍스트 스타일과 동일하게 설정
                                                    height: 1,
                                                    letterSpacing: -0.4,
                                                    color: Color(0xFF767676),

                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8), // 동일한 테두리 반경
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: _referralCodeHasText ? Color(0xFF1D4786) : Color(0xFFD0D0D0),
                                                    ), // 텍스트가 있으면 인디고, 없으면 회색
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(color: Color(0xFF1D4786)), // 포커스 시 색상 변경
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  counterText: '', // 하단의 '0/10' 텍스트를 숨김
                                                ),
                                                maxLength: 6,
                                              ),
                                            ),
                                          ),
                                        ),


                                        GestureDetector(
                                          onTap: () async {
                                            HapticFeedback.lightImpact();
                                            if (_referralCodeController.text.isNotEmpty && _referralCodeController.text.length == 6 ) {
                                              bool isCheck = await checkReferralCode(_referralCodeController.text);
                                              if (isCheck) {
                                                setState(() {
                                                  isReferralCodeVerified = true;
                                                });

                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '추천인 코드가 확인되었습니다.',
                                                      textAlign: TextAlign.center,
                                                    ),
                                                    duration: Duration(seconds: 1),
                                                  ),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '입력하신 추천인을 찾을 수 없습니다.\n코드가 정확한지 다시 확인해 주세요.',
                                                      textAlign: TextAlign.center,
                                                    ),
                                                    duration: Duration(seconds: 1),
                                                  ),
                                                );
                                              }
                                            }
                                            else if(_referralCodeController.text.isEmpty ){
                                              HapticFeedback.lightImpact();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '추천인 코드를 입력해 주세요.',
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  duration: Duration(seconds: 1),
                                                ),
                                              );
                                            }
                                            else if( _referralCodeController.text.length < 6){
                                              HapticFeedback.lightImpact();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '추천인 코드는 6자리로 입력해 주세요.',
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  duration: Duration(seconds: 1),
                                                ),
                                              );
                                            }
                                          },

                                          child: Container(
                                            height: MediaQuery.of(context).size.height *0.065,
                                            width : MediaQuery.of(context).size.width * 0.2,
                                            decoration: BoxDecoration(
                                                border: Border.all(color: _referralCodeController.text.isNotEmpty ? Color(0xFF1D4786): Color(0xFFE8EFF8)),
                                                borderRadius: BorderRadius.circular(8),
                                                color: _referralCodeController.text.isNotEmpty ? Color(0xFF1D4786): Color(0xFFE8EFF8)
                                            ),
                                            child: Center(
                                              child: Text(
                                                '확인',
                                                style: TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                  height: 1,
                                                  letterSpacing: -0.4,
                                                  color: Color(0xFFFFFFFF),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),


                              //eula 약관 동의
                              Container(
                                margin: EdgeInsets.fromLTRB(0, 10, 2, 0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [


                                    Container(
                                      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                                      child: Align(
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          '약관 동의',
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
                                    GestureDetector(
                                      onTap:(){
                                        HapticFeedback.lightImpact();
                                        _acceptTermsDialog();
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          border: Border.all(color:_isEULAChecked ? Color(0xFF1D4786):Color(0xFFF6F7F8)),
                                          borderRadius: BorderRadius.circular(8),
                                          color:_isEULAChecked ? Color(0xFF1D4786) : Color(0xFFF6F7F8),
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.fromLTRB(3.3, 15, 0, 15),
                                          child:
                                          Text(
                                            _isEULAChecked ? '동의 완료' :'EULA(최종 사용자 사용권 계약) 동의',
                                            style: TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                              height: 1,
                                              letterSpacing: -0.4,
                                              color: _isEULAChecked ? Colors.white : Color(0xFF767676),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),


                                  ],
                                ),
                              ),


                              //개인정보 처리방침
                              Container(
                                margin: EdgeInsets.fromLTRB(0, 10, 2, 0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [


                                    GestureDetector(
                                      onTap:(){
                                        HapticFeedback.lightImpact();
                                        _isPrivacyPolicyCheckdialog();
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          border: Border.all(color:_isPrivacyPolicyChecked ? Color(0xFF1D4786):Color(0xFFF6F7F8)),
                                          borderRadius: BorderRadius.circular(8),
                                          color:_isPrivacyPolicyChecked ? Color(0xFF1D4786) : Color(0xFFF6F7F8),
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.fromLTRB(3.3, 15, 0, 15),
                                          child:
                                          Text(
                                            _isPrivacyPolicyChecked ? '동의 완료' :'개인정보 처리방침 동의',
                                            style: TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                              height: 1,
                                              letterSpacing: -0.4,
                                              color: _isPrivacyPolicyChecked ? Colors.white : Color(0xFF767676),
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

                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),


      bottomNavigationBar:Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: Platform.isAndroid ? MediaQuery.of(context).size.width * 0.15 : MediaQuery.of(context).size.width * 0.20,
            child: ElevatedButton(
              onPressed: () {
                _onSignUpButtonPressed(context);
                HapticFeedback.lightImpact();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1D4786), // 배경색
                foregroundColor: Colors.white, // 텍스트 색상
                padding: EdgeInsets.symmetric(vertical: 13), // 내부 패딩 (높이 조정)
                minimumSize: Size(double.infinity, kBottomNavigationBarHeight), // 버튼 크기 설정
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // 둥근 모서리를 제거하고 직사각형 모양으로 설정
                  side: BorderSide(color: Color(0xFF1D4786)), // 테두리 색상 설정
                ),
              ),
              child: Text(
                '가입 완료',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  height: 1,
                  letterSpacing: -0.5,
                  color: Colors.white, // 텍스트 색상
                ),
              ),
            ),
          ),
        ],
      ),

    );
  }

}