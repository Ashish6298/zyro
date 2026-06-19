import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../globals.dart';

class ExtensionNotificationService {
  static void showToggleNotification(String name, String id, bool isEnabled) {
    String message = '';
    if (isEnabled) {
      if (id == 'dev_tools') {
        message = 'Dev Tools enabled — Inspect option is now available in the context menu.';
      } else if (id == 'ad_blocker_downloader') {
        message = 'Ad Blocker & Downloader enabled — ads will be blocked and video tools are available.';
      } else if (id == 'dark_mode') {
        message = 'Dark Reader enabled — High-contrast dark mode applied to websites.';
      } else if (id == 'password_gen') {
        message = 'KeyGen enabled — Password manager and generator is active.';
      } else {
        message = '$name enabled.';
      }
    } else {
      if (id == 'dev_tools') {
        message = 'Dev Tools disabled — Inspect option has been removed from the context menu.';
      } else if (id == 'ad_blocker_downloader') {
        message = 'Ad Blocker & Downloader disabled — ads and video tools are inactive.';
      } else if (id == 'dark_mode') {
        message = 'Dark Reader disabled — Standard website theme restored.';
      } else if (id == 'password_gen') {
        message = 'KeyGen disabled — Password manager is inactive.';
      } else {
        message = '$name disabled.';
      }
    }

    _showSnackbar(message, isEnabled ? Colors.teal : Colors.blueGrey);
  }

  static void showRemoveNotification(String name) {
    _showSnackbar('$name removed — moved back to Available extensions.', Colors.redAccent);
  }

  static void _showSnackbar(String message, Color color) {
    globalScaffoldKey.currentState?.clearSnackBars();
    globalScaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
