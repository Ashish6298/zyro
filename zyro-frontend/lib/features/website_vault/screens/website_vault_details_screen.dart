import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../controllers/website_vault_controller.dart';
import '../models/website_vault_item.dart';
import '../models/website_vault_type.dart';
import '../widgets/save_to_vault_dialog.dart';
import '../widgets/vault_empty_state.dart';
import '../widgets/website_vault_item_tile.dart';
import '../widgets/website_vault_type_filter_chips.dart';

class WebsiteVaultDetailsScreen extends StatefulWidget {
  final String domain;

  const WebsiteVaultDetailsScreen({super.key, required this.domain});

  @override
  State<WebsiteVaultDetailsScreen> createState() =>
      _WebsiteVaultDetailsScreenState();
}

class _WebsiteVaultDetailsScreenState extends State<WebsiteVaultDetailsScreen> {
  final _search = TextEditingController();
  WebsiteVaultType? _selectedType;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.domain,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Add note or link',
            icon: const Icon(LucideIcons.plus),
            onPressed: () => _addManual(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') _confirmClearDomain(context);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear', child: Text('Clear domain vault')),
            ],
          ),
        ],
      ),
      body: Consumer<WebsiteVaultController>(
        builder: (context, vault, child) {
          final items = vault.itemsForDomain(
            widget.domain,
            query: _search.text,
            type: _selectedType,
          );
          final grouped = _groupByType(items);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: [
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  hintText: 'Search saved items',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              WebsiteVaultTypeFilterChips(
                selected: _selectedType,
                onChanged: (value) => setState(() => _selectedType = value),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const SizedBox(
                  height: 320,
                  child: VaultEmptyState(
                    message: 'No saved items for this website yet.',
                  ),
                )
              else
                ...grouped.entries.expand((entry) {
                  return [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(
                        entry.key.label,
                        style: GoogleFonts.outfit(
                          color: theme.colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                    ...entry.value.map(
                      (item) => WebsiteVaultItemTile(
                        item: item,
                        onRename: (title) => context
                            .read<WebsiteVaultController>()
                            .renameItem(item.id, title),
                        onDelete: (deleteLocalFile) =>
                            context.read<WebsiteVaultController>().deleteItem(
                              item.id,
                              deleteLocalFile: deleteLocalFile,
                            ),
                      ),
                    ),
                  ];
                }),
            ],
          );
        },
      ),
    );
  }

  Map<WebsiteVaultType, List<WebsiteVaultItem>> _groupByType(
    List<WebsiteVaultItem> items,
  ) {
    final grouped = <WebsiteVaultType, List<WebsiteVaultItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.type, () => []).add(item);
    }
    return grouped;
  }

  Future<void> _addManual(BuildContext context) async {
    final result = await showDialog<SaveToVaultResult>(
      context: context,
      builder: (_) => SaveToVaultDialog(
        initialTitle: '',
        initialUrl: 'https://${widget.domain}',
        fixedDomain: widget.domain,
        initialType: WebsiteVaultType.note,
      ),
    );
    if (result == null || !context.mounted) return;
    await context.read<WebsiteVaultController>().addManualItem(
      domainOrUrl: widget.domain,
      title: result.title,
      type: result.type,
      sourceUrl: result.sourceUrl,
      noteText: result.noteText,
    );
  }

  Future<void> _confirmClearDomain(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Clear ${widget.domain} vault?'),
        content: const Text(
          'Only Website Vault entries for this domain will be removed. Browser history, bookmarks, downloads, screenshots, and files stay unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<WebsiteVaultController>().clearDomain(widget.domain);
    }
  }
}
