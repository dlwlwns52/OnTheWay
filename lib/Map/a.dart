//
// class NaverNewPostScreen extends StatefulWidget {
//   final DocumentSnapshot? post;
//
//   NaverNewPostScreen({this.post});
//
//   @override
//   _NaverNewPostScreenState createState() => _NaverNewPostScreenState();
// }
//
// class _NaverNewPostScreenState extends State<NaverNewPostScreen> {
//
//   //위치
//   String? _selectedLocation;
//
//   void _chooseLocation() async {
//     // MapScreen으로부터 반환된 위치를 받습니다.
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => MapScreen()),
//     );
//
//     // 반환된 위치를 변수에 저장합니다.
//     if (result != null) {
//       setState(() {
//         _selectedLocation = result; // 현재 위치 정보 업데이트
//       });
//     }
//   }
//
//   Future<void> _uploadPost() async {
//
//
//     try {
//       FirebaseFirestore db = FirebaseFirestore.instance;
//       String? email = getUserEmail();
//
//       QuerySnapshot existingPosts = await db
//           .collection('naver_posts')
//           .where('my_location', isEqualTo: _locationController.text)
//           .where('user_email', isEqualTo: email)
//           .get();
//
//       if (existingPosts.docs.isNotEmpty && widget.post == null) {
//         _showSnackBar('동일한 제목의 게시물이 이미 존재합니다.');
//       } else {
//         String documentName =
//             widget.post?.id ?? "${_locationController.text}_${email ?? 'unknown'}";
//         await db.collection('naver_posts').doc(documentName).set({
//           'kakaomap_location': _selectedLocation ?? '위치 미설정',
//           'my_location': _locationController.text,
//           'store': _storeController.text,
//           'cost': _costController.text,
//           'user_email': email,
//           'Request': _requestController.text,
//           'date': DateTime.now(),
//         });
//
//         Navigator.of(context).pop();
//       }
//     } catch (e) {
//       _showSnackBar("게시물 업로드에 실패했습니다.");
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('게시물 작성'),
//         backgroundColor:Color(0xFFFF8B13),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: EdgeInsets.all(16.0),
//             child: Column(
//               children: <Widget>[
//                 TextField(
//                   controller: _locationController,
//                   decoration: InputDecoration(
//                     labelText: '본인 위치',
//                     contentPadding: EdgeInsets.symmetric(vertical: 20.0),
//                   ),
//                   textInputAction: TextInputAction.next,
//                   maxLines: null,
//                   maxLength: 20,
//                 ),
//                 SizedBox(height: 8.0),
//                 // 본인 위치 설정 버튼
//                 ElevatedButton(
//                   onPressed: _chooseLocation,  // 버튼 클릭 시 _chooseLocation 함수 호출
//                   child: Text('본인 위치 설정'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//       bottomNavigationBar: BottomAppBar(
//         // color: Colors.transparent, // 배경 색상을 투명하게 설정
//         child: Container(
//           margin: EdgeInsets.all(16.0), // 여백 추가
//           decoration: BoxDecoration(
//             color: Colors.orange, // 버튼 배경색
//             borderRadius: BorderRadius.circular(10.0), // 버튼 모서리를 둥글게 만듦
//
//           ),
//           child: ElevatedButton.icon(
//             onPressed: _uploadPost,
//             icon: Icon(Icons.send), // 버튼 아이콘
//             label: Text(
//               '게시하기',
//               style: TextStyle(fontSize: 18),
//             ),
//             style: ElevatedButton.styleFrom(
//               primary: Colors.transparent, // 버튼 색상 투명하게 설정
//               shadowColor: Colors.transparent, // 그림자 색상 투명하게 설정
//             ),
//           ),
//         ),
//       ),
//
//     );
//   }
//
// }
