import 'dart:convert';

class AdBlockStatsModel {
  final int totalBlocked;
  final int todayBlocked;
  final String lastUpdatedDate; // yyyy-MM-dd
  final Map<String, int> domainBlockedCounts;

  AdBlockStatsModel({
    required this.totalBlocked,
    required this.todayBlocked,
    required this.lastUpdatedDate,
    required this.domainBlockedCounts,
  });

  factory AdBlockStatsModel.empty() {
    return AdBlockStatsModel(
      totalBlocked: 0,
      todayBlocked: 0,
      lastUpdatedDate: _getTodayString(),
      domainBlockedCounts: {},
    );
  }

  AdBlockStatsModel copyWith({
    int? totalBlocked,
    int? todayBlocked,
    String? lastUpdatedDate,
    Map<String, int>? domainBlockedCounts,
  }) {
    return AdBlockStatsModel(
      totalBlocked: totalBlocked ?? this.totalBlocked,
      todayBlocked: todayBlocked ?? this.todayBlocked,
      lastUpdatedDate: lastUpdatedDate ?? this.lastUpdatedDate,
      domainBlockedCounts: domainBlockedCounts ?? this.domainBlockedCounts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalBlocked': totalBlocked,
      'todayBlocked': todayBlocked,
      'lastUpdatedDate': lastUpdatedDate,
      'domainBlockedCounts': domainBlockedCounts,
    };
  }

  factory AdBlockStatsModel.fromMap(Map<String, dynamic> map) {
    return AdBlockStatsModel(
      totalBlocked: map['totalBlocked'] ?? 0,
      todayBlocked: map['todayBlocked'] ?? 0,
      lastUpdatedDate: map['lastUpdatedDate'] ?? _getTodayString(),
      domainBlockedCounts: Map<String, int>.from(map['domainBlockedCounts'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory AdBlockStatsModel.fromJson(String source) => AdBlockStatsModel.fromMap(json.decode(source));

  static String _getTodayString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }
}
