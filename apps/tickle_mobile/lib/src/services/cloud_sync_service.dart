import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:icloud_storage/icloud_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

class CloudSyncService {
  static const String _dbFileName = 'tickle.sqlite';
  // Use a designated folder in iCloud Drive or Google Drive
  static const String _iCloudContainerId = 'iCloud.com.maskedsyntax.tickle.tickleMobile';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  /// Synchronizes the local database with the cloud.
  /// Strategy: Last-Write-Wins based on file modification timestamp.
  Future<void> syncDatabase() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final localDbFile = File(p.join(dbFolder.path, _dbFileName));

      if (!await localDbFile.exists()) {
        debugPrint('CloudSync: Local DB does not exist, nothing to sync.');
        return;
      }

      if (Platform.isIOS || Platform.isMacOS) {
        await _syncWithICloud(localDbFile);
      } else if (Platform.isAndroid) {
        await _syncWithGoogleDrive(localDbFile);
      }
    } catch (e) {
      debugPrint('CloudSync: Error syncing database - $e');
    }
  }

  // --- iOS iCloud Sync ---

  Future<void> _syncWithICloud(File localFile) async {
    try {
      final localModTime = await localFile.lastModified();

      // Check if file exists in iCloud
      final files = await ICloudStorage.gather(
        containerId: _iCloudContainerId,
        onUpdate: (files) {},
      );

      ICloudFile? cloudFileMeta;
      try {
        cloudFileMeta = files.firstWhere((f) => f.relativePath == _dbFileName);
      } catch (e) {
        cloudFileMeta = null;
      }

      if (cloudFileMeta == null) {
        // Cloud file does not exist, upload local
        await _uploadToICloud(localFile);
        return;
      }

      final cloudModTime = cloudFileMeta.contentChangeDate;

      if (cloudModTime != null && cloudModTime.isAfter(localModTime)) {
        // Cloud is newer, download it
        await _downloadFromICloud(localFile);
      } else if (cloudModTime == null || localModTime.isAfter(cloudModTime)) {
        // Local is newer, upload it
        await _uploadToICloud(localFile);
      }
    } catch (e) {
      debugPrint('iCloud Sync Error: $e');
      rethrow;
    }
  }

  Future<void> _uploadToICloud(File localFile) async {
    await ICloudStorage.upload(
      containerId: _iCloudContainerId,
      filePath: localFile.path,
      destinationRelativePath: _dbFileName,
      onProgress: (stream) {
        stream.listen((progress) => debugPrint('iCloud Upload: $progress'));
      },
    );
  }

  Future<void> _downloadFromICloud(File localFile) async {
    await ICloudStorage.download(
      containerId: _iCloudContainerId,
      relativePath: _dbFileName,
      destinationFilePath: localFile.path,
      onProgress: (stream) {
        stream.listen((progress) => debugPrint('iCloud Download: $progress'));
      },
    );
  }

  // --- Android Google Drive Sync ---

  Future<void> _syncWithGoogleDrive(File localFile) async {
    try {
      final account = await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
      if (account == null) {
        debugPrint('Google Drive Sync: User not signed in.');
        return;
      }

      final authHeaders = await account.authHeaders;
      final authenticateClient = _GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      // Search for existing backup in appDataFolder
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_dbFileName'",
        $fields: 'files(id, name, modifiedTime)',
      );

      final localModTime = await localFile.lastModified();

      if (fileList.files == null || fileList.files!.isEmpty) {
        // No backup exists, upload
        await _uploadToDrive(driveApi, localFile);
        return;
      }

      final driveFile = fileList.files!.first;
      final driveModTime = driveFile.modifiedTime;

      if (driveModTime != null && driveModTime.isAfter(localModTime)) {
        // Drive is newer, download
        await _downloadFromDrive(driveApi, driveFile.id!, localFile);
      } else {
        // Local is newer, update existing drive file
        await _updateDriveFile(driveApi, driveFile.id!, localFile);
      }
    } catch (e) {
      debugPrint('Google Drive Sync Error: $e');
      rethrow;
    }
  }

  Future<void> _uploadToDrive(drive.DriveApi driveApi, File localFile) async {
    final fileToUpload = drive.File()
      ..name = _dbFileName
      ..parents = ['appDataFolder'];

    final media = drive.Media(localFile.openRead(), localFile.lengthSync());
    await driveApi.files.create(fileToUpload, uploadMedia: media);
    debugPrint('Google Drive: Upload complete');
  }

  Future<void> _updateDriveFile(drive.DriveApi driveApi, String fileId, File localFile) async {
    final fileToUpload = drive.File()..name = _dbFileName;
    final media = drive.Media(localFile.openRead(), localFile.lengthSync());
    await driveApi.files.update(fileToUpload, fileId, uploadMedia: media);
    debugPrint('Google Drive: Update complete');
  }

  Future<void> _downloadFromDrive(drive.DriveApi driveApi, String fileId, File localFile) async {
    final media = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    
    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    await localFile.writeAsBytes(bytes, flush: true);
    debugPrint('Google Drive: Download complete');
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
