
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import 'Profile.dart';


class AccountInfoScreen extends StatefulWidget {
  final String nickname;
  final String oldBank;
  final String oldAccountNumber;
  AccountInfoScreen({required this.nickname, required this.oldBank, required this.oldAccountNumber});

  @override
  _AccountInfoScreenState createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  String? _bankName;

  TextEditingController _accountNumberController = TextEditingController(); // 계좌번호 컨트롤러 추가
  String? _accountNumberErrorText; // 계좌번호 에러 텍스트

  // 보더 색상 관리 변수
  bool _accountNumberHasText = false;


  @override
  void initState() {
    super.initState();
    _bankName = widget.oldBank;
    _accountNumberController.addListener(_onAccountNumberChanged);

    _accountNumberController.addListener(() {
      setState(() {
        _accountNumberHasText = _accountNumberController.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    super.dispose();
  }


  bool _validateFields() {
    if (_accountNumberController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('계좌번호를 입력해주세요.', textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }
    return true;
  }


  _onAccountNumberChanged() {
    String value = _accountNumberController.text;
    setState(() {
      if (value == null || value
          .trim()
          .isEmpty) {
        _accountNumberErrorText = '계좌번호를 입력해주세요.';
      } else {
        _accountNumberErrorText = null;
      }
    });
  }

  void _onBankNameSelected(String bankname) {
    setState(() {
      _bankName = bankname;
    });
  }

  //은행명 바텀시
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
                bottom: MediaQuery
                    .of(context)
                    .viewInsets
                    .bottom, // 키보드에 의해 가려지는 부분을 고려한 패딩
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
                                        borderRadius: BorderRadius.circular(
                                            10.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Color(0xFF1D4786)),
                                        // 포커스 시 색상 변경
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
                                    border: Border.all(
                                        color: Color(0xFFF6F7F8)),
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
                                    border: Border.all(
                                        color: Color(0xFF1D4786)),
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
  Widget _buildBankRow(BuildContext context,
      List<String> bankNames,
      String selectedBank,
      void Function(String) onBankSelected,) {
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
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
            child: AppBar(
              title: Text(
                '계좌 정보',
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
                icon: Icon(Icons.arrow_back_ios_new_outlined),
                // '<' 모양의 뒤로가기 버튼 아이콘
                color: Colors.white,
                // 아이콘 색상
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context); // 뒤로가기 기능
                },
              ),
              // 상단 왼쪽 빈 공간을 만들기 위해 빈 SizedBox를 사용
              actions: [],
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
                              margin: EdgeInsets.fromLTRB(
                                20,
                                MediaQuery
                                    .of(context)
                                    .size
                                    .height * 0.03,
                                20,
                                0,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: EdgeInsets.fromLTRB(0, 0, 2, 0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment
                                          .start,
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        Container(
                                          margin: EdgeInsets.fromLTRB(
                                              0, 0, 0, 10),
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
                                            HapticFeedback
                                                .lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                                            showBankSelectionSheet(context);
                                          },
                                          child: Container(
                                            margin: EdgeInsets.fromLTRB(
                                                0, 0, 0, 10),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: _bankName != null
                                                    ? Colors.indigo
                                                    : Color(0xFFD0D0D0),
                                              ),
                                              borderRadius: BorderRadius
                                                  .circular(8),
                                              color: Color(0xFFFFFFFF),
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.fromLTRB(
                                                  15, 15, 15, 15),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment
                                                    .spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment
                                                    .start,
                                                children: [
                                                  Container(
                                                    child: Text(
                                                      _bankName ?? '은행명',
                                                      style: TextStyle(
                                                        fontFamily: 'Pretendard',
                                                        fontWeight: FontWeight
                                                            .w400,
                                                        fontSize: 16,
                                                        height: 1,
                                                        letterSpacing: -0.4,
                                                        color: _bankName != null
                                                            ? Color(0xFF222222)
                                                            : Color(0xFF767676),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    margin: EdgeInsets.fromLTRB(
                                                        0, 4, 0, 4),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius
                                                          .circular(1),
                                                      child: SizedBox(
                                                        width: 12,
                                                        height: 8,
                                                        child: SvgPicture.asset(
                                                          'assets/pigma/Polygon.svg',
                                                          color: _bankName !=
                                                              null
                                                              ? Colors.indigo
                                                              : Color(
                                                              0xFF424242),
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
                                          margin: EdgeInsets.fromLTRB(
                                              0, 0, 0, 10),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFFFFFFF),
                                          ),
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: TextFormField(
                                              onTap: () {
                                                HapticFeedback
                                                    .lightImpact(); // 텍스트 필드를 터치할 때 햅틱 피드백
                                              },
                                              controller: _accountNumberController,
                                              textInputAction: TextInputAction
                                                  .done,
                                              cursorColor: Color(0xFF1D4786),
                                              keyboardType: TextInputType
                                                  .number,
                                              // 숫자 입력 전용 키보드 설정
                                              onFieldSubmitted: (value) {
                                                HapticFeedback
                                                    .lightImpact(); // 다음 필드로 이동할 때 햅틱 피드백
                                              },
                                              decoration: InputDecoration(
                                                hintText: widget
                                                    .oldAccountNumber,
                                                hintStyle: TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                  height: 1,
                                                  letterSpacing: -0.4,
                                                  color: Color(0xFF767676),
                                                ),
                                                contentPadding: EdgeInsets
                                                    .symmetric(
                                                  vertical: 11,
                                                  horizontal: 12,
                                                ),
                                                // 내부 여백 조정
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius
                                                      .circular(10),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: _accountNumberHasText
                                                        ? Colors.indigo
                                                        : Color(0xFFD0D0D0),
                                                  ), // 텍스트가 있으면 인디고, 없으면 회색
                                                  borderRadius: BorderRadius
                                                      .circular(8),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: Colors.indigo,
                                                  ),
                                                  // 포커스 시 색상 변경
                                                  borderRadius: BorderRadius
                                                      .circular(8),
                                                ),
                                                errorText: _accountNumberErrorText,
                                              ),
                                              validator: (value) {
                                                if (value == null || value
                                                    .trim()
                                                    .isEmpty) {
                                                  return '계좌 번호를 입력해주세요.';
                                                }
                                                // 숫자만 포함하는지 확인
                                                if (!RegExp(r'^[0-9]+$')
                                                    .hasMatch(value)) {
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
          bottomNavigationBar:
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: Platform.isAndroid ? MediaQuery.of(context).size.width * 0.15
                    : MediaQuery.of(context).size.width * 0.21,
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    if (_validateFields()) {
                      String? newBank = _bankName;
                      String newAccountNumber = _accountNumberController.text
                          .trim();

                      if (_bankName!.isNotEmpty && newAccountNumber.isNotEmpty) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(
                            widget.nickname) // Firestore에서 사용자 문서를 업데이트합니다.
                            .update({
                          'bank': newBank,
                          'accountNumber': newAccountNumber,
                        });

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => UserProfileScreen()),
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '계좌 정보가 성공적으로 업데이트되었습니다.',
                              textAlign: TextAlign.center,
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1D4786),
                    // 배경색
                    foregroundColor: Colors.white,
                    // 텍스트 색상
                    padding: EdgeInsets.symmetric(vertical: 13),
                    // 내부 패딩 (높이 조정)
                    minimumSize: Size(
                        double.infinity, kBottomNavigationBarHeight),
                    // 버튼 크기 설정
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                      // 둥근 모서리를 제거하고 직사각형 모양으로 설정
                      side: BorderSide(color: Color(0xFF1D4786)), // 테두리 색상 설정
                    ),
                  ),
                  child: Text(
                    '수정하기',
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
        ),
      ),
    );
  }
}