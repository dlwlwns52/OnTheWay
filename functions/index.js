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
  
        // Firestore에서 배지 카운트를 가져오고, 없으면 0으로 초기화
        let currentBadgeCount = postOwnerDoc.docs[0].data().badgeCount || 0;
        currentBadgeCount += 1;  // 배지 카운트 증가
        
        // Firestore에 업데이트된 배지 카운트 저장
        await admin.firestore().collection('users').doc(postOwnerDoc.docs[0].id).update({
          badgeCount: currentBadgeCount
        });

        const message = {
          notification: {
            title: '온더웨이',
            body: `${helperNickname}님이 도움을 요청했습니다.`
          },
          data: {
            screen: 'AlarmUi',
            ownerEmail: postOwnerEmail // 게시물 작성자의 이메일
          },
          token: postOwnerDeviceToken,
          apns: {
            payload: {
              aps: {
                badge: currentBadgeCount,  // iOS 배지 설정
                sound: "default"
              }
            }
          }
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

    // 'accepted'인 경우에만 알림 전송
    if (response !== 'accepted') {
      console.log('Request was not accepted, no notification sent.');
      return null; // 수락되지 않았으므로 함수 종료
    }

    // 요청을 보낸 사용자의 디바이스 토큰 조회
    const helperDoc = await admin.firestore().collection('users')
      .where('email', '==', helperEmail).get();

    if (helperDoc.empty) {
      console.log('No device token found for helper.');
      return null;
    }

    const helperDeviceToken = helperDoc.docs[0].data().token; // 디바이스 토큰

    // Firestore에서 배지 카운트를 가져오고, 없으면 0으로 초기화
    let currentBadgeCount = helperDoc.docs[0].data().badgeCount || 0;
    currentBadgeCount += 1;  // 배지 카운트 증가
    
    // Firestore에 업데이트된 배지 카운트 저장
    await admin.firestore().collection('users').doc(helperDoc.docs[0].id).update({
      badgeCount: currentBadgeCount
    });

    // 푸시 알림 메시지 구성
    const message = {
      notification: {
        title: '온더웨이',
        body: '성공적으로 매칭되었습니다! \n진행상황에서 확인 후 진행해주세요!',
      },
      data: {
        screen: 'PaymentScreen1',
      },
      token: helperDeviceToken,
      apns: {
        payload: {
          aps: {
            badge: currentBadgeCount,  // iOS 배지 설정
            sound: "default"
          }
        }
      }
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
    if (beforeData.response === null && afterData.response === 'accepted') {
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


      // Firestore에서 배지 카운트를 가져오고, 없으면 0으로 초기화(오더)
      let currentOwnerBadgeCount = postOwnerDoc.docs[0].data().badgeCount || 0;
      currentOwnerBadgeCount += 1;  // 배지 카운트 증가
      
      // Firestore에 업데이트된 배지 카운트 저장
      await admin.firestore().collection('users').doc(postOwnerDoc.docs[0].id).update({
        badgeCount: currentOwnerBadgeCount
      });


          // Firestore에서 배지 카운트를 가져오고, 없으면 0으로 초기화(헬퍼)
      let currentHelperBadgeCount = helperDoc.docs[0].data().badgeCount || 0;
      currentHelperBadgeCount += 1;  // 배지 카운트 증가
      
      // Firestore에 업데이트된 배지 카운트 저장
      await admin.firestore().collection('users').doc(helperDoc.docs[0].id).update({
        badgeCount: currentHelperBadgeCount
      });




      // 채팅방 생성 알림 메시지
      const messageForPostOwner = {
        notification: {
          title: '온더웨이',
          body: '헬퍼와 연결되었습니다! 채팅방에서 세부 사항을 논의해보세요!'
        },
        data: {
          screen: 'AllUsersScreen',
        },
        token: postOwnerDeviceToken, // 게시물 소유자의 디바이스 토큰
        apns: {
          payload: {
            aps: {
              badge: currentOwnerBadgeCount,  // iOS 배지 설정
              sound: "default"
            }
          }
        }
      };

      const messageForHelper = {
        notification: {
          title: '온더웨이',
          body: '오더와 연결되었습니다! 채팅방에서 세부 사항을 논의해보세요!'
        },
        data: {
          screen: 'AllUsersScreen',
        },
        token: helperDeviceToken, // 도움을 제공한 사용자의 디바이스 토큰
        apns: {
          payload: {
            aps: {
              badge: currentHelperBadgeCount,  // iOS 배지 설정
              sound: "default"
            }
          }
        }
      };

      
      try {
      
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
        // Firestore에서 배지 카운트를 가져오고, 없으면 0으로 초기화
        const userDoc = await admin.firestore().collection('users').doc(receiverName).get();
        let currentBadgeCount = userDoc.exists && userDoc.data().badgeCount ? userDoc.data().badgeCount : 0;
        currentBadgeCount += 1;  // 배지 카운트 증가

        // Firestore에 업데이트된 배지 카운트 저장
        await admin.firestore().collection('users').doc(receiverName).update({
            badgeCount: currentBadgeCount
        });

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
                    token: token, // 알림을 받을 디바이스의 FCM 토큰
                    apns: { // iOS 푸시 알림 설정
                      payload: {
                          aps: {
                              badge: currentBadgeCount, // iOS 배지 카운트 설정
                              sound: "default"
                          }
                      }
                  },
                };

                // 설정한 페이로드로 푸시 알림을 보냅니다.
                return admin.messaging().send(payload); 

            } else {
                console.log("FCM 토큰이 없음"); // FCM 토큰이 없는 경우 로그 출력
                return null;
            }
        });
    });


// 5번째 함수 충남대 게시판에 게시물이 올라올때 충남대 학생일 경우 푸시알림 전달
exports.sendPushNotificationToCnuStudents = functions.firestore
    .document('g_cnu_ac_kr/{postId}')
    .onCreate(async (snap, context) => {
        // 새 게시물의 데이터를 변수에 저장합니다.
        const newValue = snap.data();
        const currentLocation = newValue.my_location; // 게시물 현재위치
        const storeLocation = newValue.store; // 게시물 가격위치
        const cost = newValue.cost; // 게시물 심부름비
        const userEmail = newValue.user_email; // 게시물 작성자
        
        // 'users' 컬렉션에서 'domain' 필드가 'g.cnu.ac.kr'인 사용자를 찾습니다.
        const userSnapshot = await admin.firestore().collection('users')
            .where('domain', '==', 'g.cnu.ac.kr')
            .get();

        if (userSnapshot.empty) {
            console.log('No matching users found.');
            return;
        }

        const tokens = []; // 푸시 알림을 받을 사용자들의 토큰을 저장할 배열입니다.
        const badgeUpdates = []; // 배지 업데이트 트랜잭션 배열
        const badgeCounts = [];  // 사용자별 새로운 배지 값을 저장할 배열
        
        // Firestore 트랜잭션 시작
        await admin.firestore().runTransaction(async (transaction) => {
            userSnapshot.forEach(doc => {
                const user = doc.data();
                if (user.token && user.email != userEmail) { 
                    tokens.push(user.token);
                    
                    // Firestore에서 배지 카운트 가져오기
                    const currentBadgeCount = user.badgeCount || 0;
                    const newBadgeCount = currentBadgeCount + 1;
                    badgeCounts.push(newBadgeCount);  // 새로운 배지 값 배열에 저장
                    
                    // 배지 업데이트 트랜잭션 추가
                    badgeUpdates.push(transaction.update(admin.firestore().collection('users').doc(doc.id), {
                        badgeCount: newBadgeCount
                    }));
                }
            });

            await Promise.all(badgeUpdates);  // 트랜잭션 커밋
        });

        // 푸시 토큰이 있는 경우 푸시 알림을 전송합니다.
        if (tokens.length > 0) {
            tokens.forEach((token, index) => {
                const message = {
                    notification: {
                        title: `새로운 요청이 생성되었습니다! `,
                        body: `위치: ${storeLocation} → ${currentLocation}\n금액: ${cost} \n상세 내용을 확인하고 신청하세요!`
                    },
                    data: {
                        screen: 'SchoolBoard',
                    },
                    token: token, // 개별 사용자 토큰
                    apns: {
                        payload: {
                            aps: {
                                badge: badgeCounts[index],  // 각 사용자에 맞는 배지 값
                                sound: "default"
                            }
                        }
                    }
                };

                // 메시지 전송
                admin.messaging().send(message)
                    .then((response) => {
                        console.log('Successfully sent message:', response);
                    })
                    .catch((error) => {
                        console.log('Error sending message:', error);
                    });
            });
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





// 7번째 함수: 결제 요청 전 '결제하기'를 눌렀을 때 알람 전송
exports.notRequestPushAlarm = functions.firestore
  .document('Payments/{documentId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    const helperEmail = afterData.helper_email; // 도움을 제공한 사용자 이메일

    if (beforeData.isPaymentRequested == null && afterData.isPaymentRequested === false) {
      // 요청을 보낸 사용자의 디바이스 토큰 조회
      const helperDoc = await admin.firestore().collection('users')
        .where('email', '==', helperEmail).get();

      if (helperDoc.empty) {
        console.log('No device token found for helper.');
        return null;
      }

      const helperDocRef = helperDoc.docs[0].ref;
      const helperDeviceToken = helperDoc.docs[0].data().token; // 디바이스 토큰


      // Firestore에서 배지 카운트를 가져오고, 없으면 0으로 초기화
      let currentHelperBadgeCount = helperDoc.docs[0].data().badgeCount || 0;
      currentHelperBadgeCount += 1;  // 배지 카운트 증가

      // Firestore에 업데이트된 배지 카운트 저장
      await helperDocRef.update({ badgeCount: currentHelperBadgeCount });


      // 푸시 알림 메시지 구성
      const message = {
        notification: {
          title: '온더웨이',
          body: `결제를 위해 헬퍼님의 결제 요청이 필요합니다! \n진행상황에서 '결제 요청하기'를 눌러주세요.`
        },
        data: {
          screen: 'PaymentScreen1',
        },
        token: helperDeviceToken,
        apns: {
          payload: {
            aps: {
              badge: currentHelperBadgeCount,  // iOS 배지 설정
              sound: "default"
            }
          }
        }
      };

      // 푸시 알림 전송
      try {
        const response = await admin.messaging().send(message);
        console.log('Successfully sent message:', response); // 성공 로그
      } catch (error) {
        console.log('Error sending message:', error);
      }
    }
    return null;
  });


  //8번째 함수 : 거래 완료시 수령완료 내역이 생성되었다는 알림
exports.notifyReceiptCompletion = functions.firestore
  .document('completedReceipts/{documentId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const ownerEmail = data.ownerEmail; 


    const userDoc = await admin.firestore().collection('users')
      .where('email', '==', ownerEmail).get();

    if (userDoc.empty) {
      console.log('No device token found for owner.');
      return null;
    }

    const ownerDeviceToken = userDoc.docs[0].data().token; 


    // Firestore에서 배지 카운트를 가져오고, 없으면 0으로 초기화
    let currentBadgeCount = userDoc.docs[0].data().badgeCount || 0;
    currentBadgeCount += 1;  // 배지 카운트 증가

    // Firestore에 업데이트된 배지 카운트 저장
    await admin.firestore().collection('users').doc(userDoc.docs[0].id).update({
      badgeCount: currentBadgeCount
    });


    const message = {
      notification: {
        title: '온더웨이',
        body: '거래가 종료되었습니다.\n수령완료 내역을 확인해주세요.\n계좌이체를 선택하셨을 경우 입금을 완료해 주세요.',
      },
      data: {
        screen: 'PaymentScreen2',
      },
      token: ownerDeviceToken,
      apns: {
        payload: {
          aps: {
            badge: currentBadgeCount,  // iOS 배지 설정
            sound: "default"
          }
        }
      }
    };


    try {
      await admin.messaging().send(message);
      console.log('Successfully sent receipt completion notification');
    } catch (error) {
      console.log('Error sending receipt completion notification:', error);
    }

    return null;
  });


  //9번째 함수 : 거래 완료시 전달완료 내역이 생성되었다는 알림
exports.notifyDeliveryCompletion = functions.firestore
  .document('completedDeliveries/{documentId}')
  .onCreate(async (snap, context) => {
    const data = snap.data(); // 생성된 문서 데이터
    const helperEmail = data.helperEmail; // 문서 필드에 있는 helperEmail

    // helperEmail을 가진 사용자의 디바이스 토큰 조회
    const userDoc = await admin.firestore().collection('users')
      .where('email', '==', helperEmail).get();

    if (userDoc.empty) {
      console.log('No device token found for helper.');
      return null;
    }

    const helperDeviceToken = userDoc.docs[0].data().token; // 디바이스 토큰

    // Firestore에서 배지 카운트를 가져오고, 없으면 0으로 초기화
    let currentBadgeCount = userDoc.docs[0].data().badgeCount || 0;
    currentBadgeCount += 1;  // 배지 카운트 증가

    // Firestore에 업데이트된 배지 카운트 저장
    await admin.firestore().collection('users').doc(userDoc.docs[0].id).update({
      badgeCount: currentBadgeCount
    });

  

    // 푸시 알림 메시지 구성
    const message = {
      notification: {
        title: '온더웨이',
        body: '성공적으로 물품을 전달하였습니다. \n전달완료 내역을 확인해 주세요.',
      },
      data: {
        screen: 'PaymentScreen3',
      },
      token: helperDeviceToken,
      apns: {
        payload: {
          aps: {
            badge: currentBadgeCount,  // iOS 배지 설정
            sound: "default"
          }
        }
      }
    };

    // 푸시 알림 전송
    try {
      await admin.messaging().send(message);
      console.log('Successfully sent delivery completion notification');
    } catch (error) {
      console.log('Error sending delivery completion notification:', error);
    }

    return null;
  });



  // 10번째 함수 x테스트 네이버 게시판에 게시물이 올라올때 한밭대 학생일 경우 푸시알림 전달
exports.sendPushNotificationToTestStudents = functions.firestore
    .document('naver_com/{postId}')
    .onCreate(async (snap, context) => {
        // 새 게시물의 데이터를 변수에 저장합니다.
        const newValue = snap.data();
        const currentLocation = newValue.my_location; // 게시물 현재위치
        const storeLocation = newValue.store; // 게시물 가격위치
        const cost = newValue.cost; // 게시물 심부름비
        const userEmail = newValue.user_email; // 게시물 작성자
        
        // 'users' 컬렉션에서 'domain' 필드가 'naver.com'인 사용자를 찾습니다.
        const userSnapshot = await admin.firestore().collection('users')
            .where('domain', '==', 'naver.com')
            .get();

        if (userSnapshot.empty) {
            console.log('No matching users found.');
            return;
        }

        const tokens = []; // 푸시 알림을 받을 사용자들의 토큰을 저장할 배열입니다.
        const badgeUpdates = []; // 배지 업데이트 트랜잭션 배열
        const badgeCounts = [];  // 사용자별 새로운 배지 값을 저장할 배열
        
        // Firestore 트랜잭션 시작
        await admin.firestore().runTransaction(async (transaction) => {
            userSnapshot.forEach(doc => {
                const user = doc.data();
                if (user.token && user.email != userEmail) { 
                    tokens.push(user.token);
                    
                    // Firestore에서 배지 카운트 가져오기
                    const currentBadgeCount = user.badgeCount || 0;
                    const newBadgeCount = currentBadgeCount + 1;
                    badgeCounts.push(newBadgeCount);  // 새로운 배지 값 배열에 저장
                    
                    // 배지 업데이트 트랜잭션 추가
                    badgeUpdates.push(transaction.update(admin.firestore().collection('users').doc(doc.id), {
                        badgeCount: newBadgeCount
                    }));
                }
            });

            await Promise.all(badgeUpdates);  // 트랜잭션 커밋
        });

        // 푸시 토큰이 있는 경우 푸시 알림을 전송합니다.
        if (tokens.length > 0) {
            tokens.forEach((token, index) => {
                const message = {
                    notification: {
                        title: `새로운 요청이 생성되었습니다! `,
                        body: `위치: ${storeLocation} → ${currentLocation}\n금액: ${cost} \n상세 내용을 확인하고 신청하세요!`
                    },
                    data: {
                        screen: 'SchoolBoard',
                    },
                    token: token, // 개별 사용자 토큰
                    apns: {
                        payload: {
                            aps: {
                                badge: badgeCounts[index],  // 각 사용자에 맞는 배지 값
                                sound: "default"
                            }
                        }
                    }
                };

                // 메시지 전송
                admin.messaging().send(message)
                    .then((response) => {
                        console.log('Successfully sent message:', response);
                    })
                    .catch((error) => {
                        console.log('Error sending message:', error);
                    });
            });
        }
    });

