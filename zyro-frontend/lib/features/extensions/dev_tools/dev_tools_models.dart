import 'dart:convert';

class SelectedElementInfo {
  final String selector;
  final String tagName;
  final String id;
  final String className;
  final String textContent;
  final String? href;
  final String? src;
  final String outerHTML;
  final Map<String, String> attributes;
  final Map<String, String> styles;
  final List<String> parentHierarchy;
  final Map<String, double> boundingBox;

  SelectedElementInfo({
    required this.selector,
    required this.tagName,
    required this.id,
    required this.className,
    required this.textContent,
    this.href,
    this.src,
    required this.outerHTML,
    required this.attributes,
    required this.styles,
    required this.parentHierarchy,
    required this.boundingBox,
  });

  factory SelectedElementInfo.fromMap(Map<String, dynamic> map) {
    // Helper to convert dynamic map to String map
    Map<String, String> toStringMap(dynamic source) {
      if (source == null) return {};
      if (source is Map) {
        return source.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
      return {};
    }

    // Helper for double values
    Map<String, double> toDoubleMap(dynamic source) {
      if (source == null) return {};
      if (source is Map) {
        return source.map((k, v) => MapEntry(k.toString(), (v is num) ? v.toDouble() : 0.0));
      }
      return {};
    }

    return SelectedElementInfo(
      selector: map['selector']?.toString() ?? '',
      tagName: map['tagName']?.toString() ?? '',
      id: map['id']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      textContent: map['textContent']?.toString() ?? '',
      href: map['href']?.toString(),
      src: map['src']?.toString(),
      outerHTML: map['outerHTML']?.toString() ?? '',
      attributes: toStringMap(map['attributes']),
      styles: toStringMap(map['styles']),
      parentHierarchy: List<String>.from(map['parentHierarchy'] ?? []),
      boundingBox: toDoubleMap(map['boundingBox']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'selector': selector,
      'tagName': tagName,
      'id': id,
      'className': className,
      'textContent': textContent,
      'href': href,
      'src': src,
      'outerHTML': outerHTML,
      'attributes': attributes,
      'styles': styles,
      'parentHierarchy': parentHierarchy,
      'boundingBox': boundingBox,
    };
  }
}

enum ConsoleLogType { log, info, warn, error }

class ConsoleMessageLog {
  final String message;
  final ConsoleLogType type;
  final DateTime timestamp;

  ConsoleMessageLog({
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

class NetworkRequestLog {
  final String url;
  final String method;
  final String resourceType; // document, stylesheet, script, image, media, xhr, other
  final int? statusCode;
  final DateTime timestamp;
  final String? size;

  NetworkRequestLog({
    required this.url,
    required this.method,
    required this.resourceType,
    this.statusCode,
    required this.timestamp,
    this.size,
  });
}

class StorageItem {
  final String key;
  final String value;
  final String type; // 'cookie', 'localStorage', 'sessionStorage'

  StorageItem({
    required this.key,
    required this.value,
    required this.type,
  });
}

class ResourceItem {
  final String url;
  final String type; // 'script', 'stylesheet', 'image', 'media', 'document'
  final String name;

  ResourceItem({
    required this.url,
    required this.type,
    required this.name,
  });
}
