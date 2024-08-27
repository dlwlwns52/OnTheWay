import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../login/LoginScreen.dart';
import '../CreateAccount/SchoolEmailDialog.dart';


class CreateAccount extends StatefulWidget {

  @override
  _CreateAccountState createState() => _CreateAccountState();

}

class _CreateAccountState extends State<CreateAccount> with WidgetsBindingObserver{


  TextEditingController _nicknameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();  // 비밀번호 컨트롤러 추가
  TextEditingController _confirmPasswordController = TextEditingController();  // 비밀번호 확인 컨트롤러 추가
  TextEditingController _emailUserController = TextEditingController();
  TextEditingController _accountNameController = TextEditingController(); // 계좌명 컨트롤러 추가
  TextEditingController _accountNumberController = TextEditingController(); // 계좌번호 컨트롤러 추가




  bool _isNicknameAvailable = false;


  String _buttonText = '중복확인';
  Color _buttonColor = Colors.white70;
  Color _buttonTextColor = Colors.black87;
  //스낵바가 이미 표시되었는지를 추적하는 플래그
  bool _snackBarShown = false;

  String? _usernicknameErrorText; // 닉네임 제한 ( 영문 대소문자 알파벳, 한글 음절, 일반적인 하이픈 기호, 그리고 숫자를 모두 허용)
  String? _userpasswordErrorText; // password 제한 (비밀번호는 8~16자의 영문 대/소문자, 숫자, 특수문자를 사용 가능)
  String? _confirmPasswordErrorText; // password 와 동일한가 확인
  String? _userEmailErrorText; // 이메일 에러 텍스트 확인
  String? _accountNameErrorText; // 계좌명 에러 텍스트
  String? _accountNumberErrorText; // 계좌번호 에러 텍스트


  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _dropdownValue = null;
  String? _bankName = null;

  bool isEmailVerified = false;
  bool _congratulation = false;

  //이메일인증
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 보더 색상 관리 변수
  bool _emailHasText = false;
  bool _nicknameHasText = false;
  bool _passwordHasText = false;
  bool _confirmPasswordHasText = false;
  bool _accountNumberHasText = false;

  //비밀번호 별표
  bool _obscureText1 = true;
  bool _obscureText2 = true;


  TextEditingController _searchController = TextEditingController();

  List<Map<String, String>> _domains = [
    {'name': '전북대학교', 'domain': 'jbnu.ac.kr'},
    {'name': '충남대학교', 'domain': 'cnu.ac.kr'},
    {'name': '한밭대학교', 'domain': 'edu.hanbat.ac.kr'},
    {'name': '부산대학교', 'domain': 'pusan.ac.kr'},
    {'name': '테스트', 'domain': 'gmail.com'}

    // 도메인 추가
  ];

  List<Map<String, String>> _filteredDomains = [];

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


    _emailUserController.addListener(() {
      setState(() {
        _emailHasText = _emailUserController.text.isNotEmpty;
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
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailUserController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }


//스낵바 형식
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
                      text: _isNicknameAvailable ? '사용 가능한 이름입니다.\n이 닉네임을 사용하시겠습니까?':'다른 사용자가 사용하고 있는 이름입니다. \n다른 닉네임을 사용해 주시길 바랍니다.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF222222),
                      ),
                    ),
                    TextSpan(
                      text: _isNicknameAvailable ? '\n\n⚠️ 닉네임은 한 번 설정하시면 변경이 \n불가하니 신중히 선택해 주세요. ' : '',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.normal, // 작은 글씨는 일반적인 가중치로 설정
                        fontSize: 12, // 작은 글씨 크기 설정
                        color: Colors.grey, // 회색으로 설정
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
                    width: 0.5, // 구분선의 두께
                    height: 60, // 구분선의 높이
                    color: Colors.grey, // 구분선의 색상
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _isNicknameAvailable ? _nicknameController.text = nickname : _nicknameController.clear();
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

  void _onDomainSelected(String domain) {
    setState(() {
      _dropdownValue = domain;
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

  // 이메일 선택 바텀시트
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
                                                    color: _emailHasText ? Colors.indigo : Color(0xFFD0D0D0),
                                                  ),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(color: Colors.indigo),
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
                                            _onDomainSelected(domain['domain']!); // onSelected 함수 호출
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
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void _onBankSelected(String bankname) {
              setState(() {
                _bankName = bankname;
              });
            }

            return SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
                    child: Column(
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
                            child: Container(
                              width: 44,
                              height: 4,
                            ),
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
                                  Text(
                                    '\n\n⚠️이용 중인 은행이 없거나 변경되더라도, 언제든지 프로필에서 \n   손쉽게 수정하실 수 있으니 편안하게 설정해 주세요.',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.normal, // 작은 글씨는 일반적인 가중치로 설정
                                      fontSize: 12, // 작은 글씨 크기 설정
                                      color: Colors.grey, // 회색으로 설정
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                      child: Container(
                                        width: double.infinity,
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
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      // 확인 버튼 로직
                                      _onBankNameSelected(_bankName);
                                      HapticFeedback.lightImpact();
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Color(0xFF1D4786)),
                                        color: Color(0xFF1D4786),
                                      ),
                                      child: Container(
                                        width: double.infinity,
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

      final rootContext = context;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
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
                      width: 0.5, // 구분선의 두께
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
                          try {
                            DateTime now = DateTime.now();
                            String formattedDate = DateFormat('yyyy-MM-dd').format(now);

                            User? currentUser = FirebaseAuth.instance.currentUser;
                            String userUid = currentUser?.uid ?? '';

                            final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
                            await usersCollection.doc(nickname).set({
                              'uid': userUid,
                              'nickname': nickname,
                              'email': email,
                              'joined_date': formattedDate,
                              'grade': 3.0,
                              'bank' : _bankName,
                              'accountNumber' : accountNumber,
                            });

                            // 다이어로그를 닫음
                            Navigator.pop(context);

                            //congratulation 애니메이션
                            // 100ms 지연 후 애니메이션과 나머지 작업 처리
                            Future.delayed(Duration(milliseconds: 100), () async {
                              //congratulation 애니메이션
                              setState(() {
                                _congratulation = true;
                              });

                              await Future.delayed(Duration(milliseconds: 1800), () {
                                setState(() {
                                  _congratulation = false;
                                });
                              });

                              // ScaffoldMessenger 호출을 여기서 안전하게 실행
                              WidgetsBinding.instance?.addPostFrameCallback((_) {
                                if (mounted) {
                                  ScaffoldMessenger.of(rootContext).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '축하합니다! \n회원가입이 완료되었습니다.',
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

  _onNicknameChanged() {
    RegExp onlyConsonants = new RegExp(r'^[ㄱ-ㅎ]+$');
    RegExp onlyVowels = new RegExp(r'^[ㅏ-ㅣ]+$');
    RegExp onlyNumbers = new RegExp(r'^[0-9]+$');
    String pattern = r'^[a-zA-Zㄱ-ㅎ가-힣0-9]+$';
    RegExp regex = new RegExp(pattern);
    String value = _nicknameController.text;
    setState(() {
      if (value == null || value.trim().isEmpty) {
        _usernicknameErrorText = '닉네임을 입력해주세요.';
      } else if (!regex.hasMatch(value)) {
        _usernicknameErrorText = '닉네임은 영문, 한글, 숫자만 \n사용 가능합니다.';
      } else if(onlyConsonants.hasMatch(_nicknameController.text) || onlyVowels.hasMatch(_nicknameController.text) || onlyNumbers.hasMatch(_nicknameController.text)){
        _usernicknameErrorText = '자음, 모음, 숫자 만으로는 \n구성될 수 없습니다.';
      }else {
        _usernicknameErrorText = null;
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

  bool _nicknameValidateFields(){
    RegExp onlyConsonants = RegExp(r'^[ㄱ-ㅎ]+$');
    RegExp onlyVowels = RegExp(r'^[ㅏ-ㅣ]+$');
    RegExp onlyNumbers = RegExp(r'^[0-9]+$');

    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('닉네임을 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    } else if (onlyConsonants.hasMatch(_nicknameController.text) || onlyVowels.hasMatch(_nicknameController.text) || onlyNumbers.hasMatch(_nicknameController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('자음, 모음, 숫자 만으로는 구성될 수 없습니다.', textAlign: TextAlign.center,),
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
    if (_nicknameController.text.trim().isEmpty) {
      if (_emailUserController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일을 입력해주세요.', textAlign: TextAlign.center,),
            duration: Duration(seconds: 1),
          ),
        );
        return false;
      }
      //
      if(isEmailVerified == false){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일 인증을 완료해주세요.', textAlign: TextAlign.center,),
            duration: Duration(seconds: 1),
          ),
        );
        return false;
      }

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




  //이메일 인증
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

      if (user != null && user.email == fullEmail) {
        // 성공적으로 로그인
        await _auth.signOut();
        setState(() {
          isEmailVerified = true;
          _userEmailErrorText = null; // 이메일 인증 성공 시 오류 메시지 제거
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일 인증이 완료되었습니다.', textAlign: TextAlign.center,),
            duration: Duration(seconds: 3),
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
                                              child: Text(
                                                '이메일',
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
                                                        errorText: _userEmailErrorText,
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(8), // 동일한 테두리 반경
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(
                                                            color: _emailHasText ? Colors.indigo : Color(0xFFD0D0D0),
                                                          ), // 텍스트가 있으면 인디고, 없으면 회색
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(color: Colors.indigo), // 포커스 시 색상 변경
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

                                                    showCustomBottomSheet(context);
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      border: Border.all(color: _dropdownValue != null ? Colors.indigo : Color(0xFFD0D0D0)),
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
                                                                    color: _dropdownValue != null ? Colors.indigo : Color(0xFF424242)
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
                                    GestureDetector(
                                      onTap:(){
                                        HapticFeedback.lightImpact();
                                        _emailUserController.text.isNotEmpty ? _signInWithGoogle() : null;
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
                                                onTap: () {
                                                  HapticFeedback.lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                                                },
                                                onFieldSubmitted: (value) {
                                                  _checkNicknameAvailabilityAndValidate();  // '다음'을 누르면 GestureDetector의 기능 실행
                                                },
                                                decoration: InputDecoration(
                                                  contentPadding: EdgeInsets.fromLTRB(15, 15, 15, 15), // 상단 컨테이너의 패딩과 일치시킴
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
                                                      color: _nicknameHasText ? Colors.indigo : Color(0xFFD0D0D0),
                                                    ), // 텍스트가 있으면 인디고, 없으면 회색
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide: BorderSide(color: Colors.indigo), // 포커스 시 색상 변경
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
                                                    _buttonColor = Colors.white70;
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
                                            decoration: BoxDecoration(
                                                border: Border.all(color: _nicknameController.text.isNotEmpty ? Color(0xFF1D4786): Color(0xFFE8EFF8)),
                                                borderRadius: BorderRadius.circular(8),
                                                color: _nicknameController.text.isNotEmpty ? Color(0xFF1D4786): Color(0xFFE8EFF8)
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.fromLTRB(13.7, 15, 13.7, 15),
                                              child:
                                              Text(
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
                                                  color: _passwordHasText ?  Colors.indigo: Color(0xFFD0D0D0),
                                                ), // 텍스트가 있으면 인디고, 없으면 회색
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: Colors.indigo), // 포커스 시 색상 변경
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
                                                  color: _confirmPasswordHasText ?  Colors.indigo: Color(0xFFD0D0D0),
                                                ), // 텍스트가 있으면 인디고, 없으면 회색
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: Colors.indigo), // 포커스 시 색상 변경
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
                                          border: Border.all(color: _bankName != null ? Colors.indigo : Color(0xFFD0D0D0)),
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
                                                        color: _bankName != null ? Colors.indigo : Color(0xFF424242)
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
                                                color: _accountNumberHasText ?  Colors.indigo: Color(0xFFD0D0D0),
                                              ), // 텍스트가 있으면 인디고, 없으면 회색
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide(color: Colors.indigo), // 포커스 시 색상 변경
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
                primary: Color(0xFF1D4786), // 배경색
                onPrimary: Colors.white, // 텍스트 색상
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
