class Device {
  final String deviceId;
  final String deviceType;
  final DateTime? lastActivity;
  final bool online;
  final int sensorCount;
  final String? ipAddress;
  final String? name;

  Device({
    required this.deviceId,
    required this.deviceType,
    this.lastActivity,
    required this.online,
    required this.sensorCount,
    this.ipAddress,
    this.name,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      deviceId: json['deviceId'],
      deviceType: json['deviceType'],
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'])
          : null,
      online: json['online'] ?? false,
      sensorCount: json['sensorCount'] ?? 0,
      ipAddress: json['ipAddress'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceType': deviceType,
      if (lastActivity != null) 'lastActivity': lastActivity!.toIso8601String(),
      'online': online,
      'sensorCount': sensorCount,
      if (ipAddress != null) 'ipAddress': ipAddress,
      if (name != null) 'name': name,
    };
  }
}

