import 'dart:convert';

class UsageEntry {
  final String domain;
  final int totalBytes;
  final int monthlyBytes;
  final int todayBytes;
  final DateTime lastVisitedAt;
  final int requestCount;
  final String? category;
  final String? faviconUrl;
  final String monthKey;
  final String dayKey;

  const UsageEntry({
    required this.domain,
    required this.totalBytes,
    required this.monthlyBytes,
    required this.todayBytes,
    required this.lastVisitedAt,
    required this.requestCount,
    required this.monthKey,
    required this.dayKey,
    this.category,
    this.faviconUrl,
  });

  factory UsageEntry.empty(String domain, DateTime now) {
    return UsageEntry(
      domain: domain,
      totalBytes: 0,
      monthlyBytes: 0,
      todayBytes: 0,
      lastVisitedAt: now,
      requestCount: 0,
      monthKey: monthKeyFor(now),
      dayKey: dayKeyFor(now),
    );
  }

  UsageEntry record({
    required int bytes,
    required DateTime now,
    String? category,
    String? faviconUrl,
  }) {
    final currentMonthKey = monthKeyFor(now);
    final currentDayKey = dayKeyFor(now);
    final currentMonthlyBytes = monthKey == currentMonthKey ? monthlyBytes : 0;
    final currentTodayBytes = dayKey == currentDayKey ? todayBytes : 0;

    return UsageEntry(
      domain: domain,
      totalBytes: totalBytes + bytes,
      monthlyBytes: currentMonthlyBytes + bytes,
      todayBytes: currentTodayBytes + bytes,
      lastVisitedAt: now,
      requestCount: requestCount + 1,
      monthKey: currentMonthKey,
      dayKey: currentDayKey,
      category: category ?? this.category,
      faviconUrl: faviconUrl ?? this.faviconUrl,
    );
  }

  UsageEntry rolledTo(DateTime now) {
    final currentMonthKey = monthKeyFor(now);
    final currentDayKey = dayKeyFor(now);
    return UsageEntry(
      domain: domain,
      totalBytes: totalBytes,
      monthlyBytes: monthKey == currentMonthKey ? monthlyBytes : 0,
      todayBytes: dayKey == currentDayKey ? todayBytes : 0,
      lastVisitedAt: lastVisitedAt,
      requestCount: requestCount,
      monthKey: currentMonthKey,
      dayKey: currentDayKey,
      category: category,
      faviconUrl: faviconUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'domain': domain,
      'totalBytes': totalBytes,
      'monthlyBytes': monthlyBytes,
      'todayBytes': todayBytes,
      'lastVisitedAt': lastVisitedAt.toIso8601String(),
      'requestCount': requestCount,
      'category': category,
      'faviconUrl': faviconUrl,
      'monthKey': monthKey,
      'dayKey': dayKey,
    };
  }

  factory UsageEntry.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now();
    return UsageEntry(
      domain: map['domain'] as String? ?? '',
      totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
      monthlyBytes: (map['monthlyBytes'] as num?)?.toInt() ?? 0,
      todayBytes: (map['todayBytes'] as num?)?.toInt() ?? 0,
      lastVisitedAt:
          DateTime.tryParse(map['lastVisitedAt'] as String? ?? '') ?? now,
      requestCount: (map['requestCount'] as num?)?.toInt() ?? 0,
      category: map['category'] as String?,
      faviconUrl: map['faviconUrl'] as String?,
      monthKey: map['monthKey'] as String? ?? monthKeyFor(now),
      dayKey: map['dayKey'] as String? ?? dayKeyFor(now),
    );
  }

  String toJson() => json.encode(toMap());

  factory UsageEntry.fromJson(String source) {
    return UsageEntry.fromMap(json.decode(source) as Map<String, dynamic>);
  }

  static String monthKeyFor(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
  }

  static String dayKeyFor(DateTime date) {
    return '${monthKeyFor(date)}-${date.day.toString().padLeft(2, '0')}';
  }
}
