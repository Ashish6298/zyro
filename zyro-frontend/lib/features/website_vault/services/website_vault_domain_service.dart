import '../../usage/services/domain_usage_normalizer.dart';

class WebsiteVaultDomainService {
  const WebsiteVaultDomainService();

  String? normalize(String? urlOrHost) {
    return DomainUsageNormalizer.normalize(urlOrHost);
  }

  String faviconUrl(String domain) {
    return 'https://www.google.com/s2/favicons?domain=$domain&sz=64';
  }
}
