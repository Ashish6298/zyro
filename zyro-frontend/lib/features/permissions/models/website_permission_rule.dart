import 'permission_enums.dart';

class WebsitePermissionRule {
  final String id;
  final String domain;
  final String origin;
  final PermissionType permissionType;
  final PermissionStatus status;
  final DateTime lastRequestedAt;
  final DateTime lastUpdatedAt;
  final String source;

  const WebsitePermissionRule({
    required this.id,
    required this.domain,
    required this.origin,
    required this.permissionType,
    required this.status,
    required this.lastRequestedAt,
    required this.lastUpdatedAt,
    required this.source,
  });

  WebsitePermissionRule copyWith({
    PermissionStatus? status,
    DateTime? lastRequestedAt,
    DateTime? lastUpdatedAt,
  }) => WebsitePermissionRule(
    id: id,
    domain: domain,
    origin: origin,
    permissionType: permissionType,
    status: status ?? this.status,
    lastRequestedAt: lastRequestedAt ?? this.lastRequestedAt,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    source: source,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'domain': domain,
    'origin': origin,
    'permissionType': permissionType.name,
    'status': status.name,
    'lastRequestedAt': lastRequestedAt.toIso8601String(),
    'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
    'source': source,
  };

  factory WebsitePermissionRule.fromMap(Map<String, dynamic> map) =>
      WebsitePermissionRule(
        id: map['id'] as String,
        domain: map['domain'] as String,
        origin: map['origin'] as String,
        permissionType: PermissionType.values.byName(
          map['permissionType'] as String,
        ),
        status: PermissionStatus.values.byName(map['status'] as String),
        lastRequestedAt: DateTime.parse(map['lastRequestedAt'] as String),
        lastUpdatedAt: DateTime.parse(map['lastUpdatedAt'] as String),
        source: map['source'] as String? ?? 'webview',
      );
}
