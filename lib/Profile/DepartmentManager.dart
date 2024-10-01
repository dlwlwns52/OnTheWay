import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

import '../CreateAccount/DepartmentList.dart';
import 'Profile.dart';



class DepartmentManager extends StatefulWidget {
  final String nickname;
  final String department;
  final String email;
  // final String oldAccountNumber;
  DepartmentManager({required this.nickname, required this.department, required this.email,});

  @override
  _DepartmentManagerScreenState createState() => _DepartmentManagerScreenState();
}

class _DepartmentManagerScreenState extends State<DepartmentManager> {

  TextEditingController _departmentSearchController = TextEditingController();  // 학과 검색 입력

  String? _selectedDepartment;  // 선택된 학과
  String domain = '';

  @override
  void initState() {
    super.initState();
    domain = _extractDomain(widget.email);
  }


  @override
  void dispose() {
    _departmentSearchController.dispose();
    super.dispose();
  }

  // 도메인 추출
  String _extractDomain(String email)  {
    return email.split('@').last;
  }

  void _onDepartmentSelected(String domain) {
    setState(() {
      _selectedDepartment = domain;
    });
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
                              print(value);
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


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
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
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(50.0), // 원하는 높이로 설정
            child: AppBar(
              title: Text(
                '수정하기',
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
              actions: [],
            ),
          ),




          body: GestureDetector(
            onTap: () {
              // 화면의 다른 부분을 터치했을 때 포커스 해제
              FocusScope.of(context).unfocus();
            },
            child:   Container(
              margin: EdgeInsets.fromLTRB(
                  screenWidth* 0.05,
                  screenHeight*0.03,
                  screenWidth* 0.05,
                  0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Container(
                    margin: EdgeInsets.fromLTRB(0, 0, 0, screenHeight*0.015),
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
                      DepartmentSelectionBottomSheet(context, '${domain}');
                    },
                    child: Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF1D4786) ),
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
                                _selectedDepartment ?? '${widget.department}',
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
                            Container(
                              margin: EdgeInsets.fromLTRB(0, 4, 0, 4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(1),
                                child: SizedBox(
                                  width: 12,
                                  height: 8,
                                  child: SvgPicture.asset(
                                      'assets/pigma/Polygon.svg',
                                      color: Color(0xFF1D4786)
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
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: Platform.isAndroid
                    ? MediaQuery.of(context).size.width * 0.15
                    : MediaQuery.of(context).size.width * 0.21,
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    if (_selectedDepartment == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('변경하고 싶은 학과를 선택해주세요.\n학과별 랭킹을 위해 사용됩니다.', textAlign: TextAlign.center,),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      return;
                    }
                    else{
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.nickname) // Firestore에서 사용자 문서를 업데이트합니다.
                          .update({
                        'department': _selectedDepartment,
                      });

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserProfileScreen()),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '학과 정보가 성공적으로 업데이트되었습니다.',
                            textAlign: TextAlign.center,
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }


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
                    '수정완료',
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
