import 'package:flutter/material.dart';

/// Global scaffold messenger key — allows non-widget code (controllers, services)
/// to show SnackBar notifications without needing a BuildContext.
final GlobalKey<ScaffoldMessengerState> globalScaffoldKey =
    GlobalKey<ScaffoldMessengerState>();
