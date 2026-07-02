import 'website_vault_type.dart';

class WebsiteVaultDomainSummary {
  final String domain;
  final String? faviconUrl;
  final int itemCount;
  final DateTime latestItemAt;
  final Map<WebsiteVaultType, int> typeCounts;
  final int totalStorageBytes;

  const WebsiteVaultDomainSummary({
    required this.domain,
    required this.itemCount,
    required this.latestItemAt,
    required this.typeCounts,
    required this.totalStorageBytes,
    this.faviconUrl,
  });
}
