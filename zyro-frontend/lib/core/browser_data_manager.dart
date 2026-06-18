import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'globals.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

import 'models/bookmark_item.dart';
import 'models/download_item.dart';
import 'models/history_item.dart';

class BrowserDataManager extends ChangeNotifier {
  static const MethodChannel _downloadChannel = MethodChannel('zyro/downloads');

  final List<HistoryItem> _history = [];
  final List<BookmarkItem> _bookmarks = [];
  final List<DownloadItem> _downloads = [];
  final List<Map<String, String>> _readingList = [];
  final List<Map<String, String>> _favorites = [];
  final List<Map<String, String>> _offlinePages = [];
  final Map<String, Timer> _downloadPollers = {};
  final _uuid = const Uuid();

  DownloadItem? lastFinishedDownload;

  List<HistoryItem> get history => List.unmodifiable(_history);
  List<BookmarkItem> get bookmarks => List.unmodifiable(_bookmarks);
  List<DownloadItem> get downloads => List.unmodifiable(_downloads);
  List<Map<String, String>> get readingList => List.unmodifiable(_readingList);
  List<Map<String, String>> get favorites => List.unmodifiable(_favorites);
  List<Map<String, String>> get offlinePages => List.unmodifiable(_offlinePages);

  void addToReadingList(String url, String title) {
    if (_readingList.any((e) => e['url'] == url)) return;
    _readingList.add({'url': url, 'title': title});
    notifyListeners();
  }

  void addToFavorites(String url, String title) {
    if (_favorites.any((e) => e['url'] == url)) return;
    _favorites.add({'url': url, 'title': title});
    notifyListeners();
  }

  void saveForOffline(String url, String title) {
    if (_offlinePages.any((e) => e['url'] == url)) return;
    _offlinePages.add({'url': url, 'title': title});
    notifyListeners();
  }

  void addHistory(String url, String title) {
    if (_history.isNotEmpty && _history.last.url == url) return;
    _history.add(HistoryItem(
      id: _uuid.v4(),
      url: url,
      title: title,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void toggleBookmark(String url, String title) {
    final index = _bookmarks.indexWhere((b) => b.url == url);
    if (index != -1) {
      _bookmarks.removeAt(index);
    } else {
      _bookmarks.add(BookmarkItem(
        id: _uuid.v4(),
        url: url,
        title: title,
      ));
    }
    notifyListeners();
  }

  void clearBookmarks() {
    _bookmarks.clear();
    notifyListeners();
  }

  bool isBookmarked(String url) {
    return _bookmarks.any((b) => b.url == url);
  }

  void addDownload(
    String url, {
    String title = 'Video Download',
    String resolution = '720p',
    String? suggestedFileName,
    String? mimeType,
    String? sourceUrl,
    String? pageUrl,
    bool isYouTube = false,
  }) {
    final normalizedUrl = _normalizeDownloadUrl(
      url,
      sourceUrl: sourceUrl,
      pageUrl: pageUrl,
      isYouTube: isYouTube,
    );
    final item = DownloadItem(
      id: _uuid.v4(),
      url: normalizedUrl,
      title: title,
      resolution: resolution,
    );
    _downloads.insert(0, item);
    notifyListeners();

    Future.microtask(() async {
      try {
        if (Platform.isAndroid && !_isYoutubeUrl(normalizedUrl)) {
          await _startAndroidSystemDownload(
            item,
            suggestedFileName: suggestedFileName,
            mimeType: mimeType,
          );
          return;
        }

        final hasPermission = await _ensureDownloadAccess();
        if (!hasPermission) {
          throw const FileSystemException('Storage permission denied');
        }

        final directory = await _resolveDownloadDirectory();
        if (directory == null) {
          throw const FileSystemException('Download directory unavailable');
        }

        final isAudio = item.resolution.contains('MP3');
        final subFolder = isAudio ? 'audio' : 'video';
        final zyroPath = p.join(directory.path, 'zyro', subFolder);
        final dir = Directory(zyroPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final extension = _resolveExtension(
          url: normalizedUrl,
          suggestedFileName: suggestedFileName,
          mimeType: mimeType,
          isAudio: isAudio,
        );
        final fileName = _buildFileName(item, extension, suggestedFileName: suggestedFileName);
        final filePath = p.join(zyroPath, fileName);

        await _downloadYoutubeToFile(item, filePath);

        item.filePath = filePath;
        item.progress = 1.0;
        item.isCompleted = true;
        item.isFailed = false;
        item.errorMessage = null;
        lastFinishedDownload = item;
        _showCompletionNotification(item.title);
        notifyListeners();
      } catch (e) {
        debugPrint('Error in download: $e');
        item.isCompleted = false;
        item.isFailed = true;
        item.errorMessage = e.toString();
        notifyListeners();
      }
    });
  }

  Future<void> _startAndroidSystemDownload(
    DownloadItem item, {
    String? suggestedFileName,
    String? mimeType,
  }) async {
    final isAudio = item.resolution.contains('MP3');
    final subFolder = isAudio ? 'audio' : 'video';
    final extension = _resolveExtension(
      url: item.url,
      suggestedFileName: suggestedFileName,
      mimeType: mimeType,
      isAudio: isAudio,
    );
    final fileName = _buildFileName(item, extension, suggestedFileName: suggestedFileName);
    final result = await _downloadChannel.invokeMapMethod<String, dynamic>(
      'enqueueDownload',
      <String, dynamic>{
        'url': item.url,
        'title': item.title,
        'description': item.title,
        'fileName': fileName,
        'subDirectory': 'zyro/$subFolder',
        'mimeType': mimeType ?? _guessMimeType(extension, isAudio),
      },
    );

    if (result == null || result['downloadId'] == null) {
      throw const FileSystemException('Unable to start Android download');
    }

    item.platformDownloadId = (result['downloadId'] as num).toInt();
    item.filePath = result['filePath'] as String?;
    notifyListeners();

    _downloadPollers[item.id]?.cancel();
    _downloadPollers[item.id] = Timer.periodic(const Duration(milliseconds: 750), (_) async {
      try {
        final status = await _downloadChannel.invokeMapMethod<String, dynamic>(
          'queryDownload',
          <String, dynamic>{'downloadId': item.platformDownloadId},
        );

        if (status == null) {
          return;
        }

        final downloadedBytes = (status['downloadedBytes'] as num?)?.toInt() ?? 0;
        final totalBytes = (status['totalBytes'] as num?)?.toInt() ?? 0;
        final state = status['status'] as String? ?? 'UNKNOWN';
        final localPath = status['localPath'] as String?;

        item.downloadedBytes = downloadedBytes;
        item.totalBytes = totalBytes > 0 ? totalBytes : null;
        if (totalBytes > 0) {
          item.progress = downloadedBytes / totalBytes;
        }
        if (localPath != null && localPath.isNotEmpty) {
          item.filePath = localPath;
        }

        if (state == 'SUCCESSFUL') {
          item.progress = 1.0;
          item.isCompleted = true;
          item.isFailed = false;
          item.errorMessage = null;
          lastFinishedDownload = item;
          _downloadPollers.remove(item.id)?.cancel();
          _showCompletionNotification(item.title);
        } else if (state == 'FAILED') {
          item.isCompleted = false;
          item.isFailed = true;
          item.errorMessage = status['reason']?.toString() ?? 'Download failed';
          _downloadPollers.remove(item.id)?.cancel();
        }

        notifyListeners();
      } catch (e) {
        _downloadPollers.remove(item.id)?.cancel();
        item.isCompleted = false;
        item.isFailed = true;
        item.errorMessage = e.toString();
        notifyListeners();
      }
    });
  }

  Future<void> _downloadYoutubeToFile(DownloadItem item, String filePath) async {
    final ytClient = yt.YoutubeExplode();
    try {
      final videoId = yt.VideoId.parseVideoId(item.url);
      if (videoId == null) {
        throw const FileSystemException('Invalid YouTube video URL');
      }

      final manifest = await ytClient.videos.streams.getManifest(videoId);
      final streamInfo = item.resolution.contains('MP3')
          ? manifest.audioOnly.withHighestBitrate()
          : manifest.muxed.withHighestBitrate();
      final stream = ytClient.videos.streams.get(streamInfo);
      final file = File(filePath);
      final fileStream = file.openWrite();

      final totalSize = streamInfo.size.totalBytes;
      item.totalBytes = totalSize;
      var downloadedCount = 0;

      await for (final data in stream) {
        fileStream.add(data);
        downloadedCount += data.length;
        item.downloadedBytes = downloadedCount;
        item.progress = downloadedCount / totalSize;
        notifyListeners();
      }

      await fileStream.flush();
      await fileStream.close();
    } finally {
      ytClient.close();
    }
  }

  Future<Directory?> _resolveDownloadDirectory() async {
    if (Platform.isAndroid) {
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return directory;
    }
    return getDownloadsDirectory();
  }

  Future<bool> _ensureDownloadAccess() async {
    if (!Platform.isAndroid) return true;

    final manageStorage = await Permission.manageExternalStorage.request();
    if (manageStorage.isGranted) {
      return true;
    }

    final storage = await Permission.storage.request();
    if (storage.isGranted) {
      return true;
    }

    final videos = await Permission.videos.request();
    if (videos.isGranted) {
      return true;
    }

    final audio = await Permission.audio.request();
    return audio.isGranted;
  }

  bool _isYoutubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  String _normalizeDownloadUrl(
    String url, {
    String? sourceUrl,
    String? pageUrl,
    bool isYouTube = false,
  }) {
    if (isYouTube) {
      if (pageUrl != null && _isYoutubeUrl(pageUrl)) {
        return pageUrl;
      }
      if (_isYoutubeUrl(url)) {
        return url;
      }
      if (sourceUrl != null && _isYoutubeUrl(sourceUrl)) {
        return sourceUrl;
      }
    }

    if (url.startsWith('blob:') && pageUrl != null) {
      return pageUrl;
    }

    return url;
  }

  String _buildFileName(
    DownloadItem item,
    String extension, {
    String? suggestedFileName,
  }) {
    final baseName = suggestedFileName != null && suggestedFileName.trim().isNotEmpty
        ? p.basenameWithoutExtension(suggestedFileName)
        : item.title;
    final cleanTitle = baseName.replaceAll(RegExp(r'[^\w\s-]+'), '_').trim();
    return '${cleanTitle.isEmpty ? 'download' : cleanTitle}_${item.id.substring(0, 4)}$extension';
  }

  String _resolveExtension({
    required String url,
    String? suggestedFileName,
    String? mimeType,
    required bool isAudio,
  }) {
    final fileName = suggestedFileName ?? '';
    final fromName = p.extension(fileName);
    if (fromName.isNotEmpty) {
      return fromName;
    }

    final fromUrl = p.extension(Uri.parse(url).path);
    if (fromUrl.isNotEmpty && fromUrl.length <= 5) {
      return fromUrl;
    }

    if (mimeType?.contains('mp4') == true) {
      return '.mp4';
    }
    if (mimeType?.contains('webm') == true) {
      return '.webm';
    }
    if (mimeType?.contains('mpeg') == true || mimeType?.contains('mp3') == true) {
      return '.mp3';
    }

    return isAudio ? '.mp3' : '.mp4';
  }

  String _guessMimeType(String extension, bool isAudio) {
    switch (extension.toLowerCase()) {
      case '.mp4':
        return 'video/mp4';
      case '.webm':
        return 'video/webm';
      case '.mkv':
        return 'video/x-matroska';
      case '.mp3':
        return 'audio/mpeg';
      case '.m4a':
        return 'audio/mp4';
      default:
        return isAudio ? 'audio/*' : 'video/*';
    }
  }

  /// Adds an in-progress download entry for a backend-managed download (yt-dlp/ffmpeg).
  /// This shows the item immediately in the Downloads screen while the backend processes.
  void addBackendDownload({
    required String id,
    required String url,
    required String title,
    required String resolution,
  }) {
    final item = DownloadItem(
      id: id,
      url: url,
      title: title,
      resolution: resolution,
    );
    _downloads.insert(0, item);
    notifyListeners();
  }

  /// Updates progress of a backend-managed download item.
  void updateBackendDownload(
    String id, {
    required double progress,
    bool isFailed = false,
    String? errorMessage,
  }) {
    final idx = _downloads.indexWhere((d) => d.id == id);
    if (idx == -1) return;
    final item = _downloads[idx];
    item.progress = progress;
    if (isFailed) {
      item.isFailed = true;
      item.errorMessage = errorMessage;
    }
    notifyListeners();
  }

  /// Removes a download item by id (used when handing off from backend to system download).
  void removeDownload(String id) {
    _downloads.removeWhere((d) => d.id == id);
    _downloadPollers.remove(id)?.cancel();
    notifyListeners();
  }

  void _showCompletionNotification(String title) {
    globalScaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done_rounded, color: Colors.cyanAccent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Download complete: $title',
                style: const TextStyle(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void clearDownloads() {
    for (final timer in _downloadPollers.values) {
      timer.cancel();
    }
    _downloadPollers.clear();
    _downloads.clear();
    notifyListeners();
  }
}
