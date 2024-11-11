class AppVersion {
  final String version;
  final String apkFileName;
  final String releaseNotes;
  final bool forceUpdate;
  final String minRequiredVersion;

  AppVersion({
    required this.version,
    required this.apkFileName,
    required this.releaseNotes,
    this.forceUpdate = false,
    this.minRequiredVersion = '1.0.0',
  });

  factory AppVersion.fromMap(Map<dynamic, dynamic> map) {
    return AppVersion(
      version: map['version'] ?? '',
      apkFileName: map['apkFileName'] ?? '',
      releaseNotes: map['releaseNotes'] ?? '',
      forceUpdate: map['forceUpdate'] ?? false,
      minRequiredVersion: map['minRequiredVersion'] ?? '1.0.0',
    );
  }
}

