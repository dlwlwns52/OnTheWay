// 이 코드는 사용자 데이터를 나타내는 UserDetails 클래스를 정의하고,
// 사용자 데이터를 맵 형식으로 변환하거나 맵 데이터를 UserDetails 객체로 변환하는 기능을 제공합니다.
// 이 클래스는 Firebase Firestore에서 사용자 데이터를 읽고 쓰는 데 사용됩니다.
// 코드를 한 줄씩 주석으로 설명하겠습니다:
class UserDetails {

  String name;
  String emailId;
  String photoUrl;
  String uid;

  UserDetails({this.name, this.emailId, this.photoUrl, this.uid});

  Map toMap(UserDetails userDetails) {
    var data = Map<String, String>();
    data['name'] = userDetails.name;
    data['emailId'] = userDetails.emailId;
    data['photoUrl'] = userDetails.photoUrl;
    data['uid'] = userDetails.uid;
    return data;
  }

  UserDetails.fromMap(Map<String, String> mapData) {
    this.name = mapData['name'];
    this.emailId = mapData['emailId'];
    this.photoUrl = mapData['photoUrl'];
    this.uid = mapData['uid'];
  }

  String get _name => name;
  String get _emailId => emailId;
  String get _photoUrl => photoUrl;
  String get _uid => uid;

  set _photoUrl(String photoUrl) {
    this.photoUrl = photoUrl;
  }

  set _name(String name) {
    this.name = name;
  }

  set _emailId(String emailId) {
    this.emailId = emailId;
  }

  set _uid(String uid) {
    this.uid = uid;
  }

}