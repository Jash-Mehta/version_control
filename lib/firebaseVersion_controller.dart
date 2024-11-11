import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppVersion {
  final String version;
  final String minRequiredVersion;
  final String releaseNotes;
  final String downloadUrl;
  final bool forceUpdate;

  AppVersion({
    required this.version,
    required this.minRequiredVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    this.forceUpdate = false,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      version: json['version'],
      minRequiredVersion: json['minRequiredVersion'],
      releaseNotes: json['releaseNotes'],
      downloadUrl: json['downloadUrl'],
      forceUpdate: json['forceUpdate'] ?? false,
    );
  }
}

class VersionController {
  // Replace with your JSON endpoint URL (can be a GitHub Gist or any hosting service)
  static const String VERSION_CHECK_URL = 'YOUR_VERSION_JSON_URL';
  
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      bool permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        _showPermissionDialog(context);
        return;
      }

      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      final response = await http.get(Uri.parse(VERSION_CHECK_URL));
      if (response.statusCode == 200) {
        final versionData = json.decode(response.body);
        AppVersion latestVersion = AppVersion.fromJson(versionData);

        if (_isUpdateRequired(currentVersion, latestVersion.version)) {
          if (_isVersionCompatible(currentVersion, latestVersion.minRequiredVersion)) {
            _showUpdateDialog(context, latestVersion);
          } else {
            _showForceUpdateDialog(context, latestVersion);
          }
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
      _showErrorDialog(context, 'Failed to check for updates: ${e.toString()}');
    }
  }

  static Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final storage = await Permission.storage.request();
      final install = await Permission.requestInstallPackages.request();
      
      return storage.isGranted && install.isGranted;
    }
    return true; // For iOS, no special permissions needed for App Store updates
  }

  static bool _isUpdateRequired(String currentVersion, String newVersion) {
    List<int> current = currentVersion.split('.').map(int.parse).toList();
    List<int> latest = newVersion.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      if (latest[i] > current[i]) return true;
      if (latest[i] < current[i]) return false;
    }
    return false;
  }

  static bool _isVersionCompatible(String currentVersion, String minRequired) {
    List<int> current = currentVersion.split('.').map(int.parse).toList();
    List<int> minimum = minRequired.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      if (current[i] < minimum[i]) return false;
      if (current[i] > minimum[i]) return true;
    }
    return true;
  }

  static Future<void> _downloadAndInstallUpdate(
      BuildContext context, AppVersion version) async {
    try {
      final progressDialogKey = GlobalKey<_DownloadProgressDialogState>();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _DownloadProgressDialog(key: progressDialogKey),
      );

      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/app-update.apk';
      final file = File(filePath);

      final request = await http.Client().get(Uri.parse(version.downloadUrl));
      final contentLength = int.parse(request.headers['content-length'] ?? '0');

      final bytes = <int>[];
      int downloadedBytes = 0;

      // await for (final chunk in request.stream) {
      //   bytes.addAll(chunk);
      //   downloadedBytes += chunk.length;
      //   if (contentLength > 0) {
      //     final progress = downloadedBytes / contentLength;
      //     progressDialogKey.currentState?.updateProgress(progress);
      //   }
      // }

      await file.writeAsBytes(bytes);
      Navigator.pop(context); // Close progress dialog

      // Install new version
      if (Platform.isAndroid) {
      //  await InstallPlugin.installApk(filePath);
      }
    } catch (e) {
      Navigator.pop(context); // Close progress dialog
      _showErrorDialog(context, 'Failed to install update: $e');
    }
  }

  static void _showUpdateDialog(BuildContext context, AppVersion version) {
    showDialog(
      context: context,
      barrierDismissible: !version.forceUpdate,
      builder: (context) => AlertDialog(
        title: Text('New Update Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version ${version.version} is available'),
            SizedBox(height: 8),
            Text('What\'s New:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(version.releaseNotes),
          ],
        ),
        actions: [
          if (!version.forceUpdate)
            TextButton(
              child: Text('Later'),
              onPressed: () => Navigator.pop(context),
            ),
          TextButton(
            child: Text('Update Now'),
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstallUpdate(context, version);
            },
          ),
        ],
      ),
    );
  }

  static void _showForceUpdateDialog(BuildContext context, AppVersion version) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Critical Update Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your app version is no longer supported. Please update to continue.'),
            SizedBox(height: 8),
            Text('New Version: ${version.version}'),
            Text(version.releaseNotes),
          ],
        ),
        actions: [
          TextButton(
            child: Text('Update Now'),
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstallUpdate(context, version);
            },
          ),
        ],
      ),
    );
  }

  static void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permissions Required'),
        content: Text('Please grant storage and installation permissions to update the app.'),
        actions: [
          TextButton(
            child: Text('Open Settings'),
            onPressed: () => openAppSettings(),
          ),
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _DownloadProgressDialog extends StatefulWidget {
  const _DownloadProgressDialog({Key? key}) : super(key: key);

  @override
  _DownloadProgressDialogState createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0;

  void updateProgress(double progress) {
    setState(() {
      _progress = progress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Downloading Update'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: _progress),
          SizedBox(height: 16),
          Text('${(_progress * 100).toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}