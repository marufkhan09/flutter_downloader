

// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';

// class DownloadPage extends StatefulWidget {
//   @override
//   _DownloadPageState createState() => _DownloadPageState();
// }

// // Sample PDF URL
// class _DownloadPageState extends State<DownloadPage> {
//   String downloadUrl =
//       "http://englishonlineclub.com/pdf/iOS%20Programming%20-%20The%20Big%20Nerd%20Ranch%20Guide%20(6th%20Edition)%20[EnglishOnlineClub.com].pdf";

//   String? taskId;
//   int progress = 0;

//   @override
//   void initState() {
//     super.initState();
//   }

//   Future<void> _requestPermissions() async {
//     if (Platform.isAndroid) {
//       PermissionStatus storagePermission = await Permission.storage.request();
//       PermissionStatus managePermission =
//           await Permission.manageExternalStorage.request();

//       if (storagePermission.isDenied || managePermission.isDenied) {
//         // Show alert dialog to inform the user about permission requirements
//         showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: Text("Permission Required"),
//             content: Text(
//                 "This app needs storage permissions to download files. Please allow them in the settings."),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop(); // Close the dialog
//                 },
//                 child: Text("OK"),
//               ),
//               TextButton(
//                 onPressed: () {
//                   openAppSettings(); // Open app settings for user to grant permissions
//                 },
//                 child: Text("Open Settings"),
//               ),
//             ],
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _downloadFile() async {
//     // Get external directory for saving the file
//     final directory = await getExternalStorageDirectory();
//     final savePath = '${directory?.path}/maruf.pdf'; // Specify full file path

//     // Initiate download
//     taskId = await FlutterDownloader.enqueue(
//       url: downloadUrl,
//       savedDir: directory?.path ?? '',
//       fileName:
//           "maruf_${DateTime.now().millisecondsSinceEpoch}.pdf", // Use a unique filename
//       showNotification: true,
//       openFileFromNotification: true,
//     );

//     // Listen for download progress
//     FlutterDownloader.registerCallback((id, status, progress) {
//       setState(() {
//         this.progress = progress;
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("PDF Downloader"),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton(
//               onPressed: () {
//                 _requestPermissions();
//               },
//               child: Text("Download PDF"),
//             ),
//             SizedBox(height: 20),
//             if (progress > 0) // Show progress bar if progress is greater than 0
//               Column(
//                 children: [
//                   Text('Download Progress: $progress%'),
//                   SizedBox(height: 10),
//                   LinearProgressIndicator(value: progress / 100),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
