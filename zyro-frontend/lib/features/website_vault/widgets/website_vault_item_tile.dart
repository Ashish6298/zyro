import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/website_vault_item.dart';
import '../models/website_vault_type.dart';

class WebsiteVaultItemTile extends StatelessWidget {
  final WebsiteVaultItem item;
  final Future<void> Function(String title) onRename;
  final Future<void> Function(bool deleteLocalFile) onDelete;

  const WebsiteVaultItemTile({
    super.key,
    required this.item,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: Icon(_iconFor(item.type), color: theme.colorScheme.primary),
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            _subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.52),
              fontSize: 10,
              height: 1.25,
            ),
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(LucideIcons.moreVertical, size: 18),
          onSelected: (value) => _handleAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'open', child: Text('Open')),
            const PopupMenuItem(value: 'share', child: Text('Share')),
            const PopupMenuItem(value: 'rename', child: Text('Rename')),
            if (item.sourceUrl.isNotEmpty)
              const PopupMenuItem(value: 'copy', child: Text('Copy Link')),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  String get _subtitle {
    final parts = <String>[
      item.type.singularLabel,
      _formatDate(item.createdAt),
      if (item.fileSize != null) _formatBytes(item.fileSize!),
      if (item.sourceUrl.isNotEmpty) item.sourceUrl,
    ];
    return parts.join('  •  ');
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    switch (action) {
      case 'open':
        await _open(context);
        break;
      case 'share':
        await _share();
        break;
      case 'rename':
        await _rename(context);
        break;
      case 'copy':
        await Clipboard.setData(ClipboardData(text: item.sourceUrl));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vault link copied'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break;
      case 'delete':
        await _confirmDelete(context);
        break;
    }
  }

  Future<void> _open(BuildContext context) async {
    if (kDebugMode) debugPrint('[WEBSITE VAULT] Vault item opened');
    final filePath = item.filePath;
    if (filePath != null &&
        filePath.isNotEmpty &&
        await File(filePath).exists()) {
      await Share.shareXFiles([XFile(filePath)], text: item.title);
      return;
    }
    final uri = Uri.tryParse(item.sourceUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _share() async {
    final filePath = item.filePath;
    if (filePath != null &&
        filePath.isNotEmpty &&
        await File(filePath).exists()) {
      await Share.shareXFiles([XFile(filePath)], text: item.title);
      return;
    }
    await Share.share(item.sourceUrl.isNotEmpty ? item.sourceUrl : item.title);
  }

  Future<void> _rename(BuildContext context) async {
    final controller = TextEditingController(text: item.title);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename vault item'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.trim().isNotEmpty) {
      await onRename(value);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    var deleteLocalFile = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Delete vault item?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Only this vault entry will be removed. Browser data stays unchanged.',
                ),
                if ((item.filePath ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: deleteLocalFile,
                    onChanged: (value) {
                      setState(() => deleteLocalFile = value == true);
                    },
                    title: const Text('Also delete the local file'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
    if (confirmed == true) {
      await onDelete(deleteLocalFile);
    }
  }

  IconData _iconFor(WebsiteVaultType type) {
    switch (type) {
      case WebsiteVaultType.screenshot:
        return LucideIcons.image;
      case WebsiteVaultType.pdf:
        return LucideIcons.fileText;
      case WebsiteVaultType.link:
        return LucideIcons.link;
      case WebsiteVaultType.download:
        return LucideIcons.download;
      case WebsiteVaultType.note:
        return LucideIcons.stickyNote;
      case WebsiteVaultType.receipt:
        return LucideIcons.receipt;
      case WebsiteVaultType.page:
        return LucideIcons.file;
    }
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
