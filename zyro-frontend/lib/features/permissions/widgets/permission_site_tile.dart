import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/permission_enums.dart';
import '../models/website_permission_rule.dart';
import 'permission_status_selector.dart';

class PermissionSiteTile extends StatelessWidget {
  final WebsitePermissionRule rule;
  final ValueChanged<WebsitePermissionRule> onUpdated;
  final VoidCallback onTap;
  const PermissionSiteTile({
    super.key,
    required this.rule,
    required this.onUpdated,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withOpacity(.1),
        child: Text(
          rule.domain.isEmpty ? '?' : rule.domain[0].toUpperCase(),
          style: GoogleFonts.outfit(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        rule.domain,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${rule.permissionType.label} · Updated ${_date(rule.lastUpdatedAt)}',
        style: GoogleFonts.outfit(fontSize: 11),
      ),
      trailing: PermissionStatusSelector(
        value: rule.status,
        onChanged: (status) => onUpdated(
          rule.copyWith(status: status, lastUpdatedAt: DateTime.now()),
        ),
      ),
    );
  }

  String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
