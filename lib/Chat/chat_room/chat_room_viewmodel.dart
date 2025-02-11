import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';

import 'chat_room_model.dart';

class ChatRoomViewModel extends ChangeNotifier{

  final ChatRoomModel model = ChatRoomModel();              // 데이터 모델 인스턴스 (Model 연결)
  List<DocumentSnapshot> acceptedChatActions = [];          // 수락된 도움말 액션 목록 저장 (채팅방 데이터)
  Map<String, DateTime?> lastMessageTimes = {};             // 채팅방 별 마지막 메시지 시간 저장 (키: 채팅방 ID, 값: 시간)
  Map<String, int> messageCounts = {};                      // 사용자별 메시지 수 저장 (키: "채팅방ID-사용자이메일", 값: 읽지 않은 메시지 수)

  late StreamSubscription<dynamic> _chatActionsSubscription; // Firestore 스트림 구독
  late StreamSubscription<DocumentSnapshot> _messageCountSubscription;

  bool _isNearBottom = false; // 스크롤 하단 여부

  bool get isNearBottom => _isNearBottom;
  set isNearBottom(bool value) {
    if (_isNearBottom != value) {
      _isNearBottom = value;
      notifyListeners();
    }
  }

  Future<String?>? _nickname;
  Future<String?>? get nickname => _nickname;

  String? nicknameValue;

  int _messageCount = 0;
  int get messageCount => _messageCount;




  //---------------------------------------------------------------------
  Future<void> getNickname(String botton_email) async {
    _nickname = model.getNickname(botton_email);
    notifyListeners();
    nicknameValue = await _nickname;
  }



  Stream<DocumentSnapshot> getMessageCountStreamVm(String nickname) {
    return model.getMessageCountStream(nickname);
  }


  Future<void> resetMessageCountVm(String nickname) async{
    await model.resetMessageCount(nickname);
    notifyListeners();
  }


  // Helper의 채팅방 삭제 로직
  Future<void> handleDeleteChatRoom(String documentId, String userNickname) async {
    await model.updateDeleteStatus(documentId, userNickname);
    await model.deleteUserStatusChatRoom(documentId, userNickname);
    notifyListeners(); // 상태 변경 알림
  }


// helper의 isDeleted_ 와 owner의 isDeleted_ 두 개 다 모두 활성화 시 문서 삭제
  Future<void> deleteChatRoomIfBothDeleted(String documentId, String helperNickname, String ownerNickname) async {
    // 채팅방 문서 참조
    DocumentReference chatRoomRef = FirebaseFirestore.instance.collection('ChatActions').doc(documentId);

    // 채팅방 문서 가져오기
    DocumentSnapshot chatRoomSnapshot = await chatRoomRef.get();

    if (chatRoomSnapshot.exists) {
      Map<String, dynamic> chatRoomData = chatRoomSnapshot.data() as Map<String, dynamic>;

      // 두 사용자 모두 채팅방을 삭제했는지 확인
      bool isHelperDeleted = chatRoomData['isDeleted_$helperNickname'] ?? false;
      bool isOwnerDeleted = chatRoomData['isDeleted_$ownerNickname'] ?? false;

      if (isHelperDeleted && isOwnerDeleted) {
        // 채팅방에 있는 모든 이미지 URL 가져오기
        QuerySnapshot messagesImageSnapshot = await chatRoomRef.collection('messages')
            .where('type', isEqualTo: 'image')
            .get();

        // Firebase Storage에서 이미지 삭제
        for (var doc in messagesImageSnapshot.docs) {
          var messageData = doc.data() as Map<String, dynamic>;
          var photoUrl = messageData['photoUrl'];
          if (photoUrl != null) {
            try {
              await FirebaseStorage.instance.refFromURL(photoUrl).delete();
            } catch (e) {
              print("Error deleting image from Storage: $e");
            }
          }
        }

        // 서브컬렉션의 모든 문서 삭제
        await model.deleteSubCollection(chatRoomRef);
        // 두 사용자 모두 채팅방을 삭제했다면 문서 삭제
        await chatRoomRef.delete();
        notifyListeners();
      }
    }
  }



  //------------------------

  // 이 함수는 현재 로그인한 사용자의 채팅방 목록을 가져오고, 각 채팅방의 최신 메시지 시간에 따라 목록을 정렬합니다.
  Future<void> fetchChatActions() async {
    // 현재 로그인한 사용자 정보를 가져옵니다.
    User? currentUser = FirebaseAuth.instance.currentUser;
    // 사용자가 로그인하지 않았거나 이메일 정보가 없다면 함수를 종료합니다.
    if (currentUser == null || currentUser.email == null) {
      return;
    }

    // 현재 사용자의 이메일 주소를 가져옵니다.
    String currentUserEmail = currentUser.email!;
    // 'helper_email' 필드가 현재 사용자의 이메일과 일치하는 'ChatActions' 컬렉션의 문서 스트림을 가져옵니다.
    var helperEmailStream = FirebaseFirestore.instance
        .collection('ChatActions')
        .where('response', isEqualTo: 'accepted')
        .where('helper_email', isEqualTo: currentUserEmail)
        .snapshots();

    // 'owner_email' 필드가 현재 사용자의 이메일과 일치하는 'ChatActions' 컬렉션의 문서 스트림을 가져옵니다.
    var ownerEmailStream = FirebaseFirestore.instance
        .collection('ChatActions')
        .where('response', isEqualTo: 'accepted')
        .where('owner_email', isEqualTo: currentUserEmail)
        .snapshots();

    // 두 스트림을 결합하여 채팅방 목록을 생성합니다.
    _chatActionsSubscription = Rx.combineLatest2(helperEmailStream, ownerEmailStream, (QuerySnapshot helperSnapshot, QuerySnapshot ownerSnapshot) async {
      // helperEmailStream과 ownerEmailStream에서 받은 문서들을 결합합니다.
      var combinedDocs = {...helperSnapshot.docs, ...ownerSnapshot.docs}.toList();

      // 각 채팅방의 마지막 메시지 시간을 비동기적으로 가져오는 작업 목록을 생성합니다.
      var fetchLastMessageFutures = <Future<void>>[];

      for (var doc in combinedDocs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
        _updateMessageCount(doc.id, userData);

        var docName = doc.id;
        fetchLastMessageFutures.add(
          model.fetchLastMessage(docName).then((timestamp) {
            lastMessageTimes[docName] = timestamp ?? doc.get('timestamp').toDate();
          }),
        );
      }

      // 모든 채팅방의 마지막 메시지 시간을 가져온 후에 목록을 정렬합니다.
      await Future.wait(fetchLastMessageFutures);
      combinedDocs.sort((a, b) => lastMessageTimes[b.id]!.compareTo(lastMessageTimes[a.id]!));

      acceptedChatActions = combinedDocs;
      notifyListeners(); // 상태 변경을 알림

    }
    ).listen(
          (data) {},
      onError: (error) {
        // 스트림에서 오류가 발생한 경우 로그를 출력합니다.
        print("An error occurred: $error");
      },
    );
  }


  Future<void> _updateMessageCount(documentName, userData) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    String? currentUserEmail = currentUser?.email;
    String? helperNickname = userData['helper_email_nickname'];
    String? ownerNickname = userData['owner_email_nickname'];
    String helperMessageCountKey = "$documentName-${userData['helper_email']}";
    String ownerMessageCountKey = "$documentName-${userData['owner_email']}";

    try {
      if (userData['helper_email'] == currentUserEmail) {
        _messageCountSubscription = FirebaseFirestore.instance
            .collection('ChatActions')
            .doc(documentName)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            var data = snapshot.data() as Map<String, dynamic>;
            messageCounts[helperMessageCountKey] = data['messageCount_$helperNickname'] ?? 0;
            notifyListeners();
          }
        });
      } else if (userData['owner_email'] == currentUserEmail) {
        _messageCountSubscription = FirebaseFirestore.instance
            .collection('ChatActions')
            .doc(documentName)
            .snapshots()
            .listen((snapshot) {
          if (snapshot.exists) {
            var data = snapshot.data() as Map<String, dynamic>;
            messageCounts[ownerMessageCountKey] = data['messageCount_$ownerNickname'] ?? 0;
            notifyListeners();
          }
        });
      }
    } catch (error) {
      print("Error updating message count: $error");
    }
  }



  // 시간을 '분 전' 형식으로 변환하는 함수
  String getTimeAgo(DateTime dateTime) {
    final Duration difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes <= 1){
      return '방금 전';
    }
    if ( 1 < difference.inMinutes  && difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    }
    else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    }
    else {
      return '${difference.inDays}일 전';
    }
  }


  @override
  void dispose() {
    _chatActionsSubscription.cancel();
    _messageCountSubscription.cancel();
    super.dispose();
  }

}