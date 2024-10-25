import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FlutterDownloader before running the app
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PermissionHandlerWidget(),
    );
  }
}

class PermissionHandlerWidget extends StatefulWidget {
  const PermissionHandlerWidget({super.key});

  @override
  State<PermissionHandlerWidget> createState() =>
      _PermissionHandlerWidgetState();
}

class _PermissionHandlerWidgetState extends State<PermissionHandlerWidget> {
  String downloadUrl = "https://pdfobject.com/pdf/sample.pdf";
  String? taskId;
  int progress = 0;
  late bool _permissionReady;
  late String _localPath;
  final ReceivePort _port = ReceivePort();
  bool _isDownloading = false;
  @override
  void initState() {
    super.initState();
    _bindBackgroundIsolate();
    FlutterDownloader.registerCallback(downloadCallback, step: 1);
    _permissionReady = false;
    _prepare();
  }

  void _bindBackgroundIsolate() {
    final isSuccess = IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'downloader_send_port',
    );
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      final taskId = (data as List<dynamic>)[0] as String;
      final status = DownloadTaskStatus.fromInt(data[1] as int);
      final progress = data[2] as int;

      print(
        'Callback on UI isolate: '
        'task ($taskId) is in status ($status) and progress ($progress)',
      );
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    print(
      'Callback on background isolate: '
      'task ($id) is in status ($status) and progress ($progress)',
    );

    IsolateNameServer.lookupPortByName('downloader_send_port')
        ?.send([id, status, progress]);
  }

  Future<void> _prepare() async {
    _permissionReady = await _requestStoragePermission();
    if (_permissionReady) {
      await _prepareSaveDir();
    }
  }

  Future<void> _prepareSaveDir() async {
    _localPath = (await _getSavedDir())!;
    final savedDir = Directory(_localPath);
    if (!savedDir.existsSync()) {
      await savedDir.create();
    }
  }

  Future<String?> _getSavedDir() async {
    String? externalStorageDirPath;
    externalStorageDirPath =
        (await getApplicationDocumentsDirectory()).absolute.path;

    return externalStorageDirPath;
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 300,
            child: Center(
              child: ListView(children: [
                ListTile(
                  title: Text("Request Notification Permission"),
                  onTap: () async {
                    bool result = await _requestPermission("notification");
                    _showPermissionStatus(result, "Notification");
                  },
                ),
                ListTile(
                  title: Text("Request Camera Permission"),
                  onTap: () async {
                    bool result = await _requestPermission("camera");
                    _showPermissionStatus(result, "Camera");
                  },
                ),
                ListTile(
                  title: const Text("Request Storage Permission"),
                  onTap: () async {
                    bool result = await _requestStoragePermission();
                    _showPermissionStatus(result, "Storage");
                  },
                ),
              ]),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _requestStoragePermission().then((value) {
                      if (value) {
                        _showDownloadDialog(); // Show the download dialog
                        _downloadFile(downloadUrl); // Start the download
                      }
                    });
                  },
                  child: const Text("Download PDF"),
                ),
                const SizedBox(height: 20),
                if (progress >
                    0) // Show progress bar if progress is greater than 0
                  Column(
                    children: [
                      Text('Download Progress: $progress%'),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: progress / 100),
                    ],
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<bool> _requestPermission(String permissionType) async {
    Permission permission;

    switch (permissionType.toLowerCase()) {
      case "notification":
        permission = Permission.notification;
        break;
      case "camera":
        permission = Permission.camera;
        break;
      case "storage":
        permission = Permission.storage;
        if (Platform.isAndroid) {
          // For Android 13 and higher, manage external storage is necessary
          final status = await permission.request();
          if (status.isDenied) {
            openAppSettings();
            return false; // Redirect to settings if denied
          }
          // Requesting manage external storage permission if needed
          if (await Permission.manageExternalStorage.isRestricted) {
            final manageStatus =
                await Permission.manageExternalStorage.request();
            return manageStatus
                .isGranted; // Return the status of manage external storage
          }
          return true; // Storage permission granted
        } else {
          openAppSettings(); // Open settings for iOS if needed
          return false;
        }
      default:
        return false; // Invalid permission type
    }

    // Request the specific permission
    final status = await permission.request();
    if (status.isDenied) {
      openAppSettings(); // Open settings if denied
      return false;
    }
    return status.isGranted;
  }

  Future<bool> _requestStoragePermission() async {
    bool granted = false;

    if (Platform.isAndroid) {
      DeviceInfoPlugin plugin = DeviceInfoPlugin();
      AndroidDeviceInfo android = await plugin.androidInfo;

      if (android.version.sdkInt < 33) {
        // For Android versions below 13
        PermissionStatus status = await Permission.storage.request();
        granted = status.isGranted;
      } else {
        // For Android 13 and above, handle media-specific permissions
        PermissionStatus photoStatus = await Permission.photos.request();
        PermissionStatus videoStatus = await Permission.videos.request();
        PermissionStatus audioStatus = await Permission.audio.request();
        granted = photoStatus.isGranted ||
            videoStatus.isGranted ||
            audioStatus.isGranted;
      }
    } else if (Platform.isIOS) {
      PermissionStatus status = await Permission.photos.request();
      granted = status.isGranted;
    } else {
      granted = true; // Other platforms automatically grant permission
    }

    return granted;
  }

  void _showPermissionStatus(bool granted, String permissionName) {
    String statusMessage;
    Color color = granted ? Colors.green : Colors.red;

    if (granted) {
      statusMessage = "$permissionName permission granted.";
    } else {
      statusMessage = "$permissionName permission denied.";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(statusMessage),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _downloadFile(String url) async {
    log('Saving to: $_localPath');

    setState(() {
      _isDownloading = true; // Update the state to indicate downloading
    });

    final taskId = await FlutterDownloader.enqueue(
      url: url,
      savedDir: _localPath,
      showNotification: true,
      openFileFromNotification: true,
      saveInPublicStorage: true, // Save in public storage
    );

    log('Download started with taskId: $taskId');

    // Wait for the download to complete
    FlutterDownloader.registerCallback((id, status, progress) {
      log('Download status: $status, progress: $progress');
      if (status == DownloadTaskStatus.complete) {
        // Close the dialog and show completed message
        setState(() {
          _isDownloading = false; // Update the state
        });
        // Navigator.of(context).pop(); // Close the dialog
        // _showCompletionDialog(); // Show completion dialog
      } else {
        setState(() {
          this.progress = progress; // Update progress
        });
      }
    });
  }

void _showDownloadDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, void Function(void Function()) setState) {
          // Update progress dynamically
          _port.listen((dynamic data) {
            final String taskId = (data as List<dynamic>)[0] as String;
            final DownloadTaskStatus status = DownloadTaskStatus.fromInt(data[1] as int);
            final int currentProgress = data[2] as int;

            // Update state to reflect progress
            setState(() {
              progress = currentProgress;
            });

            // Close dialog when download is complete
            if (status == DownloadTaskStatus.complete) {
             setState(() {
              
            });// Show completion message
            }
          });

          return AlertDialog(
            title: Text("Downloading..."),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress / 100),
                const SizedBox(height: 20),
             progress == 100
                    ? const Text("Downloaded")
                    : Text("Downloading... $progress%"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Optionally, you could cancel the download here
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text("Cancel"),
              ),
            ],
          );
        },
      );
    },
  );
}
}





