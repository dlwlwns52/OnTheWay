class NicknameValidator {
  // 금지된 닉네임 목록
  static List<String> bannedNicknames = [
    "씨발", "병신", "좆", "개새끼", "미친놈", "ㅅㅂ", "ㅈㄹ", "ㅄ", "시발", "씹",
    "좇", "개년", "씹새", "십새끼", "미친년", "개같은", "엿같다", "똘아이", "좆까", "빡대가리",
    "씹할", "똥구멍", "개좆", "병신같은", "개지랄", "죽여버린다", "미친놈", "개수작", "좆밥", "썅",
    "븅신", "병1신", "병ㅅ", "꼴값", "ㅈ까", "꺼져", "엿먹어", "졸라", "좃", "돌아이",
    "ㅂㅅ", "엠창", "엠병", "니애미", "꺼져라", "쳐죽일", "개념상실", "덜떨어진", "짜증나", "니미",
    "지랄", "개소리", "염병", "좆나", "씹새끼", "졸라리", "대갈빡", "대가리", "염병할", "씨부랄",
    "꺼지라", "개자식", "씹치기", "엿바꿔먹다", "호로자식", "씹덕", "덕후", "씹선비", "골빈", "노답",
    "개망나니", "개찌질", "등신", "망나니", "돌대가리", "눈깔", "X발", "육갑", "쳐맞다", "개차반",
    "치매걸린", "꼴불견", "비위생적", "찌질하다", "찌질이", "양아치", "양키", "쪽팔리다", "헛소리", "개소리",
    "개쪽", "헛짓", "대가리깨져라", "무식한놈", "버러지같은", "구역질나는", "찌질한", "꼴통", "씹통수", "십덕후",
    "미친놈", "돌아버린", "허접한", "저능아", "찌끄레기", "개같은", "개나리", "돌대가리", "늙다리", "썅놈",
    "늙은이", "병맛", "병걸린", "사기꾼", "죽일놈", "미친", "뇌정지", "바보같은", "바보멍청이", "모자라다",
    "구린내", "삽질", "계집", "성질머리", "삐뚤어진", "찐따같은", "후잡한",
    "찌질한", "덜떨어진놈", "쪼다", "덤앤더머", "돌팔이", "조무래기", "돌대가리",
    "발암", "등신같은",
    "똥오줌", "똥통", "양아치같은", "입방정", "입삐뚤어진", "입놀리다", "입털다",
    "장난질", "장난치다", "잡놈", "잡것", "잡범", "잡놈같은", "잡스러운", "죽음의", "죽이다", "지랄같은",
    "짜증나게", "짜증폭발", "짜증나는놈", "창녀", "창년", "창놈", "창녀같은", "찌꺼기", "찌질대다", "쪽팔리게",
    "쪽팔린다", "쫄다", "쫄보", "쫄따구", "쫄리다", "쫄딱망하다", "쪽박", "찐따같은", "찌그러지다", "찌질하게",
    "지랄염병", "지리다", "지옥불", "지옥의문", "죽을놈", "쳐죽일놈", "진상이", "찐따같은", "보지", "자지",
    "젖", "섹스", "자위", "애무", "음란", "야동", "포르노", "에로", "섹시", "몸매좋은",
    "야한년", "야동충", "X스", "야사", "섹시녀", "섹시남", "AV", "AV배우", "성기", "성적수치심",
    "스와핑", "그룹섹스", "성매매", "성매수자", "야한사진", "가슴만지기", "야동중독", "성관계", "피임", "콘돔",
    "가슴크기", "유방확대", "유두", "음경", "질", "항문", "성기삽입", "성교", "성도착증", "변태",
    "변태놈", "변태짓", "성적유혹", "음란마귀", "야한남자", "야한여자", "섹시남자", "섹시여자", "색정광", "색광",
    "음란한", "성욕", "유혹하다", "성적접촉", "스킨십", "나체사진", "성추행", "성희롱", "성폭행", "성매매",
    "성매수자", "성욕구", "음란죄", "자위행위", "성행위", "성교행위", "유사성행위", "사후피임", "낙태", "성형수술",
    "피임약", "젖가슴", "젖꼭지", "여성성기", "남성성기", "성도착", "성적일탈", "성적가치", "성적학대", "성적희롱",
    "성적욕구", "성적환상", "야한비디오", "음란서적", "성인비디오", "성인물", "성적놀이", "야한놈", "야한사진", "유혹적인",
    "성적코드", "성적표현", "성적농담", "성적유린", "성도착증", "성기능장애", "자위기구", "성행위도구", "섹스용품", "성행위용품",
    "자위도구", "성기확대", "가슴확대", "유두크기", "젖꼭지크기", "성인용품", "성인동영상", "야한영화", "성적욕망", "성적충동",
    "성적가학", "성적피해", "성적학대", "성적능욕", "성적모욕", "성적굴욕", "성적삽입", "성적접촉", "성적유혹", "성적도구",
    "성행위영상", "성행위사진", "성행위기록", "음란물", "야한영화", "야한사진", "야한소설", "성적삽입", "성적문란", "음란동영상",
    "성인영화", "성적자극", "음란사이트", "음란영상", "성적노예", "성적지배", "성적자학", "성적비하", "성적학대자", "성적환상",
    "성적욕구자극", "성도착행위", "성적괴롭힘", "성적우월감", "음란물제작", "음란물배포", "성행위장면", "성적대상화", "음란비디오", "음란방송",
    "음란채팅", "야동사이트", "음란클럽", "성인용동영상", "성매매알선", "성매수행위", "성적소외감", "성적불만족", "성적자기만족", "성적판타지",
    "성적기구", "성적중독", "성적억압", "음란전화", "음란대화", "성적허기", "성적피해자", "성범죄", "성범죄자", "성범죄피해자",
    "성범죄기록", "성범죄율", "성범죄예방", "성범죄사건", "성범죄수법", "성범죄유형", "성범죄알림", "성범죄근절", "성범죄처벌", "성적쾌락",
    "성적학대행위", "성적도구사용", "성적상상력", "성적접촉행위", "성도착자", "성적중독자", "성적자극물", "성적행동장애", "성도착성행위", "음란물중독",
    "성적공포감", "성적도구판매", "성적도구구매", "성도착증환자", "성적취향자", "음란성행위", "성적비디오", "성적대화", "김치녀", "된장녀",
    "한남충", "꼰대", "틀딱", "짱깨", "쪽바리", "흑형", "탈북자", "백정", "서민충", "흑인비하",
    "여성혐오", "남성혐오", "메갈", "워마드", "한남", "벌레", "흑형충", "꼴페미", "엑스페미", "꼴통",
    "무뇌충", "맘충", "급식충", "망치부인", "영감탱이", "영감", "틀니충", "멸공", "홍어", "가스라이팅",
    "일베충", "지잡대", "불법체류자", "성차별", "인종차별", "장애인비하", "비하발언", "장애비하", "전라도비하", "경상도비하",
    "다문화비하", "외국인비하", "여성비하", "남성비하", "동성애비하", "성소수자비하", "성소수자차별", "트랜스젠더비하", "동성애혐오", "이슬람혐오",
    "외국인혐오", "다문화혐오", "종교비하", "신체비하", "탈모비하", "얼굴비하", "체중비하", "뚱뚱이", "외모지상주의", "빈곤층비하",
    "부자비하", "저소득층비하", "금수저비하", "흑인비하발언", "장애인차별", "성차별적발언", "성차별주의자", "성적지향차별", "장애비하발언", "성비하발언",
    "나이비하", "인종차별적발언", "정신장애비하", "지적장애비하", "저능아", "흑형비하", "지능비하", "나이차별", "외국인혐오발언", "혐오발언",
    "여자비하", "남자비하", "성인비하", "청소년비하", "노인비하", "성소수자비하발언", "성소수자차별발언", "인종혐오발언", "전라도혐오발언", "경상도혐오발언",
    "한국인비하", "동양인비하", "서양인비하", "흑인혐오발언", "인종비하발언", "민족비하", "민족차별", "문화비하", "외모비하발언", "체중비하발언",
    "장애혐오발언", "성차별발언", "성차별주의", "동성애혐오발언", "동성애차별발언", "종교차별", "종교혐오", "교회혐오", "성당혐오", "이슬람혐오발언",
    "유대인혐오발언", "이민자비하", "이민자혐오", "비하행위", "비하적발언", "정신장애비하발언", "육체비하", "신체차별", "육체차별", "트랜스젠더차별",
    "트랜스젠더혐오", "레즈비언혐오", "게이혐오", "레즈비언차별", "게이차별", "동성애자비하", "양성애자비하", "동성애자혐오발언", "양성애자혐오발언", "동성애차별",
    "동성애혐오", "남성혐오발언", "여성혐오발언", "페미니즘혐오", "페미니스트비하", "남성차별", "여성차별", "성차별주의적발언", "군인비하", "군대비하",
    "장교비하", "병사비하", "군인차별", "군대혐오", "군대혐오발언", "병역비하", "병역의무비하", "병역거부자비하", "병역거부자혐오", "병역비하발언",
    "군대차별발언", "군대차별주의", "군대비하발언", "전쟁비하", "전쟁혐오", "군인혐오발언", "전쟁차별발언", "병역차별", "전쟁비하발언", "군대혐오주의",
    "군대차별주의", "군대비하발언", "장교혐오발언", "병사혐오발언", "징병제비하", "병역제비하", "징병제혐오", "병역제혐오발언", "예비군비하", "예비군혐오발언",
    "국방비하", "국방혐오", "군복비하", "군복혐오", "전사비하", "참전비하", "참전혐오발언", "전쟁차별", "군사비하", "군사혐오",
    "참전차별", "참전비하발언", "전쟁차별주의", "군사혐오발언", "참전차별발언", "전사혐오발언", "병역비하발언", "예비군차별", "예비군혐오", "군대비하발언",
    "병역비하행위", "병역차별발언", "군사차별", "병역차별주의", "병역차별행위", "군사비하발언", "군사혐오주의", "전사차별", "살인자", "테러범",
    "죽여버려", "폭탄", "테러", "살인", "살인마", "강간범", "강간", "성범죄자", "성폭행", "납치범",
    "도둑놈", "강도", "폭력배", "조폭", "야쿠자", "총알받이", "마약", "마약사범", "마약중독자", "중독자",
    "방화범", "화염병", "폭행", "구타", "패싸움", "칼부림", "칼들고", "총질", "도둑질", "사기꾼",
    "성희롱범", "사기범", "절도범", "밀수꾼", "성추행범", "자살충동", "총격사건", "범죄조직", "살인예고", "살인미수",
    "테러위협", "테러단체", "폭력단체", "폭행사건", "성폭행범", "성범죄", "성매매범", "성희롱", "강도사건", "성추행",
    "납치사건", "방화사건", "방화범죄", "성범죄사건", "성매매알선", "성매매방조", "성매매피해자", "강간사건", "강간미수", "살인범",
    "살인사건", "납치미수", "방화미수", "도둑사건", "절도사건", "강도미수", "총기사고", "총기난사", "테러사건", "폭발사건",
    "폭발물", "폭발범죄", "폭파사건", "폭파미수", "총격사고", "총기소지", "총기위협", "무기밀매", "무기거래", "폭탄사고",
    "무기소지", "무기사용", "무기밀수", "테러미수", "테러위험", "살인사건", "납치미수", "납치위협", "사기사건", "강간피해자",
    "성희롱사건", "성추행사건", "성추행피해자", "성희롱피해자", "성매매사건", "성매매단속", "성매매밀수", "인신매매", "인신매매범", "인신매매사건",
    "인신매매미수", "인신매매피해자", "밀수사건", "밀수범", "밀수단속", "밀수피해자", "도박사건", "도박범", "도박단속", "도박피해자",
    "강도단속", "강도사건", "강도미수", "총기사고", "총기밀수", "총기거래", "총기사건", "총기위협", "도둑사건", "강도범",
    "성폭행피해자", "성범죄피해자", "성폭행사건", "납치범죄", "납치피해자", "도둑미수", "절도미수", "절도범죄", "절도사건", "강간범죄",
    "강간피해", "납치사건", "방화사건", "방화미수", "절도사건", "사기범죄", "사기피해", "사기미수", "폭행미수", "폭행범죄",
    "폭행사건", "사기단", "사기피해자", "범죄피해자", "강간범죄", "성범죄사건", "성매매사건", "성매매피해", "문재인", "박근혜",
    "김정은", "이명박", "노무현", "전두환", "노태우",'문재인','윤석열', "광주사태", "518", "민주당", "국힘당", "보수꼴통",
    "좌익빨갱이", "우익", "좌파", "우파", "토착왜구", "일본군", "일본군위안부", "위안부문제", "종북", "반공",
    '18년', '18놈', '18새끼', 'ㄱㅐㅅㅐㄲl', 'ㄱㅐㅈㅏ', '가슴만져', '가슴빨아', '가슴빨어', '가슴조물락',
    '가슴주물럭', '가슴쪼물딱', '가슴쪼물락', '가슴핧아', '가슴핧어', '강간', '개가튼년', '개가튼뇬',
    '개같은년', '개걸레', '개고치', '개너미', '개넘', '개년', '개놈', '개늠', '개똥', '개떵', '개떡',
    '개라슥', '개보지', '개부달', '개부랄', '개불랄', '개붕알', '개새', '개세', '개쓰래기', '개쓰레기',
    '개씁년', '개씁블', '개씁자지', '개씨발', '개씨블', '개자식', '개자지', '개잡년', '개젓가튼넘', '개좆',
    '개지랄', '개후라년', '개후라들놈', '개후라새끼', '걔잡년', '거시기', '걸래년', '걸레같은년', '걸레년',
    '걸레핀년', '게부럴', '게세끼', '게이', '게새끼', '게늠', '게자식', '게지랄놈', '고환', '공지', '공지사항',
    '귀두', '깨쌔끼', '난자마셔', '난자먹어', '난자핧아', '내꺼빨아', '내꺼핧아', '내버지', '내자지', '내잠지',
    '내조지', '너거애비', '노옴', '누나강간', '니기미', '니뿡', '니뽕', '니씨브랄', '니아범', '니아비', '니애미',
    '니애뷔', '니애비', '니할애비', '닝기미', '닌기미', '니미', '닳은년', '덜은새끼', '돈새끼', '돌으년', '돌은넘',
    '돌은새끼', '동생강간', '동성애자', '딸딸이', '똥구녁', '똥꾸뇽', '똥구뇽', '똥', '띠발뇬', '띠팔', '띠펄',
    '띠풀', '띠벌', '띠벨', '띠빌', '마스터', '막간년', '막대쑤셔줘', '막대핧아줘', '맛간년', '맛없는년', '맛이간년',
    '멜리스', '미친구녕', '미친구멍', '미친넘', '미친년', '미친놈', '미친눔', '미친새끼', '미친쇄리', '미친쇠리',
    '미친쉐이', '미친씨부랄', '미튄', '미티넘', '미틴', '미틴넘', '미틴년', '미틴놈', '미틴것', '백보지', '버따리자지',
    '버지구녕', '버지구멍', '버지냄새', '버지따먹기', '버지뚫어', '버지뜨더', '버지물마셔', '버지벌려', '버지벌료',
    '버지빨아', '버지빨어', '버지썰어', '버지쑤셔', '버지털', '버지핧아', '버짓물', '버짓물마셔', '벌창같은년',
    '벵신', '병닥', '병딱', '병신', '보쥐', '보지', '보지핧어', '보짓물', '보짓물마셔', '봉알', '부랄', '불알', '붕알',
    '붜지', '뷩딱', '븅쉰', '븅신', '빙띤', '빙신', '빠가십새', '빠가씹새', '빠구리', '빠굴이', '뻑큐', '뽕알',
    '뽀지', '뼝신', '사까시', '상년', '새꺄', '새뀌', '새끼', '색갸', '색끼', '색스', '색키', '샤발', '서버', '써글',
    '써글년', '성교', '성폭행', '세꺄', '세끼', '섹스', '섹스하자', '섹스해', '섹쓰', '섹히', '수셔', '쑤셔', '쉐끼',
    '쉑갸', '쉑쓰', '쉬발', '쉬방', '쉬밸년', '쉬벌', '쉬불', '쉬붕', '쉬빨', '쉬이발', '쉬이방', '쉬이벌', '쉬이불',
    '쉬이붕', '쉬이빨', '쉬이팔', '쉬이펄', '쉬이풀', '쉬팔', '쉬펄', '쉬풀', '쉽쌔', '시댕이', '시발', '시발년',
    '시발놈', '시발새끼', '시방새', '시밸', '시벌', '시불', '시붕', '시이발', '시이벌', '시이불', '시이붕', '시이팔',
    '시이펄', '시이풀', '시팍새끼', '시팔', '시팔넘', '시팔년', '시팔놈', '시팔새끼', '시펄', '실프', '십8', '십때끼',
    '십떼끼', '십버지', '십부랄', '십부럴', '십새', '십세이', '십셰리', '십쉐', '십자석', '십자슥', '십지랄', '십창녀',
    '십창', '십탱', '십탱구리', '십탱굴이', '십팔새끼', 'ㅆㅂ', 'ㅆㅂㄹㅁ', 'ㅆㅂㄻ', 'ㅆㅣ', '쌍넘', '쌍년', '쌍놈',
    '쌍눔', '쌍보지', '쌔끼', '쌔리', '쌕스', '쌕쓰', '썅년', '썅놈', '썅뇬', '썅늠', '쓉새', '쓰바새끼', '쓰브랄쉽세',
    '씌발', '씌팔', '씨가랭넘', '씨가랭년', '씨가랭놈', '씨발', '씨발년', '씨발롬', '씨발병신', '씨방새', '씨방세', '씨밸',
    '씨뱅가리', '씨벌', '씨벌년', '씨벌쉐이', '씨부랄', '씨부럴', '씨불', '씨불알', '씨붕', '씨브럴', '씨블', '씨블년',
    '씨븡새끼', '씨빨', '씨이발', '씨이벌', '씨이불', '씨이붕', '씨이팔', '씨파넘', '씨팍새끼', '씨팍세끼', '씨팔',
    '씨펄', '씨퐁넘', '씨퐁뇬', '씨퐁보지', '씨퐁자지', '씹년', '씹물', '씹미랄', '씹버지', '씹보지', '씹부랄', '씹브랄',
    '씹빵구', '씹뽀지', '씹새', '씹새끼', '씹세', '씹쌔끼', '씹자석', '씹자슥', '씹자지', '씹지랄', '씹창', '씹창녀',
    '씹탱', '씹탱굴이', '씹탱이', '씹팔', '아가리', '애무', '애미', '애미랄', '애미보지', '애미씨뱅', '애미자지', '애미잡년',
    '애미좃물', '애비', '애자', '양아치', '어미강간', '어미따먹자', '어미쑤시자', '영자', '엄창', '에미', '에비', '엔플레버',
    '엠플레버', '염병', '염병할', '염뵹', '엿먹어라', '오랄', '오르가즘', '왕버지', '왕자지', '왕잠지', '왕털버지',
    '왕털보지', '왕털자지', '왕털잠지', '우미쑤셔', '운디네', '유두', '유두빨어', '유두핧어', '유방',
    '유방만져', '유방빨아', '유방주물럭', '유방쪼물딱', '유방쪼물럭', '유방핧아', '유방핧어', '육갑', '이그니스',
    '이년', '이프리트', '자기핧아', '자지', '자지구녕', '자지구멍', '자지꽂아', '자지넣자', '자지뜨더', '자지뜯어',
    '자지박어', '자지빨아', '자지빨아줘', '자지빨어', '자지쑤셔', '자지쓰레기', '자지정개', '자지짤라', '자지털',
    '자지핧아', '자지핧아줘', '자지핧어', '작은보지', '잠지', '잠지뚫어', '잠지물마셔', '잠지털', '잠짓물마셔',
    '잡년', '잡놈', '저년', '점물', '젓가튼', '젓가튼쉐이', '젓같내', '젓같은', '젓까', '젓나', '젓냄새', '젓대가리',
    '젓떠', '젓마무리', '젓만이', '젓물', '젓물냄새', '젓밥', '정액마셔', '정액먹어', '정액발사', '정액짜', '정액핧아',
    '정자마셔', '정자먹어', '정자핧아', '젖같은', '젖까', '젖밥', '젖탱이', '조개넓은년', '조개따조', '조개마셔줘',
    '조개벌려조', '조개속물', '조개쑤셔줘', '조개핧아줘', '조까', '조또', '족같내', '족까', '족까내', '존나', '존나게',
    '존니', '졸라', '좀마니', '좀물', '좀쓰레기', '좁빠라라', '좃가튼뇬', '좃간년', '좃까', '좃까리', '좃깟네',
    '좃냄새', '좃넘', '좃대가리', '좃도', '좃또', '좃만아', '좃만이', '좃만한것', '좃만한쉐이', '좃물', '좃물냄새',
    '좃보지', '좃부랄', '좃빠구리', '좃빠네', '좃빠라라', '좃털', '좆같은놈', '좆같은새끼', '좆까', '좆까라',
    '좆나', '좆년', '좆도', '좆만아', '좆만한년', '좆만한놈', '좆만한새끼', '좆먹어', '좆물', '좆밥', '좆빨아',
    '좆새끼', '좆털', '좋만한것', '주글년', '주길년', '쥐랄', '지랄', '지랼', '지럴', '지뢀', '쪼까튼', '쪼다',
    '쪼다새끼', '찌랄', '찌질이', '창남', '창녀', '창녀버지', '창년', '처먹고', '처먹을', '쳐먹고', '쳐쑤셔박어',
    '촌씨브라리', '촌씨브랑이', '촌씨브랭이', '크리토리스', '큰보지', '클리토리스', '트랜스젠더', '페니스', '항문수셔',
    '항문쑤셔', '허덥', '허버리년', '허벌년', '허벌보지', '허벌자식', '허벌자지', '허접', '허젚', '허졉', '허좁',
    '헐렁보지', '혀로보지핧기', '호냥년', '호로', '호로새끼', '호로자슥', '호로자식', '호로짜식', '호루자슥',
    '호모', '호졉', '호좁', '후라덜넘', '후장', '후장꽂아', '후장뚫어', '흐접', '흐젚', '흐졉', 'bitch', 'fuck',
    'fuckyou', 'nflavor', 'penis', 'pennis', 'pussy', 'sex','pornhub', 'xvideos','운영자','운영',

  ];


  // 닉네임이 금지된 목록에 있는지 확인하는 메서드
  static bool isNicknameValid(String nickname) {
    return !bannedNicknames.contains(nickname);
  }
}