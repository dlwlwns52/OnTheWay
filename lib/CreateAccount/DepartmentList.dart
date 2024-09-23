import 'package:flutter/material.dart';

class DepartmentList {
  static List<String> getDepartmentsByDomain(String domain) {
    switch (domain) {
      case 'cnu.ac.kr':
        return _cnuDepartments;

      default:
        return _defaultDepartments;
    }
  }

  static const List<String> _cnuDepartments = [
    '국어국문학과',
    '영어영문학과',
    '독어독문학과',
    '불어불문학과',
    '중어중문학과',
    '일어일문학과',
    '한문학과',
    '언어학과',
    '국사학과',
    '사학과',
    '고고학과',
    '철학과',
    '사회학과',
    '문헌정보학과',
    '심리학과',
    '언론정보학과',
    '사회복지학과',
    '정치외교학과',
    '행정학부',
    '도시·자치융합학과',
    '수학과',
    '정보통계학과',
    '물리학과',
    '천문우주과학과',
    '화학과',
    '생화학과',
    '지질환경과학과',
    '해양환경과학과',
    '스포츠과학과',
    '무용학과',
    '반도체융합학과',
    '경제학과',
    '경영학부',
    '무역학과',
    '아시아비즈니스국제학과',
    '건축학과(5년제)',
    '건축공학과',
    '토목공학과',
    '환경공학과',
    '기계공학부',
    '메카트로닉스공학과',
    '선박해양공학과',
    '항공우주공학과',
    '전기공학과',
    '전자공학과',
    '전파정보통신공학과',
    '컴퓨터융합학부',
    '인공지능학과',
    '신소재공학과',
    '응용화학공학과',
    '유기재료공학과',
    '자율운항시스템공학과',
    '에너지공학과',
    '식물자원학과',
    '원예학과',
    '산림환경자원학과',
    '환경소재공학과',
    '동물자원과학부',
    '응용생물학과',
    '생물환경화학과',
    '식품공학과',
    '지역환경토목학과',
    '바이오시스템기계공학과',
    '농업경제학과',
    '약학과',
    '의학과(의예과)',
    '의류학과',
    '식품영양학과',
    '소비자학과',
    '음악과',
    '관현악과',
    '회화과',
    '조소과',
    '디자인창의학과',
    '수의학과(수의예과)',
    '국어교육과',
    '영어교육과',
    '수학교육과',
    '교육학과',
    '체육교육과',
    '건설공학교육과',
    '기계·재료공학교육과',
    '전기·전자·통신공학교육과',
    '화학공학교육과',
    '기술교육과',
    '간호학과',
    '생물과학과',
    '미생물·분자생명과학과',
    '생명정보융합학과',
    '인문사회학과',
    '리더십과 조직과학과',
    '공공안전학과',
    '국토안보학전공',
    '해양안보학전공'
  ];


  static const List<String> _jbnuDepartments = [
    '전북대 학과 1',
    '전북대 학과 2',
    // 나머지 전북대 학과
  ];

  static const List<String> _defaultDepartments = ['곧 출시될 학교입니다.'];
}
