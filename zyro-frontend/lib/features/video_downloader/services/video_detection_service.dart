import '../models/current_playing_video.dart';
import 'url_sanitizer_service.dart';

class VideoDetectionService {
  bool canDetect(String url) {
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    
    final host = uri.host.toLowerCase();
    return host.contains('youtube.com') ||
        host.contains('youtu.be') ||
        host.contains('vimeo.com') ||
        host.contains('facebook.com') ||
        host.contains('instagram.com') ||
        host.contains('twitter.com') ||
        host.contains('x.com') ||
        host.contains('dailymotion.com') ||
        uri.path.contains('.mp4') ||
        uri.path.contains('.mkv') ||
        uri.path.contains('.webm');
  }

  String get detectionScript => """
    (function() {
      const isYouTube = window.location.hostname.includes('youtube.com');
      const getThumbnail = () => {
        if (isYouTube) {
          const vId = new URLSearchParams(window.location.search).get('v');
          return vId ? 'https://img.youtube.com/vi/' + vId + '/hqdefault.jpg' : '';
        }
        const metaImg = document.querySelector('meta[property="og:image"]');
        if (metaImg) return metaImg.content;
        const video = document.querySelector('video');
        return video ? video.poster : '';
      };

      const getDuration = (video) => {
        if (video.duration && !isNaN(video.duration)) {
          return Math.floor(video.duration);
        }
        return 0;
      };

      const getCurrentPlaybackTime = (video) => {
        if (video.currentTime && !isNaN(video.currentTime)) {
          return Math.floor(video.currentTime);
        }
        return 0;
      };

      const checkVideoState = () => {
        const videos = Array.from(document.querySelectorAll('video'));
        let activeVideo = null;
        if (isYouTube) {
          activeVideo = document.querySelector('.html5-main-video') || 
                        document.querySelector('video.video-stream') ||
                        videos.find(v => v.src || v.currentSrc);
        } else {
          activeVideo = videos.find(v => v.offsetWidth > 0 && v.offsetHeight > 0) || videos[0];
        }

        if (activeVideo && (activeVideo.src || activeVideo.currentSrc)) {
          const isPlaying = !activeVideo.paused && !activeVideo.ended;
          const videoSrc = activeVideo.src || activeVideo.currentSrc || '';
          const usePageUrl = isYouTube || videoSrc.startsWith('blob:');
          
          window.flutter_inappwebview.callHandler('updatePlayingVideo', {
            sourcePageUrl: window.location.href,
            canonicalVideoUrl: usePageUrl ? window.location.href : videoSrc,
            title: document.title || 'Video',
            thumbnail: getThumbnail(),
            duration: getDuration(activeVideo),
            currentPlaybackTime: getCurrentPlaybackTime(activeVideo),
            isPlaying: isPlaying
          });
        }
      };

      if (!window.zyroVideoDetectorStarted) {
        window.zyroVideoDetectorStarted = true;
        setInterval(checkVideoState, 1500);
        checkVideoState();
      }
    })();
  """;

  CurrentPlayingVideo? parseVideoState(Map<String, dynamic> data) {
    try {
      final String pageUrl = data['sourcePageUrl'] as String;
      final String videoUrl = data['canonicalVideoUrl'] as String;

      // Sanitize client-side
      final cleanPageUrl = UrlSanitizerService.sanitizeSingleVideoUrl(pageUrl);
      final cleanVideoUrl = UrlSanitizerService.sanitizeSingleVideoUrl(videoUrl);
      final videoId = UrlSanitizerService.extractVideoId(cleanPageUrl);

      return CurrentPlayingVideo(
        sourcePageUrl: cleanPageUrl,
        canonicalVideoUrl: cleanVideoUrl,
        videoId: videoId,
        title: data['title'] as String? ?? 'Video',
        thumbnail: data['thumbnail'] as String? ?? '',
        duration: (data['duration'] as num?)?.toInt() ?? 0,
        currentPlaybackTime: (data['currentPlaybackTime'] as num?)?.toInt() ?? 0,
        detectedAt: DateTime.now(),
        isPlaying: data['isPlaying'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}
