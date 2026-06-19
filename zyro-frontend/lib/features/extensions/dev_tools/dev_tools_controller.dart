import 'package:flutter/material.dart';
import 'dev_tools_models.dart';

class DevToolsController extends ChangeNotifier {
  final List<ConsoleMessageLog> _consoleLogs = [];
  final List<NetworkRequestLog> _networkLogs = [];
  SelectedElementInfo? _selectedElement;

  List<ConsoleMessageLog> get consoleLogs => _consoleLogs;
  List<NetworkRequestLog> get networkLogs => _networkLogs;
  SelectedElementInfo? get selectedElement => _selectedElement;

  void addConsoleLog(String message, ConsoleLogType type) {
    _consoleLogs.add(ConsoleMessageLog(
      message: message,
      type: type,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void addNetworkLog(String url, String method, String type, {int? statusCode, String? size}) {
    _networkLogs.add(NetworkRequestLog(
      url: url,
      method: method,
      resourceType: type,
      statusCode: statusCode,
      timestamp: DateTime.now(),
      size: size,
    ));
    notifyListeners();
  }

  void setSelectedElement(SelectedElementInfo? element) {
    _selectedElement = element;
    notifyListeners();
  }

  void clearConsole() {
    _consoleLogs.clear();
    notifyListeners();
  }

  void clearNetwork() {
    _networkLogs.clear();
    notifyListeners();
  }

  void clearAll() {
    _consoleLogs.clear();
    _networkLogs.clear();
    _selectedElement = null;
    notifyListeners();
  }
}
