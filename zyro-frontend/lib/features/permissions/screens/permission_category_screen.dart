import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/website_permissions_controller.dart';
import '../models/permission_enums.dart';
import '../models/website_permission_rule.dart';
import '../widgets/permission_site_tile.dart';
import '../widgets/permission_status_selector.dart';

class PermissionCategoryScreen extends StatelessWidget {
  final PermissionType type;
  const PermissionCategoryScreen({super.key, required this.type});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        type.label.toUpperCase(),
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w900,
          letterSpacing: 1.4,
        ),
      ),
    ),
    body: Consumer<WebsitePermissionsController>(
      builder: (context, controller, _) {
        final rules = controller.rulesFor(type);
        if (rules.isEmpty)
          return Center(
            child: Text(
              'No websites configured',
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.55),
              ),
            ),
          );
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: rules.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withOpacity(.3),
          ),
          itemBuilder: (_, index) {
            final rule = rules[index];
            return PermissionSiteTile(
              rule: rule,
              onUpdated: controller.upsert,
              onTap: () => _showDetails(context, rule),
            );
          },
        );
      },
    ),
  );

  void _showDetails(BuildContext context, WebsitePermissionRule selected) {
    final controller = context.read<WebsitePermissionsController>();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selected.domain,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Site permission details',
              style: GoogleFonts.outfit(
                color: Theme.of(
                  sheetContext,
                ).colorScheme.onSurface.withOpacity(.55),
              ),
            ),
            const SizedBox(height: 14),
            for (final permission in PermissionType.values)
              _detailRow(sheetContext, controller, selected, permission),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    WebsitePermissionsController controller,
    WebsitePermissionRule selected,
    PermissionType type,
  ) {
    final rule = controller.ruleFor(selected.domain, type);
    final status = rule?.status ?? PermissionStatus.ask;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        type.label,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
      ),
      trailing: PermissionStatusSelector(
        value: status,
        onChanged: (next) {
          final now = DateTime.now();
          controller.upsert(
            rule?.copyWith(status: next, lastUpdatedAt: now) ??
                WebsitePermissionRule(
                  id: '${selected.domain}:${type.name}',
                  domain: selected.domain,
                  origin: selected.origin,
                  permissionType: type,
                  status: next,
                  lastRequestedAt: now,
                  lastUpdatedAt: now,
                  source: 'settings',
                ),
          );
        },
      ),
    );
  }
}
