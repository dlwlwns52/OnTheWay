const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// 첫 번째 함수: 도움 요청 푸시 알림 전송
exports.sendHelpNotification = functions.firestore
  .document('helpActions/{documentId}')
  .onCreate(async (snapshot, context) => {
        const helpAction = snapshot.data(); // 생성된 문서의 데이터를 가져옵니다.
        const helperEmail = helpAction.helper_email; // 도움을 제공하는 사용자의 이메일
        const postOwnerId = helpAction.post_id; // 게시물 소유자의 ID
        const helperNickname = helpAction.helper_email_nickname; // 추가된 닉네임 필드ㄴ
        const postOwnerEmail = helpAction.owner_email; // 게시물 작성자의 이메일
    
        // 게시물 작성자의 디바이스 토큰을 조회합니다.
        const postOwnerDoc = await admin.firestore().collection('users')
          .where('email', '==', postOwnerEmail).get();
    
        if (postOwnerDoc.empty) {
          console.log('No device token found for post owner.'); // 게시물 소유자의 디바이스 토큰이 없을 경우 로그에 메시지를 출력합니다.
          return null;
        }
    
        // 가정: 게시물 작성자의 디바이스 토큰을 가져옵니다. 첫 번째 일치 항목만 사용합니다.
        const postOwnerDeviceToken = postOwnerDoc.docs[0].data().token;
    

        const message = {
          notification: {
            title: '온더웨이',
            body: `${helperNickname}님이 도움을 요청했습니다.`
          },
          data: {
            screen: 'AlarmUi',
            ownerEmail: postOwnerEmail // 게시물 작성자의 이메일
          },
          token: postOwnerDeviceToken
        };

        // 푸시 알림을 보냅니다.
        try {
          const response = await admin.messaging().send(message); // 푸시 알림을 보내고 응답을 기다립니다.
          console.log('Successfully sent message:', response); // 푸시 알림을 성공적으로 보낸 경우 로그에 성공 메시지를 출력합니다.
        } catch (error) {
          console.log('Error sending message:', error); // 푸시 알림을 보내는 도중 오류가 발생한 경우 오류 메시지를 출력합니다.
        }
    
        return null; // 함수 실행 완료를 나타내기 위해 null을 반환합니다.
      });


// 두 번째 함수: 수락/거절 응답 푸시 알림 전송
exports.respondToHelpRequest = functions.firestore
  .document('helpActions/{documentId}')
  .onUpdate(async (change, context) => {
    const requestData = change.after.data(); // 업데이트된 문서 데이터
    const helperEmail = requestData.helper_email; // 도움을 제공한 사용자 이메일
    const response = requestData.response; // 요청에 대한 응답 ('accepted' 또는 'rejected')

    // 요청을 보낸 사용자의 디바이스 토큰 조회
    const helperDoc = await admin.firestore().collection('users')
      .where('email', '==', helperEmail).get();

    if (helperDoc.empty) {
      console.log('No device token found for helper.');
      return null;
    }

    const helperDeviceToken = helperDoc.docs[0].data().token; // 디바이스 토큰

    // 푸시 알림 메시지 구성
    const message = {
      notification: {
        title: '온더웨이',
        body: `귀하의 요청이 ${response === 'accepted' ? '수락되었습니다' : '거절되었습니다'}.`
      },
      token: helperDeviceToken
    };

    // 푸시 알림 전송
    try {
      const response = await admin.messaging().send(message);
      console.log('Successfully sent message:', response);
    } catch (error) {
      console.log('Error sending message:', error);
    }

    return null;
  });


//세 번째 함수 : 채팅방 생성 알림 함수
exports.notifyChatRoomCreated = functions.firestore
  .document('ChatActions/{documentId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // 요청이 수락된 경우만 처리
    if (beforeData.response !== 'accepted' && afterData.response === 'accepted') {
      const postOwnerId = afterData.post_id;
      const helperEmail = afterData.helper_email;
      const postOwnerEmail = afterData.owner_email; // 게시물 작성자의 이메일

      // 게시물 작성자의 디바이스 토큰 조회
      const postOwnerDoc = await admin.firestore().collection('users')
        .where('email', '==', postOwnerEmail).get();
      if (postOwnerDoc.empty) {
        console.log('No device token found for post owner.');
        return null;
      }
      const postOwnerDeviceToken = postOwnerDoc.docs[0].data().token;

      
      // 도움을 제공하는 사용자의 디바이스 토큰 조회
      const helperDoc = await admin.firestore().collection('users')
        .where('email', '==', helperEmail).get();
      if (helperDoc.empty) {
        console.log('No device token found for helper.');
        return null;
      }
      const helperDeviceToken = helperDoc.docs[0].data().token;

      // 채팅방 생성 알림 메시지
      const messageForPostOwner = {
        notification: {
          title: '온더웨이',
          body: '채팅방이 생성되었습니다.'
        },
        data: {
          screen: 'AllUsersScreen',
        },
        token: postOwnerDeviceToken // 게시물 소유자의 디바이스 토큰
      };

      const messageForHelper = {
        notification: {
          title: '온더웨이',
          body: '채팅방이 생성되었습니다.'
        },
        data: {
          screen: 'AllUsersScreen',
        },
        token: helperDeviceToken // 도움을 제공한 사용자의 디바이스 토큰
      };

      // 3초 지연 함수
      const delay = ms => new Promise(res => setTimeout(res, ms));

      try {
        // 3초 지연 후 알림 전송
        await delay(3000);
        await admin.messaging().send(messageForPostOwner);
        await admin.messaging().send(messageForHelper);
        console.log('Successfully sent chat room creation notifications');
      } catch (error) {
        console.log('Error sending chat room creation notifications:', error);
      }
    }

    return null;
  });


  
// 4번째 함수 채팅 메시지 푸시알림
exports.sendPushNotification = functions.firestore // Cloud Functions를 사용하여 Firestore 이벤트를 감지합니다.
    .document('ChatActions/{chatId}/messages/{messageId}') // 'ChatActions/{chatId}/messages/{messageId}' 경로의 문서에 변화가 있을 때 함수가 트리거됩니다.
    .onCreate(async (snapshot, context) => { // 새 문서가 생성될 때 실행되는 함수입니다.
        const messageData = snapshot.data(); // 생성된 문서의 데이터를 가져옵니다.
        const receiverName = messageData.receiverName; // 메시지의 수신자 닉네임을 가져옵니다.
        const senderName = messageData.senderName; // 메시지의 발신자 닉네임을 가져옵니다.
        
        // 수신자의 FCM 토큰을 가져오는 부분입니다.
        // 사용자의 FCM 토큰을 'users' 컬렉션에서 관리한다고 가정합니다.
        const tokenRef = admin.firestore().collection('users').doc(receiverName).get(); 

        //userStatus 상태 확인
        const userStatusRef = admin.firestore().collection('userStatus').doc(receiverName).collection('chatRooms').doc(context.params.chatId);
        const userStatusSnapshot = await userStatusRef.get();
        
        if (userStatusSnapshot.exists && userStatusSnapshot.data().isInChatRoom) {
          // 수신자가 채팅방에 있는 경우 푸시 알림을 보내지 않습니다.
          console.log('수신자가 채팅방에 있습니다. 푸시 알림을 보내지 않습니다.');
          return null;
      }

        return tokenRef.then(tokenDoc => { // 토큰 문서를 가져온 후 처리합니다.
            if (tokenDoc.exists) { // 토큰 문서가 존재하는 경우
                const token = tokenDoc.data().token; // 수신자의 FCM 토큰을 가져옵니다.

                // 푸시 알림의 내용을 설정합니다.
                const payload = {
                    notification: { 
                        title: messageData.senderName, // 알림의 제목
                        body: messageData.message, // 알림의 본문 (메시지 내용)
                        // 필요에 따라 추가 FCM 옵션을 설정할 수 있습니다.
                    },
                    data : {
                      screen: 'AllUsersScreen',
                    },
                    token: token // 알림을 받을 디바이스의 FCM 토큰
                };

                // 설정한 페이로드로 푸시 알림을 보냅니다.
                return admin.messaging().send(payload); 

            } else {
                console.log("FCM 토큰이 없음"); // FCM 토큰이 없는 경우 로그 출력
                return null;
            }
        });
    });


// 5번째 함수 한밭대 게시판에 게시물이 올라올때 한밭대 학생일 경우 푸시알림 전달
exports.sendPushNotificationToHanBatStudents = functions.firestore
    .document('naver_posts/{postId}')
    .onCreate(async (snap, context) => {
        // 새 게시물의 데이터를 변수에 저장합니다.
        const newValue = snap.data();
        const currentLocation = newValue.my_location; // 게시물 현재위치
        const storeLocation = newValue.store // 게시물 가격위치
        const cost = newValue.cost // 게시물 심부름비 
        const userEmail = newValue.user_email; // 게시물 작성자

        // 'users' 컬렉션에서 'domain' 필드가 'naver.com'인 사용자를 찾습니다.
        const userSnapshot = await admin.firestore().collection('users')
            .where('domain', '==', 'naver.com')
            .get();

        // 해당하는 사용자가 없으면 로그를 출력하고 함수를 종료합니다.
        if (userSnapshot.empty) {
            console.log('No matching users found.');
            return;
        }

        const tokens = []; // 푸시 알림을 받을 사용자들의 토큰을 저장할 배열입니다.

        // 쿼리 결과로 받은 사용자 문서들을 순회하며 푸시 토큰을 배열에 추가합니다.
        userSnapshot.forEach(doc => {
            const user = doc.data();
            if (user.token && user.email != userEmail) { // 'token' 필드가 존재하면 배열에 추가합니다.
                tokens.push(user.token);
            }
        });

        // 푸시 토큰이 있는 경우 푸시 알림을 전송합니다.
        if (tokens.length > 0){
          const message = {
              notification : {
                title : `새로운 게시물이 생성되었습니다! `,
                body : `위치 : ${storeLocation} → ${currentLocation}\n금액 : ${cost} \n상세 내용을 확인하고 신청하세요!`
              },
                tokens: tokens, // 알림을 받을 토큰 배열
            };

            try {
                // Firebase Cloud Messaging을 이용하여 알림을 전송합니다.
                const response = await admin.messaging().sendMulticast(message);
                console.log('Successfully sent message:', response);
            } catch (error) {
                // 알림 전송 중 에러가 발생하면 로그를 출력합니다.
                console.log('Error sending message:', error);
            }
        }
    });



// 6번째 함수 accept 값이 없는 것 12시간 후 삭제 - 오전 9시에 호출
exports.scheduledFunction = functions.pubsub.schedule('00 09 * * *').timeZone('Asia/Seoul').onRun(async (context) => {
  // 현재 시간을 Firestore 타임스탬프로 가져옵니다.
  const now = admin.firestore.Timestamp.now();
  console.log('Current timestamp:', now);
  
  // 현재 시간에서 12시간을 뺀 시간을 계산합니다.
  const cutoff = new Date(now.toDate().getTime() - 12 * 60 * 60 * 1000); // 12 hours ago
  const cutoffTimestamp = admin.firestore.Timestamp.fromDate(cutoff);
  console.log('Cutoff timestamp:', cutoffTimestamp);

  // 'ChatActions' 컬렉션에서 'response' 필드가 'accepted'가 아닌 문서들과
  // 'timestamp' 필드가 12시간 이전인 문서들을 쿼리합니다.
  const chatActionsQuery = admin.firestore().collection('ChatActions')
                    .where('response', '==', null)
                    .where('timestamp', '<', cutoffTimestamp);


  const helpActionsQuery = admin.firestore().collection('helpActions')
                    .where('response', '==', null)
                    .where('timestamp', '<', cutoffTimestamp);


  const PaymentsQuery = admin.firestore().collection('Payments')
                    .where('response', '==', null)
                    .where('timestamp', '<', cutoffTimestamp);

                  
  const [chatActionsSnapshot, helpActionsSnapshot, PaymentsSnapshot] = await Promise.all([
    chatActionsQuery.get(),
    helpActionsQuery.get(),
    PaymentsQuery.get()
  ]);
  console.log('Number of documents in ChatActions to delete:', chatActionsSnapshot.size);
  console.log('Number of documents in helpActions to delete:', helpActionsSnapshot.size);
  console.log('Number of documents in Payments to delete:', PaymentsSnapshot.size);

  
  const batch = admin.firestore().batch();
  
  // chatActionsSnapshot 삭제
  if (chatActionsSnapshot.empty) {
    console.log('No documents found in ChatActions.');
  } else {
    chatActionsSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
  }
  
  // helpActionsSnapshot 삭제
  if (helpActionsSnapshot.empty) {
    console.log('No documents found in helpActions.');
  } else {
    helpActionsSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
  }

    // PaymentsSnapshot 삭제
    if (PaymentsSnapshot.empty) {
      console.log('No documents found in helpActions.');
    } else {
      PaymentsSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
    }

  await batch.commit();
  console.log('Documents older than 48 hours have been deleted');
});