enum UsagePeriod { today, month, allTime }

extension UsagePeriodLabel on UsagePeriod {
  String get label {
    return switch (this) {
      UsagePeriod.today => 'Today',
      UsagePeriod.month => 'This Month',
      UsagePeriod.allTime => 'All Time',
    };
  }
}
