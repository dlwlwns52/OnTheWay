// // 비동기 함수로 이미지를 선택하고 업로드하는 과정을 처리합니다.
// Future<List<String>> _pickImage() async {
//   final ImagePicker _picker = ImagePicker(); // ImagePicker 객체를 생성합니다.
//   final List<XFile>? selectedImages = await _picker.pickMultiImage(); // 사용자가 여러 이미지를 선택할 수 있게 합니다.
//   List<String> uploadImageUrls = []; // 업로드된 이미지의 URL들을 저장할 리스트입니다.
//
//   // 선택된 이미지들이 있는지 확인합니다.
//   if (selectedImages != null && selectedImages.isNotEmpty) {
//     // 선택된 이미지 파일들을 File 타입으로 변환합니다.
//     List<File> imageFiles = selectedImages.map((xFile) => File(xFile.path)).toList();
//
//     // 선택된 이미지를 보여주고 업로드를 진행할지 결정하는 UI
//     List<String>? result = await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(30.0), // 대화상자 모서리를 둥글게 합니다.
//         ),
//         title: Text('사진 확인',
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87),
//           textAlign: TextAlign.center,),
//         content: Container(
//           height: 300,
//           width: double.infinity,
//           child: SingleChildScrollView(
//             child: Column(
//               children: imageFiles.map((file) => Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8.0),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(25.0), // 이미지 모서리를 둥글게 합니다.
//                   child: Image.file(file, fit: BoxFit.cover), // 이미지를 화면에 맞춰 표시합니다.
//                 ),
//               )).toList(),
//             ),
//           ),
//         ),
//         actionsAlignment: MainAxisAlignment.spaceEvenly,
//         actions: <Widget>[
//           ElevatedButton.icon(
//             icon: Icon(Icons.send, color: Colors.white),
//             label: Text('보내기'),
//             style: ElevatedButton.styleFrom(
//               primary: Colors.orangeAccent, // 버튼 색상을 오렌지색으로 설정합니다.
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20), // 버튼 모서리를 둥글게 합니다.
//               ),
//               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             ),
//             onPressed: () async {
//               for (var imageFile in imageFiles) {
//                 // Firebase Storage에 이미지를 업로드합니다.
//                 Reference storageReference = FirebaseStorage.instance
//                     .ref()
//                     .child('images/${DateTime.now().millisecondsSinceEpoch}');
//                 UploadTask uploadTask = storageReference.putFile(imageFile);
//                 TaskSnapshot taskSnapshot = await uploadTask;
//                 String downloadUrl = await taskSnapshot.ref.getDownloadURL(); // 업로드된 이미지의 URL을 가져옵니다.
//                 uploadImageUrls.add(downloadUrl); // 가져온 URL을 리스트에 추가합니다.
//               }
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text(
//                   "이미지가 전송되고 있습니다. 잠시만 기다려 주세요.",
//                   textAlign: TextAlign.center,
//                 ),
//                   duration: Duration(seconds: 1),
//                 ),
//               );
//               Navigator.of(context).pop(uploadImageUrls); // 업로드된 이미지 URL 리스트를 반환합니다.
//             },
//           ),
//
//           ElevatedButton.icon(
//             icon: Icon(Icons.cancel, color: Colors.white),
//             label: Text('취소'),
//             style: ElevatedButton.styleFrom(
//               primary: Colors.grey, // 버튼 색상을 회색으로 설정합니다.
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20), // 버튼 모서리를 둥글게 합니다.
//               ),
//               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             ),
//             onPressed: () => Navigator.of(context).pop(), // 대화상자를 닫습니다.
//           ),
//
//         ],
//       ),
//     );
//     return result ?? []; // 대화상자로부터 반환된 결과를 반환하거나, 결과가 없으면 빈 리스트를 반환합니다.
//   }
//   return uploadImageUrls; // 선택된 이미지가 없으면 빈 리스트를 반환합니다.
// }
//
//
//
//
// //이미지 파이어스토어에 저장
// void _uploadImageToDb(String downloadUrl) {
//   DateTime now = DateTime.now();
//   Timestamp timestamp = Timestamp.fromDate(now); // DateTime을 Timestamp로 변환
//
//   if (_senderUid != null) {
//     Message message = Message.withoutMessage(
//       receiverName : widget.receiverName,
//       senderName : widget.senderName,
//       receiverUid: widget.receiverUid,
//       senderUid: _senderUid!,
//       photoUrl: downloadUrl,
//       timestamp: timestamp,
//       message: '사진',
//       read: false,
//       isDeleted: false,
//       type: 'image',
//
//     );
//
//     // _addMessageToDb 함수를 사용하여 메시지 추가
//     _addMessageToDb(message);
//   }
// }