// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';

// class PermissionHandlerWidget extends StatefulWidget {
//   const PermissionHandlerWidget({super.key});

//   @override
//   State<PermissionHandlerWidget> createState() =>
//       _PermissionHandlerWidgetState();
// }

// class _PermissionHandlerWidgetState extends State<PermissionHandlerWidget> {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: ListView(children: [
//         ListTile(
//           title: Text("Request Notification Permission"),
//           onTap: () async {
//             bool result = await _requestPermission("notification");
//             _showPermissionStatus(result, "Notification");
//           },
//         ),
//         ListTile(
//           title: Text("Request Camera Permission"),
//           onTap: () async {
//             bool result = await _requestPermission("camera");
//             _showPermissionStatus(result, "Camera");
//           },
//         ),
//         ListTile(
//           title: const Text("Request Storage Permission"),
//           onTap: () async {
//             bool result = await _requestPermission("storage");
//             _showPermissionStatus(result, "Storage");
//           },
//         ),
//       ]),
//     );
//   }

//   Future<bool> _requestPermission(String permissionType) async {
//     Permission permission;

//     switch (permissionType.toLowerCase()) {
//       case "notification":
//         permission = Permission.notification;
//         break;
//       case "camera":
//         permission = Permission.camera;
//         break;
//       case "storage":
//         permission = Permission.storage;
//         if (Platform.isAndroid) {
//           // Request both storage and manage external storage on Android
//           final status = await permission.request();
//           if (status.isDenied) {
//             // Open settings if the permission is denied
//             openAppSettings();
//             return false;
//           }
//           final manageStatus = await Permission.manageExternalStorage.request();
//           return status.isGranted && manageStatus.isGranted;
//         } else {
//           // Open settings for iOS if needed
//           openAppSettings();
//           return false;
//         }
//       default:
//         return false; // Invalid permission type
//     }

//     final status = await permission.request();
//     if (status.isDenied) {
//       // Open settings if the permission is denied
//       openAppSettings();
//       return false;
//     }
//     return status.isGranted;
//   }

//   void _showPermissionStatus(bool granted, String permissionName) {
//     String statusMessage;
//     Color color = granted ? Colors.green : Colors.red;

//     if (granted) {
//       statusMessage = "$permissionName permission granted.";
//     } else {
//       statusMessage = "$permissionName permission denied.";
//     }

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(statusMessage),
//         backgroundColor: color,
//       ),
//     );
//   }
// }
