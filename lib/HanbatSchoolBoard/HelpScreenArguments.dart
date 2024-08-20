import 'package:cloud_firestore/cloud_firestore.dart';

class HelpScreenArguments {
  final DocumentSnapshot doc;
  final Function(bool) pushHelpButton;
  final String userName;
  final String timeAgo;
  final String location;
  final String cost;
  final String storeName;
  final String email;
  final String request;
  final String current_location;
  final String store_location;
  final bool isMyPost;




  HelpScreenArguments({
    required this.doc,
    required this.pushHelpButton,
    required this.userName,
    required this.timeAgo,
    required this.location,
    required this.cost,
    required this.storeName,
    required this.email,
    required this.request,
    required this.current_location,
    required this.store_location,
    required this.isMyPost,
  });
}
