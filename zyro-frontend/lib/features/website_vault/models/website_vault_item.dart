import 'website_vault_type.dart';

class WebsiteVaultItem {
  final String id;
  final String domain;
  final String origin;
  final String sourceUrl;
  final String title;
  final WebsiteVaultType type;
  final String? filePath;
  final String? mimeType;
  final int? fileSize;
  final String? thumbnailPath;
  final String? noteText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final bool isFavorite;

  const WebsiteVaultItem({
    required this.id,
    required this.domain,
    required this.origin,
    required this.sourceUrl,
    required this.title,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.filePath,
    this.mimeType,
    this.fileSize,
    this.thumbnailPath,
    this.noteText,
    this.tags = const [],
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'domain': domain,
    'origin': origin,
    'sourceUrl': sourceUrl,
    'title': title,
    'type': type.key,
    'filePath': filePath,
    'mimeType': mimeType,
    'fileSize': fileSize,
    'thumbnailPath': thumbnailPath,
    'noteText': noteText,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'tags': tags,
    'isFavorite': isFavorite,
  };

  factory WebsiteVaultItem.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return WebsiteVaultItem(
      id: map['id'] as String? ?? '',
      domain: map['domain'] as String? ?? '',
      origin: map['origin'] as String? ?? '',
      sourceUrl: map['sourceUrl'] as String? ?? '',
      title: map['title'] as String? ?? 'Saved item',
      type: WebsiteVaultTypeLabel.fromKey(map['type'] as String?),
      filePath: map['filePath'] as String?,
      mimeType: map['mimeType'] as String?,
      fileSize: (map['fileSize'] as num?)?.toInt(),
      thumbnailPath: map['thumbnailPath'] as String?,
      noteText: map['noteText'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? now,
      tags: (map['tags'] as List?)?.whereType<String>().toList() ?? const [],
      isFavorite: map['isFavorite'] == true,
    );
  }

  WebsiteVaultItem copyWith({
    String? title,
    String? noteText,
    List<String>? tags,
    bool? isFavorite,
    DateTime? updatedAt,
  }) {
    return WebsiteVaultItem(
      id: id,
      domain: domain,
      origin: origin,
      sourceUrl: sourceUrl,
      title: title ?? this.title,
      type: type,
      filePath: filePath,
      mimeType: mimeType,
      fileSize: fileSize,
      thumbnailPath: thumbnailPath,
      noteText: noteText ?? this.noteText,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
