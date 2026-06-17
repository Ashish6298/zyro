class VideoFormat {
  final String formatId;
  final String ext;
  final int? height;
  final int? fps;
  final String vcodec;
  final String acodec;
  final double? bitrate;
  final int? filesize;
  final bool hasAudio;
  final bool hasVideo;
  final bool isProgressive;
  final String container;

  VideoFormat({
    required this.formatId,
    required this.ext,
    this.height,
    this.fps,
    required this.vcodec,
    required this.acodec,
    this.bitrate,
    this.filesize,
    required this.hasAudio,
    required this.hasVideo,
    required this.isProgressive,
    required this.container,
  });

  factory VideoFormat.fromJson(Map<String, dynamic> json) {
    return VideoFormat(
      formatId: json['formatId'] as String? ?? '',
      ext: json['ext'] as String? ?? '',
      height: (json['height'] as num?)?.toInt(),
      fps: (json['fps'] as num?)?.toInt(),
      vcodec: json['vcodec'] as String? ?? 'none',
      acodec: json['acodec'] as String? ?? 'none',
      bitrate: (json['bitrate'] as num?)?.toDouble(),
      filesize: (json['filesize'] as num?)?.toInt(),
      hasAudio: json['hasAudio'] as bool? ?? false,
      hasVideo: json['hasVideo'] as bool? ?? false,
      isProgressive: json['isProgressive'] as bool? ?? false,
      container: json['container'] as String? ?? '',
    );
  }
}
