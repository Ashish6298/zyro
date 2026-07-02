enum WebsiteVaultType { screenshot, pdf, link, download, note, receipt, page }

extension WebsiteVaultTypeLabel on WebsiteVaultType {
  String get key => name;

  String get label {
    switch (this) {
      case WebsiteVaultType.screenshot:
        return 'Screenshots';
      case WebsiteVaultType.pdf:
        return 'PDFs';
      case WebsiteVaultType.link:
        return 'Links';
      case WebsiteVaultType.download:
        return 'Downloads';
      case WebsiteVaultType.note:
        return 'Notes';
      case WebsiteVaultType.receipt:
        return 'Receipts';
      case WebsiteVaultType.page:
        return 'Pages';
    }
  }

  String get singularLabel {
    switch (this) {
      case WebsiteVaultType.screenshot:
        return 'Screenshot';
      case WebsiteVaultType.pdf:
        return 'PDF';
      case WebsiteVaultType.link:
        return 'Link';
      case WebsiteVaultType.download:
        return 'Download';
      case WebsiteVaultType.note:
        return 'Note';
      case WebsiteVaultType.receipt:
        return 'Receipt/Invoice';
      case WebsiteVaultType.page:
        return 'Page';
    }
  }

  static WebsiteVaultType fromKey(String? value) {
    return WebsiteVaultType.values.firstWhere(
      (type) => type.key == value,
      orElse: () => WebsiteVaultType.link,
    );
  }
}
