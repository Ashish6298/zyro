enum PermissionType { camera, microphone, location, notifications, clipboard }

enum PermissionStatus { allow, ask, block }

extension PermissionTypeLabel on PermissionType {
  String get label => switch (this) {
    PermissionType.camera => 'Camera',
    PermissionType.microphone => 'Microphone',
    PermissionType.location => 'Location',
    PermissionType.notifications => 'Notifications',
    PermissionType.clipboard => 'Clipboard',
  };

  String get description => switch (this) {
    PermissionType.camera => 'Use your camera for calls and scanning',
    PermissionType.microphone => 'Use your microphone for calls and recording',
    PermissionType.location => 'Access your approximate or precise location',
    PermissionType.notifications => 'Send browser notifications',
    PermissionType.clipboard => 'Read or write clipboard content',
  };
}

extension PermissionStatusLabel on PermissionStatus {
  String get label => switch (this) {
    PermissionStatus.allow => 'Allow',
    PermissionStatus.ask => 'Ask Every Time',
    PermissionStatus.block => 'Block',
  };
}
