// import 'package:flutter/material.dart';
// import 'package:tmap_ui_sdk/auth/data/auth_data.dart';
// import 'package:tmap_ui_sdk/auth/data/init_result.dart';
// import 'package:tmap_ui_sdk/route/data/planning_option.dart';
// import 'package:tmap_ui_sdk/route/data/route_point.dart';
// import 'package:tmap_ui_sdk/route/data/route_request_data.dart';
// import 'package:tmap_ui_sdk/tmap_ui_sdk.dart';
// import 'package:tmap_ui_sdk/tmap_ui_sdk_manager.dart';
// import 'package:tmap_ui_sdk/widget/tmap_view_widget.dart';
//
// class RouteMapScreen extends StatefulWidget {
//   @override
//   _RouteMapScreenState createState() => _RouteMapScreenState();
// }
//
// class _RouteMapScreenState extends State<RouteMapScreen> {
//
//   @override
//   void initState() {
//     super.initState();
//     initTmap();
//   }
//
//   Future<void> initTmap() async {
//     try {
//       String? platformVersion = await TmapUiSdk().getPlatformVersion();
//       AuthData authData = AuthData(
//         clientApiKey: "ZNBrF3RTfI6DtWPIa9AIs4yvkxDdCPWI3FZrXZsM", // 여기에 실제 Tmap API 키를 입력해야 합니다.
//         // 다른 필드는 필요에 따라 채워주세요
//       );
//
//       InitResult? result = await TmapUISDKManager().initSDK(authData);
//
//       if (platformVersion != null && result != null && result == InitResult.granted) {
//         print("초기화 성공 : $platformVersion / $result");
//       } else {
//         print("초기화 실패 : $platformVersion / $result");
//       }
//     } catch (e) {
//       print("error ${e.toString()}");
//     }
//   }
//
//   TmapViewWidget getTmapViewWidget() {
//     RouteRequestData data = RouteRequestData(
//       source: RoutePoint(latitude: 36.402461020967664, longitude: 127.42474065006031, name: "출발지"),
//       destination: RoutePoint(latitude: 36.44872437488492, longitude: 127.42882136402619, name: "도착지"),
//       routeOption: [PlanningOption.recommend, PlanningOption.shortest],
//     );
//
//     return TmapViewWidget(data: data);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('길찾기'),
//       ),
//       body: getTmapViewWidget(),
//     );
//   }
// }
//
//
