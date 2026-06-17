import '../models/video_format.dart';

class UiFormatOption {
  final String label;
  final VideoFormat videoFormat;
  final String description;
  final String type; // 'video' or 'audio'

  UiFormatOption({
    required this.label,
    required this.videoFormat,
    required this.description,
    required this.type,
  });
}

class FormatMapperService {
  List<UiFormatOption> mapFormats(List<VideoFormat> formats) {
    final List<UiFormatOption> options = [];
    final Map<int, VideoFormat> bestVideoFormats = {};
    final List<VideoFormat> audioFormats = [];

    for (final f in formats) {
      if (f.hasVideo) {
        final height = f.height ?? 0;
        if (height > 0) {
          final existing = bestVideoFormats[height];
          if (existing == null) {
            bestVideoFormats[height] = f;
          } else {
            final existingScore = (existing.isProgressive ? 1000 : 0) + (existing.bitrate ?? 0);
            final newScore = (f.isProgressive ? 1000 : 0) + (f.bitrate ?? 0);
            if (newScore > existingScore) {
              bestVideoFormats[height] = f;
            }
          }
        }
      } else if (f.hasAudio) {
        audioFormats.add(f);
      }
    }

    bestVideoFormats.forEach((height, f) {
      final label = "${height}p";
      final details = <String>[];
      details.add(f.container.toUpperCase());
      if (f.fps != null && f.fps! > 0) {
        details.add("${f.fps} FPS");
      }
      if (f.filesize != null) {
        details.add(_formatFilesize(f.filesize!));
      }
      
      if (f.isProgressive) {
        details.add("direct download");
      } else {
        details.add("video+audio merge required");
      }

      options.add(UiFormatOption(
        label: label,
        videoFormat: f,
        description: details.join(" • "),
        type: 'video',
      ));
    });

    options.sort((a, b) => (b.videoFormat.height ?? 0).compareTo(a.videoFormat.height ?? 0));

    if (audioFormats.isNotEmpty) {
      audioFormats.sort((a, b) => (b.bitrate ?? 0).compareTo(a.bitrate ?? 0));
      final bestAudio = audioFormats.first;
      final details = <String>[];
      details.add("MP3 (converted)");
      if (bestAudio.filesize != null) {
        details.add(_formatFilesize(bestAudio.filesize!));
      } else if (bestAudio.bitrate != null) {
        details.add("${bestAudio.bitrate!.round()} kbps");
      }

      options.add(UiFormatOption(
        label: "MP3 Audio",
        videoFormat: bestAudio,
        description: details.join(" • "),
        type: 'audio',
      ));
    }

    return options;
  }

  String _formatFilesize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return "${size.toStringAsFixed(1)} ${suffixes[i]}";
  }
}
