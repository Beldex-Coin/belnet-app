import 'package:flutter/material.dart';
//import 'log_entry.dart'; // or define in same file


class LogEntry {
  final DateTime timestamp;
  final String message;

  LogEntry(this.timestamp, this.message);
}


class LogProvider with ChangeNotifier {
  final List<LogEntry> _logs = [];

  List<LogEntry> get logs => _logs;

  void addLog(String message) {
    _logs.add(LogEntry(DateTime.now(), message));
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  String getAllLogs() {
    return _logs
        .map((log) =>
            "${log.timestamp.millisecondsSinceEpoch}: ${log.message}")
        .join('\n');
  }
}
