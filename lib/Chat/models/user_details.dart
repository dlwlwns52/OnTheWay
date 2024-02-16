// // 이 코드는 사용자 데이터를 나타내는 UserDetails 클래스를 정의하고,
// // 사용자 데이터를 맵 형식으로 변환하거나 맵 데이터를 UserDetails 객체로 변환하는 기능을 제공합니다.
// // 이 클래스는 Firebase Firestore에서 사용자 데이터를 읽고 쓰는 데 사용됩니다.
//
//
// // UserDetails 클래스: 사용자 정보를 나타냄
// class UserDetails {
//   // 멤버 변수들: 사용자의 이름, 이메일 ID, 사진 URL, 고유 ID
//   String nickname;
//   String email;
//   String photoUrl;
//   String uid;
//
//   // 생성자: 객체 초기화
//   // null safety를 적용하기 위해 필요한 필드에는 required 키워드 추가
//   UserDetails({required this.nickname, required this.email, required this.photoUrl, required this.uid});
//
//
//   // toMap: UserDetails 객체를 Map 형식으로 변환
//   Map<String, String> toMap() {
//     var data = <String, String>{};
//     data['name'] = nickname;
//     data['email'] = email;
//     data['photoUrl'] = photoUrl;
//     data['uid'] = uid;
//     return data;
//   }
//
//   // fromMap: Map을 UserDetails 객체로 변환
//   // 생성자를 factory 생성자로 변경하여 코드를 개선
//   factory UserDetails.fromMap(Map<String, String> mapData) {
//     return UserDetails(
//       nickname: mapData['nickname'] ?? '', // null 체크 후 추가
//       email: mapData['email'] ?? '', // null 체크 후 추가
//       photoUrl: mapData['photoUrl'] ?? '',
//       uid: mapData['uid'] ?? '',
//     );
//   }
//
//   // Getters: 필요한 경우에만 사용하고, 필요없으면 삭제 가능
//   String get _name => nickname;
//   String get _emailId => email;
//   String get _photoUrl => photoUrl;
//   String get _uid => uid;
//
//
//   // Setters: 필요한 경우에만 사용하고, 필요없으면 삭제 가능
//   set _photoUrl(String photoUrl) {
//     this.photoUrl = photoUrl;
//   }
//
//   set _name(String name) {
//     this.nickname = nickname;
//   }
//
//   set _emailId(String emailId) {
//     this.email = email;
//   }
//
//   set _uid(String uid) {
//     this.uid = uid;
//   }
//
// }
//
//
