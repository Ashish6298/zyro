class UrlSanitizerService {
  static String sanitizeSingleVideoUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('blob:')) {
      url = url.replaceFirst('blob:', '');
    }
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();

      if (host.contains('youtube.com') || host.contains('youtu.be')) {
        String? videoId;

        if (host.contains('youtu.be')) {
          videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        } else {
          videoId = uri.queryParameters['v'];
          if (videoId == null && uri.path.startsWith('/embed/')) {
            videoId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
          } else if (videoId == null && uri.path.startsWith('/shorts/')) {
            videoId = uri.pathSegments.length > 1 ? uri.pathSegments[1] : null;
          }
        }

        if (videoId != null && videoId.isNotEmpty) {
          // Strip any query parameter appended in path-based IDs
          final cleanId = videoId.split('?').first.split('&').first;
          return 'https://www.youtube.com/watch?v=$cleanId';
        }
      }

      // Strip common playlist/autoplay parameters
      final queryParams = Map<String, String>.from(uri.queryParameters);
      final keysToRemove = ['list', 'index', 'start_radio', 'autoplay', 'playlist'];
      for (final key in keysToRemove) {
        queryParams.remove(key);
      }

      final cleanUri = uri.replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      return cleanUri.toString();
    } catch (_) {
      return url;
    }
  }

  static String extractVideoId(String url) {
    if (url.isEmpty) return '';
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();

      if (host.contains('youtube.com') || host.contains('youtu.be')) {
        if (host.contains('youtu.be')) {
          return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
        } else {
          final v = uri.queryParameters['v'];
          if (v != null) return v;
          if (uri.path.startsWith('/embed/') || uri.path.startsWith('/shorts/')) {
            return uri.pathSegments.length > 1 ? uri.pathSegments[1] : '';
          }
        }
      }
      
      // Fallback: use hash or simple query parameter or filename
      return uri.queryParameters['v'] ?? uri.pathSegments.last;
    } catch (_) {
      return '';
    }
  }
}
