import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
              bool result = await _requestPermission("storage");
              _showPermissionStatus(result, "Storage");
            },
          ),
        ]),
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
}
