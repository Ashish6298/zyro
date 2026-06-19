import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/tab_manager.dart';
import '../../core/browser_data_manager.dart';
import '../../core/models/link_metadata.dart';
import '../../core/extension_manager.dart';
import '../../features/extensions/dev_tools/dev_tools_extension.dart';

class LinkContextMenuPopup extends StatelessWidget {
  final LinkMetadata metadata;
  final bool isIncognitoContext;

  const LinkContextMenuPopup({
    super.key,
    required this.metadata,
    this.isIncognitoContext = false,
  });

  void _showNotification(BuildContext context, String message, ThemeData theme) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tabManager = Provider.of<TabManager>(context, listen: false);
    final dataManager = Provider.of<BrowserDataManager>(context, listen: false);

    final isImage = metadata.type == LinkType.image;
    final isVideo = metadata.type == LinkType.video;
    final isEmail = metadata.type == LinkType.email;
    final isPhone = metadata.type == LinkType.phone;
    final isPdf = metadata.type == LinkType.pdf;

    // Build actions list based on category
    final List<Widget> actions = [];

    if (isEmail) {
      actions.addAll([
        _buildActionItem(
          theme,
          icon: LucideIcons.mail,
          title: 'Compose Email',
          onTap: () async {
            final uri = Uri.parse(metadata.url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
            Navigator.pop(context);
          },
        ),
        _buildActionItem(
          theme,
          icon: LucideIcons.copy,
          title: 'Copy Email Address',
          onTap: () {
            final email = metadata.url.replaceAll('mailto:', '');
            Clipboard.setData(ClipboardData(text: email));
            _showNotification(context, 'Email address copied', theme);
            Navigator.pop(context);
          },
        ),
      ]);
    } else if (isPhone) {
      actions.addAll([
        _buildActionItem(
          theme,
          icon: LucideIcons.phoneCall,
          title: 'Call Number',
          onTap: () async {
            final uri = Uri.parse(metadata.url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            }
            Navigator.pop(context);
          },
        ),
        _buildActionItem(
          theme,
          icon: LucideIcons.copy,
          title: 'Copy Number',
          onTap: () {
            final number = metadata.url.replaceAll('tel:', '');
            Clipboard.setData(ClipboardData(text: number));
            _showNotification(context, 'Phone number copied', theme);
            Navigator.pop(context);
          },
        ),
      ]);
    } else if (isImage && metadata.imageSrcIfInsideLink == null) {
      // Truly image-only context menu
      actions.addAll([
        _buildActionItem(
          theme,
          icon: LucideIcons.externalLink,
          title: 'Open Image in New Tab',
          onTap: () {
            tabManager.addNewTab(url: metadata.url, isIncognito: isIncognitoContext);
            Navigator.pop(context);
          },
        ),
        _buildActionItem(
          theme,
          icon: LucideIcons.download,
          title: 'Download Image',
          onTap: () {
            dataManager.addDownload(
              metadata.url,
              title: 'Image Download',
            );
            Navigator.pop(context);
          },
        ),
        _buildActionItem(
          theme,
          icon: LucideIcons.copy,
          title: 'Copy Image Address',
          onTap: () {
            Clipboard.setData(ClipboardData(text: metadata.url));
            _showNotification(context, 'Image address copied', theme);
            Navigator.pop(context);
          },
        ),
        _buildActionItem(
          theme,
          icon: LucideIcons.share,
          title: 'Share Image',
          onTap: () {
            Share.share(metadata.url);
            Navigator.pop(context);
          },
        ),
      ]);
    } else {
      // Standard hyperlink, or image inside hyperlink (which gets link context)
      actions.addAll([
        _buildActionItem(
          theme,
          icon: LucideIcons.plus,
          title: 'Open in new tab',
          onTap: () {
            tabManager.addNewTab(url: metadata.url, isIncognito: isIncognitoContext);
            Navigator.pop(context);
          },
        ),
        _buildActionItem(
          theme,
          icon: LucideIcons.folderPlus,
          title: 'Open in new tab group',
          onTap: () {
            final newTab = tabManager.openInTabGroup(url: metadata.url, isIncognito: isIncognitoContext);
            _showNotification(context, 'Opened in group: ${newTab.groupName}', theme);
            Navigator.pop(context);
          },
        ),
        _buildActionItem(
          theme,
          icon: LucideIcons.eyeOff,
          title: 'Open in Incognito tab',
          onTap: () {
            tabManager.addNewTab(url: metadata.url, isIncognito: true);
            _showNotification(context, 'Opened in Incognito tab', theme);
            Navigator.pop(context);
          },
        ),
        _buildActionItem(
          theme,
          icon: LucideIcons.externalLink,
          title: 'Open in new window',
          onTap: () {
            tabManager.addNewTab(url: metadata.url, isIncognito: isIncognitoContext);
            Navigator.pop(context);
          },
        ),
        _buildActionItem(
          theme,
          icon: LucideIcons.eye,
          title: 'Preview page',
          onTap: () {
            Navigator.pop(context);
            _showPreviewDialog(context, theme);
          },
        ),
        if (Provider.of<ExtensionManager>(context, listen: false).isExtensionEnabled('dev_tools'))
          _buildActionItem(
            theme,
            icon: LucideIcons.code,
            title: 'Inspect',
            onTap: () {
              Navigator.pop(context);
              final controller = tabManager.currentTab?.controller;
              if (controller != null) {
                DevToolsExtension.showPanel(context, controller);
              }
            },
          ),
        _buildActionItem(
          theme,
          icon: LucideIcons.copy,
          title: 'Copy link address',
          onTap: () {
            Clipboard.setData(ClipboardData(text: metadata.url));
            _showNotification(context, 'Link copied to clipboard', theme);
            Navigator.pop(context);
          },
        ),
        _buildActionItem(
          theme,
          icon: LucideIcons.type,
          title: 'Copy link text',
          onTap: () {
            Clipboard.setData(ClipboardData(text: metadata.title.isNotEmpty ? metadata.title : metadata.url));
            _showNotification(context, 'Text copied to clipboard', theme);
            Navigator.pop(context);
          },
        ),
        _buildActionItem(
          theme,
          icon: LucideIcons.download,
          title: 'Download link',
          onTap: () {
            dataManager.addDownload(
              metadata.url,
              title: metadata.title.isNotEmpty ? metadata.title : 'Download File',
            );
            Navigator.pop(context);
          },
        ),
        _buildActionItem(
          theme,
          icon: LucideIcons.bookOpen,
          title: 'Add to reading list',
          onTap: () {
            dataManager.addToReadingList(metadata.url, metadata.title.isNotEmpty ? metadata.title : 'Reading Item');
            _showNotification(context, 'Added to Reading List', theme);
            Navigator.pop(context);
          },
        ),
        _buildActionItem(
          theme,
          icon: LucideIcons.share2,
          title: 'Share link',
          onTap: () {
            Share.share(metadata.url, subject: metadata.title);
            Navigator.pop(context);
          },
        ),
      ]);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final popupWidth = screenWidth * 0.85;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: popupWidth,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: theme.dividerColor.withOpacity(isDark ? 0.1 : 0.2),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Compact Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.02),
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor.withOpacity(isDark ? 0.08 : 0.15),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            isImage
                                ? LucideIcons.image
                                : isVideo
                                    ? LucideIcons.video
                                    : isEmail
                                        ? LucideIcons.mail
                                        : isPhone
                                            ? LucideIcons.phone
                                            : isPdf
                                                ? LucideIcons.fileText
                                                : LucideIcons.link,
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              metadata.title.isNotEmpty ? metadata.title : 'Link Options',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              metadata.url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical Actions List
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: actions,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              size: 18,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface.withOpacity(0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPreviewDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Page Preview',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metadata.title.isNotEmpty ? metadata.title : 'Untitled Page',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                metadata.url,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 11),
              ),
              const SizedBox(height: 16),
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.globe, size: 36, color: theme.colorScheme.primary.withOpacity(0.3)),
                      const SizedBox(height: 10),
                      Text(
                        'Secure Sandbox Preview',
                        style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Offline loading simulated...',
                        style: GoogleFonts.outfit(fontSize: 9, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Dismiss',
                style: GoogleFonts.outfit(color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Provider.of<TabManager>(context, listen: false).addNewTab(url: metadata.url);
              },
              child: Text(
                'Open Page',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
