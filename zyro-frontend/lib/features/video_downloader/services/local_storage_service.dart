import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/downloaded_video.dart';

class LocalStorageService {
  static const String _fileName = 'downloaded_videos.json';

  Future<File> _getStorageFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<List<DownloadedVideo>> loadDownloadedVideos() async {
    try {
      final file = await _getStorageFile();
      if (!await file.exists()) {
        return [];
      }
      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((item) => DownloadedVideo.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading downloaded videos: $e');
      return [];
    }
  }

  Future<void> saveDownloadedVideos(List<DownloadedVideo> videos) async {
    try {
      final file = await _getStorageFile();
      final jsonList = videos.map((v) => v.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('Error saving downloaded videos: $e');
    }
  }

  Future<void> addVideo(DownloadedVideo video) async {
    final videos = await loadDownloadedVideos();
    // Prevent duplicate entries
    videos.removeWhere((v) => v.id == video.id || (v.videoId == video.videoId && v.quality == video.quality));
    videos.insert(0, video);
    await saveDownloadedVideos(videos);
  }

  Future<void> removeVideo(String id) async {
    final videos = await loadDownloadedVideos();
    videos.removeWhere((v) => v.id == id);
    await saveDownloadedVideos(videos);
  }
}
