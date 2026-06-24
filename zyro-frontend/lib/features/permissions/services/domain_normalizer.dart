class DomainDetails {
  final String domain;
  final String origin;
  const DomainDetails({required this.domain, required this.origin});
}

class DomainNormalizer {
  static DomainDetails normalize(String value) {
    final uri = Uri.tryParse(value.contains('://') ? value : 'https://$value');
    final host = (uri?.host.isNotEmpty == true ? uri!.host : value)
        .toLowerCase()
        .replaceFirst(RegExp(r'^www\\.'), '');
    final origin = uri != null && uri.host.isNotEmpty
        ? '${uri.scheme.isEmpty ? 'https' : uri.scheme}://${uri.host}'
        : 'https://$host';
    return DomainDetails(domain: host, origin: origin);
  }
}
