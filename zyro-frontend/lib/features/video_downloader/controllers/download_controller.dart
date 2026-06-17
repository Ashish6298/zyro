import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../core/browser_data_manager.dart';
import '../../../core/models/download_item.dart';
import '../models/current_playing_video.dart';
import '../models/download_request.dart';
import '../models/downloaded_video.dart';
import '../models/video_format.dart';
import '../services/download_api_service.dart';
import '../services/format_mapper_service.dart';
import '../services/local_storage_service.dart';
import '../services/media_store_service.dart';
import '../services/url_sanitizer_service.dart';

class DownloadController extends ChangeNotifier {
  final DownloadApiService _apiService = DownloadApiService();
  final FormatMapperService _mapperService = FormatMapperService();
  final LocalStorageService _storageService = LocalStorageService();
  final MediaStoreService _mediaStoreService = MediaStoreService();

  CurrentPlayingVideo? _currentPlayingVideo;
  List<DownloadedVideo> _downloadedVideos = [];
  final List<DownloadRequest> _activeRequests = [];
  final Map<String, Timer> _pollers = {};

  CurrentPlayingVideo? get currentPlayingVideo => _currentPlayingVideo;
  List<DownloadedVideo> get downloadedVideos => List.unmodifiable(_downloadedVideos);
  List<DownloadRequest> get activeRequests => List.unmodifiable(_activeRequests);

  DownloadController() {
    loadDownloadedVideos();
  }

  void updateCurrentPlayingVideo(CurrentPlayingVideo? video) {
    // Avoid redundant updates
    if (_currentPlayingVideo?.canonicalVideoUrl == video?.canonicalVideoUrl &&
        _currentPlayingVideo?.isPlaying == video?.isPlaying &&
        _currentPlayingVideo?.currentPlaybackTime == video?.currentPlaybackTime) {
      return;
    }
    _currentPlayingVideo = video;
    notifyListeners();
  }

  Future<void> loadDownloadedVideos() async {
    _downloadedVideos = await _storageService.loadDownloadedVideos();
    notifyListeners();
  }

  bool isDownloaded(String videoId, String quality) {
    return _downloadedVideos.any((v) => v.videoId == videoId && v.quality == quality);
  }

  DownloadedVideo? getDownloadedVideo(String videoId, String quality) {
    try {
      return _downloadedVideos.firstWhere((v) => v.videoId == videoId && v.quality == quality);
    } catch (_) {
      return null;
    }
  }

  bool isDownloading(String videoId, String quality) {
    return _activeRequests.any((r) =>
        UrlSanitizerService.extractVideoId(r.url) == videoId &&
        r.expectedHeight.toString() == quality.replaceAll('p', ''));
  }

  DownloadRequest? getActiveRequest(String videoId, String quality) {
    try {
      return _activeRequests.firstWhere((r) =>
          UrlSanitizerService.extractVideoId(r.url) == videoId &&
          r.expectedHeight.toString() == quality.replaceAll('p', ''));
    } catch (_) {
      return null;
    }
  }

  Future<List<UiFormatOption>> fetchAvailableFormats(String url) async {
    try {
      final cleanUrl = UrlSanitizerService.sanitizeSingleVideoUrl(url);
      debugPrint('Fetching formats from backend for URL: $cleanUrl');
      final data = await _apiService.fetchMetadata(cleanUrl);
      final rawFormats = (data['formats'] as List? ?? [])
          .map((f) => VideoFormat.fromJson(f as Map<String, dynamic>))
          .toList();
      return _mapperService.mapFormats(rawFormats);
    } catch (e) {
      debugPrint('Error fetching formats: $e');
      rethrow;
    }
  }

  void startBackendDownload({
    required String pageUrl,
    required String title,
    required UiFormatOption option,
    required BrowserDataManager dataManager,
  }) {
    final format = option.videoFormat;
    final expectedHeight = format.height;
    final mode = option.type;
    final resolutionLabel = option.label;

    final cleanUrl = UrlSanitizerService.sanitizeSingleVideoUrl(pageUrl);
    final videoId = UrlSanitizerService.extractVideoId(cleanUrl);

    // Guard against duplicate active downloads
    if (isDownloading(videoId, resolutionLabel)) {
      debugPrint('Already downloading this video & resolution');
      return;
    }

    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    final request = DownloadRequest(
      id: requestId,
      url: cleanUrl,
      title: title,
      formatId: format.formatId,
      expectedHeight: expectedHeight,
      mode: mode,
      state: DownloadState.extracting,
      progress: 0.0,
    );

    // Show temporary status item in BrowserDataManager too for backward compatibility
    dataManager.addBackendDownload(
      id: request.id,
      url: cleanUrl,
      title: title,
      resolution: resolutionLabel,
    );

    _activeRequests.insert(0, request);
    notifyListeners();

    _apiService.startDownload(
      url: cleanUrl,
      formatId: format.formatId,
      expectedHeight: expectedHeight,
      mode: mode,
    ).then((taskId) {
      _startPolling(taskId, request.id, resolutionLabel, title, videoId, dataManager);
    }).catchError((err) {
      _updateRequestState(request.id, DownloadState.failed, progress: 0.0, error: err.toString());
      dataManager.updateBackendDownload(request.id, progress: 0.0, isFailed: true, errorMessage: err.toString());
    });
  }

  void _startPolling(
    String taskId,
    String requestId,
    String resolutionLabel,
    String title,
    String videoId,
    BrowserDataManager dataManager,
  ) {
    _pollers[requestId]?.cancel();
    _pollers[requestId] = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
      try {
        final taskData = await _apiService.checkStatus(taskId);
        final stateStr = taskData['state'] as String? ?? 'failed';
        final progressVal = (taskData['progress'] as num? ?? 0).toDouble();
        final filename = taskData['filename'] as String?;
        final downloadUrl = taskData['downloadUrl'] as String?;
        final error = taskData['error'] as String?;

        final state = _mapState(stateStr);
        _updateRequestState(
          requestId,
          state,
          progress: progressVal / 100.0,
          error: error,
          downloadUrl: downloadUrl,
          filename: filename,
        );

        dataManager.updateBackendDownload(requestId, progress: progressVal / 100.0);

        if (state == DownloadState.completed) {
          timer.cancel();
          _pollers.remove(requestId);

          if (downloadUrl != null && filename != null) {
            final absoluteDownloadUrl = '${_apiService.baseUrl}$downloadUrl';
            debugPrint('Backend completed processing. Saving file locally from: $absoluteDownloadUrl');

            // Download the file stream and save it to Android local media storage folder
            _downloadFileAndSaveToLibrary(requestId, absoluteDownloadUrl, filename, resolutionLabel, videoId, dataManager);
          }
        } else if (state == DownloadState.failed) {
          timer.cancel();
          _pollers.remove(requestId);
          dataManager.updateBackendDownload(
            requestId,
            progress: 0.0,
            isFailed: true,
            errorMessage: error,
          );
        }
      } catch (e) {
        timer.cancel();
        _pollers.remove(requestId);
        _updateRequestState(requestId, DownloadState.failed, progress: 0.0, error: e.toString());
        dataManager.updateBackendDownload(
          requestId,
          progress: 0.0,
          isFailed: true,
          errorMessage: e.toString(),
        );
      }
    });
  }

  Future<void> _downloadFileAndSaveToLibrary(
    String requestId,
    String downloadUrl,
    String filename,
    String resolutionLabel,
    String videoId,
    BrowserDataManager dataManager,
  ) async {
    try {
      final ext = p.extension(filename);
      final baseName = p.basenameWithoutExtension(filename);
      final subFolder = ext.contains('mp3') ? 'audio' : 'video';
      final file = await _mediaStoreService.downloadFile(
        downloadUrl,
        baseName,
        ext,
        subFolder,
        (progress) {
          _updateRequestState(requestId, DownloadState.downloadingVideo, progress: progress);
          dataManager.updateBackendDownload(requestId, progress: progress);
        },
      );

      final fileSize = await file.length();

      // Create DownloadedVideo metadata
      final video = DownloadedVideo(
        id: requestId,
        title: filename,
        videoId: videoId,
        sourceUrl: _currentPlayingVideo?.canonicalVideoUrl ?? downloadUrl,
        localFilePath: file.path,
        quality: resolutionLabel,
        fileSize: fileSize,
        duration: _currentPlayingVideo?.duration ?? 0,
        thumbnailPath: _currentPlayingVideo?.thumbnail ?? '',
        downloadedAt: DateTime.now(),
        mimeType: ext.contains('mp3') ? 'audio/mpeg' : 'video/mp4',
      );

      // Save to library persistence
      await _storageService.addVideo(video);
      await loadDownloadedVideos();

      // Clear the temporary list items
      _activeRequests.removeWhere((r) => r.id == requestId);
      dataManager.removeDownload(requestId);
      notifyListeners();

      // Trigger standard download complete notification
      dataManager.lastFinishedDownload = DownloadItem(
        id: requestId,
        url: file.path,
        title: filename,
        resolution: resolutionLabel,
      );
      dataManager.notifyListeners();

    } catch (e) {
      debugPrint('Error saving file locally: $e');
      _updateRequestState(requestId, DownloadState.failed, progress: 0.0, error: e.toString());
      dataManager.updateBackendDownload(requestId, progress: 0.0, isFailed: true, errorMessage: e.toString());
    }
  }

  Future<void> deleteVideo(String id) async {
    final videoIndex = _downloadedVideos.indexWhere((v) => v.id == id);
    if (videoIndex != -1) {
      final video = _downloadedVideos[videoIndex];
      try {
        final file = File(video.localFilePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting local file: $e');
      }
      await _storageService.removeVideo(id);
      await loadDownloadedVideos();
    }
  }

  void removeFailedRequest(String requestId) {
    _activeRequests.removeWhere((r) => r.id == requestId);
    notifyListeners();
  }

  void _updateRequestState(
    String requestId,
    DownloadState state, {
    required double progress,
    String? error,
    String? downloadUrl,
    String? filename,
  }) {
    final idx = _activeRequests.indexWhere((r) => r.id == requestId);
    if (idx != -1) {
      _activeRequests[idx] = _activeRequests[idx].copyWith(
        state: state,
        progress: progress,
        error: error,
        downloadUrl: downloadUrl,
        filename: filename,
      );
      notifyListeners();
    }
  }

  DownloadState _mapState(String stateStr) {
    switch (stateStr) {
      case 'extracting':
        return DownloadState.extracting;
      case 'downloading_video':
        return DownloadState.downloadingVideo;
      case 'downloading_audio':
        return DownloadState.downloadingAudio;
      case 'merging':
        return DownloadState.merging;
      case 'completed':
        return DownloadState.completed;
      case 'failed':
      default:
        return DownloadState.failed;
    }
  }

  @override
  void dispose() {
    for (final timer in _pollers.values) {
      timer.cancel();
    }
    _pollers.clear();
    super.dispose();
  }
}
