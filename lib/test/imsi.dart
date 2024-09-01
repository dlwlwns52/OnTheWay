// // 새로운 메시지가 추가되었는지 확인
// if (messages.length > _previousMessageCount) {
// _shouldAutoScroll = true;
// } else {
// _shouldAutoScroll = false;
// }
// _previousMessageCount = messages.length;
//
// // 자동 스크롤 실행
// WidgetsBinding.instance.addPostFrameCallback((_) {
// if (_scrollController.hasClients && _shouldAutoScroll) {
// _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
// }
// });