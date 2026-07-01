class QrCodeUrlDetails {
  final String url;
  final String domain;

  const QrCodeUrlDetails({required this.url, required this.domain});
}

class QrCodeUrlService {
  const QrCodeUrlService._();

  static QrCodeUrlDetails? currentPage(String? rawUrl) {
    final url = rawUrl?.trim();
    if (url == null || url.isEmpty || url == 'about:blank') return null;

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;

    return QrCodeUrlDetails(
      url: url,
      domain: uri.host.replaceFirst(RegExp(r'^www\.'), ''),
    );
  }
}
