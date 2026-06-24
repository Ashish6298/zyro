import 'package:flutter/material.dart';
import '../models/permission_enums.dart';

class PermissionStatusSelector extends StatelessWidget {
  final PermissionStatus value;
  final ValueChanged<PermissionStatus> onChanged;
  const PermissionStatusSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => PopupMenuButton<PermissionStatus>(
    tooltip: 'Change permission',
    onSelected: onChanged,
    itemBuilder: (_) => PermissionStatus.values
        .map(
          (status) => PopupMenuItem(value: status, child: Text(status.label)),
        )
        .toList(),
    child: Chip(
      label: Text(value.label),
      backgroundColor: switch (value) {
        PermissionStatus.allow => Colors.green.withOpacity(.14),
        PermissionStatus.ask => Theme.of(
          context,
        ).colorScheme.primary.withOpacity(.12),
        PermissionStatus.block => Colors.red.withOpacity(.12),
      },
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
