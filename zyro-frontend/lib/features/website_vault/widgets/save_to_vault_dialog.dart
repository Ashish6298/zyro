import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/website_vault_type.dart';

class SaveToVaultResult {
  final String title;
  final String domainOrUrl;
  final String sourceUrl;
  final WebsiteVaultType type;
  final String? noteText;

  const SaveToVaultResult({
    required this.title,
    required this.domainOrUrl,
    required this.sourceUrl,
    required this.type,
    this.noteText,
  });
}

class SaveToVaultDialog extends StatefulWidget {
  final String initialTitle;
  final String initialUrl;
  final String? fixedDomain;
  final WebsiteVaultType initialType;

  const SaveToVaultDialog({
    super.key,
    required this.initialTitle,
    required this.initialUrl,
    this.fixedDomain,
    this.initialType = WebsiteVaultType.page,
  });

  @override
  State<SaveToVaultDialog> createState() => _SaveToVaultDialogState();
}

class _SaveToVaultDialogState extends State<SaveToVaultDialog> {
  late final TextEditingController _title;
  late final TextEditingController _domainOrUrl;
  late final TextEditingController _sourceUrl;
  late final TextEditingController _note;
  late WebsiteVaultType _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle);
    _domainOrUrl = TextEditingController(
      text: widget.fixedDomain ?? widget.initialUrl,
    );
    _sourceUrl = TextEditingController(text: widget.initialUrl);
    _note = TextEditingController();
    _type = widget.initialType;
  }

  @override
  void dispose() {
    _title.dispose();
    _domainOrUrl.dispose();
    _sourceUrl.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final domainPreview = _domainPreview;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.16),
                        theme.colorScheme.tertiary.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: theme.cardColor.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          LucideIcons.archive,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Save to Website Vault',
                              style: GoogleFonts.outfit(
                                color: theme.colorScheme.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Organize this item for easy future access.',
                              style: GoogleFonts.outfit(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.58,
                                ),
                                fontSize: 12,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LocalInfoPanel(theme: theme),
                      const SizedBox(height: 16),
                      _VaultTextField(
                        controller: _title,
                        label: 'Title',
                        hint: 'Name this saved item',
                        helper: 'Used when searching your vault.',
                        icon: LucideIcons.type,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      _VaultTextField(
                        controller: _domainOrUrl,
                        enabled: widget.fixedDomain == null,
                        label: 'Domain or URL',
                        hint: 'example.com',
                        helper: 'Zyro organizes items by website.',
                        icon: LucideIcons.globe2,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      _VaultTextField(
                        controller: _sourceUrl,
                        label: 'Source URL',
                        hint: 'https://example.com/page',
                        helper: 'Open or copy the original page later.',
                        icon: LucideIcons.link,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Content type',
                        style: GoogleFonts.outfit(
                          color: theme.colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _TypeSelector(
                        selected: _type,
                        onChanged: (value) => setState(() => _type = value),
                      ),
                      const SizedBox(height: 16),
                      _VaultTextField(
                        controller: _note,
                        label: 'Notes',
                        hint: 'Add order number, context, or reminders',
                        helper: '${_note.text.length}/500 characters',
                        icon: LucideIcons.stickyNote,
                        maxLines: 5,
                        maxLength: 500,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      _SaveSummary(
                        domain: domainPreview,
                        type: _type,
                        searchable: true,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _GradientSaveButton(
                              saving: _saving,
                              onPressed: _saving ? null : _finishSave,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _domainPreview {
    final raw = _sourceUrl.text.trim().isNotEmpty
        ? _sourceUrl.text.trim()
        : _domainOrUrl.text.trim();
    final uri = Uri.tryParse(raw.startsWith('http') ? raw : 'https://$raw');
    return (uri?.host.isNotEmpty == true ? uri!.host : raw)
        .replaceFirst(RegExp(r'^www\.'), '')
        .ifEmpty('Not set');
  }

  Future<void> _finishSave() async {
    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    Navigator.pop(
      context,
      SaveToVaultResult(
        title: _title.text.trim(),
        domainOrUrl: _domainOrUrl.text.trim(),
        sourceUrl: _sourceUrl.text.trim(),
        type: _type,
        noteText: _note.text.trim().isEmpty ? null : _note.text.trim(),
      ),
    );
  }
}

class _LocalInfoPanel extends StatelessWidget {
  final ThemeData theme;

  const _LocalInfoPanel({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.shieldCheck, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Stored locally, organized automatically, and searchable by title, URL, notes, and website.',
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.66),
                fontSize: 11,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VaultTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String helper;
  final IconData icon;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  const _VaultTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.helper,
    required this.icon,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        counterText: '',
        prefixIcon: Icon(icon, size: 18),
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 2,
        filled: true,
        fillColor: theme.cardColor.withValues(alpha: 0.72),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final WebsiteVaultType selected;
  final ValueChanged<WebsiteVaultType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final types = WebsiteVaultType.values;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        return _TypeChip(
          type: type,
          selected: selected == type,
          onTap: () => onChanged(type),
        );
      }).toList(),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final WebsiteVaultType type;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedScale(
      scale: selected ? 1.03 : 1,
      duration: const Duration(milliseconds: 140),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.13)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_iconFor(type), size: 15, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                type.singularLabel,
                style: GoogleFonts.outfit(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}

class _SaveSummary extends StatelessWidget {
  final String domain;
  final WebsiteVaultType type;
  final bool searchable;

  const _SaveSummary({
    required this.domain,
    required this.type,
    required this.searchable,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Domain', value: domain),
          _SummaryRow(label: 'Content type', value: type.singularLabel),
          const _SummaryRow(label: 'Storage', value: 'Website Vault metadata'),
          _SummaryRow(label: 'Search', value: searchable ? 'Enabled' : 'Off'),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.48),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: theme.colorScheme.onSurface,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientSaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback? onPressed;

  const _GradientSaveButton({required this.saving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [theme.colorScheme.tertiary, theme.colorScheme.primary],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.26),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: saving
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      key: const ValueKey('label'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.archive,
                          color: Colors.white,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Save to Vault',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
