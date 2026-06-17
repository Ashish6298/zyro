import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MediaStoreService {
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    // Try request manageExternalStorage first (Android 11+)
    if (await Permission.manageExternalStorage.request().isGranted) {
      return true;
    }

    // Try standard storage permissions
    if (await Permission.storage.request().isGranted) {
      return true;
    }

    // On Android 13+, these are media permissions
    final videoGranted = await Permission.videos.request().isGranted;
    final audioGranted = await Permission.audio.request().isGranted;
    return videoGranted || audioGranted;
  }

  Future<String> getSaveDirectoryPath({String subFolder = 'video'}) async {
    if (Platform.isAndroid) {
      // Direct path to public downloads directory
      final publicDir = Directory('/storage/emulated/0/Download/zyro/$subFolder');
      try {
        if (!await publicDir.exists()) {
          await publicDir.create(recursive: true);
        }
        // Test write ability
        final testFile = File(p.join(publicDir.path, '.test_write'));
        await testFile.writeAsString('test');
        await testFile.delete();
        return publicDir.path;
      } catch (_) {
        // Fallback to app-specific external storage downloads folder if restricted
        final appDir = await getExternalStorageDirectory();
        if (appDir != null) {
          final zyroDir = Directory(p.join(appDir.path, 'zyro', subFolder));
          if (!await zyroDir.exists()) {
            await zyroDir.create(recursive: true);
          }
          return zyroDir.path;
        }
      }
    } else {
      // Non-Android platforms (e.g. Windows)
      try {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          final zyroDir = Directory(p.join(downloadsDir.path, 'zyro', subFolder));
          if (!await zyroDir.exists()) {
            await zyroDir.create(recursive: true);
          }
          return zyroDir.path;
        }
      } catch (_) {}
    }
    
    // Fallback for non-Android or general error
    final docDir = await getApplicationDocumentsDirectory();
    final fallbackDir = Directory(p.join(docDir.path, 'zyro', subFolder));
    if (!await fallbackDir.exists()) {
      await fallbackDir.create(recursive: true);
    }
    return fallbackDir.path;
  }

  String sanitizeFileName(String fileName) {
    // Replace invalid characters with underscore
    return fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  Future<File> getUniqueFile(String directoryPath, String baseName, String extension) async {
    final sanitizedBase = sanitizeFileName(baseName);
    var targetPath = p.join(directoryPath, '$sanitizedBase$extension');
    var file = File(targetPath);
    var counter = 1;

    while (await file.exists()) {
      targetPath = p.join(directoryPath, '${sanitizedBase}_$counter$extension');
      file = File(targetPath);
      counter++;
    }

    return file;
  }

  Future<File> downloadFile(
    String fileUrl,
    String suggestedName,
    String extension,
    String subFolder,
    Function(double) onProgress,
  ) async {
    await requestStoragePermission();
    final saveDir = await getSaveDirectoryPath(subFolder: subFolder);
    final uniqueFile = await getUniqueFile(saveDir, suggestedName, extension);

    final client = http.Client();
    final request = http.Request('GET', Uri.parse(fileUrl));
    final response = await client.send(request);

    if (response.statusCode != 200) {
      throw Exception('Failed to download file from backend (Status: ${response.statusCode})');
    }

    final contentLength = response.contentLength ?? 0;
    var downloadedBytes = 0;
    final sink = uniqueFile.openWrite();

    await for (final chunk in response.stream) {
      sink.add(chunk);
      downloadedBytes += chunk.length;
      if (contentLength > 0) {
        onProgress(downloadedBytes / contentLength);
      }
    }

    await sink.flush();
    await sink.close();
    client.close();

    return uniqueFile;
  }
}
