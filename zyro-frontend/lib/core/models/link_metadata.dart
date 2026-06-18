enum LinkType {
  hyperlink,
  image,
  video,
  email,
  phone,
  pdf,
  download
}

class LinkMetadata {
  final String url;
  final String title;
  final String domain;
  final LinkType type;
  final String? extra;
  final String? imageSrcIfInsideLink;

  LinkMetadata({
    required this.url,
    required this.title,
    required this.domain,
    required this.type,
    this.extra,
    this.imageSrcIfInsideLink,
  });
}
