class Scenario {
  final int? id;
  final String name;
  final String deviceId;
  final String conditionType;
  final int conditionSensorId;
  final String? conditionSensorName;
  final double? conditionValue;
  final String actionType;
  final int actionPin;
  final bool enabled;

  Scenario({
    this.id,
    required this.name,
    required this.deviceId,
    required this.conditionType,
    required this.conditionSensorId,
    this.conditionSensorName,
    this.conditionValue,
    required this.actionType,
    required this.actionPin,
    this.enabled = true,
  });

  factory Scenario.fromJson(Map<String, dynamic> json) {
    return Scenario(
      id: json['id'],
      name: json['name'],
      deviceId: json['deviceId'],
      conditionType: json['conditionType'],
      conditionSensorId: json['conditionSensorId'],
      conditionSensorName: json['conditionSensorName'],
      conditionValue: json['conditionValue']?.toDouble(),
      actionType: json['actionType'],
      actionPin: json['actionPin'],
      enabled: json['enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'deviceId': deviceId,
      'conditionType': conditionType,
      'conditionSensorId': conditionSensorId,
      if (conditionValue != null) 'conditionValue': conditionValue,
      'actionType': actionType,
      'actionPin': actionPin,
      'enabled': enabled,
    };
  }

  Scenario copyWith({
    int? id,
    String? name,
    String? deviceId,
    String? conditionType,
    int? conditionSensorId,
    String? conditionSensorName,
    double? conditionValue,
    String? actionType,
    int? actionPin,
    bool? enabled,
  }) {
    return Scenario(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceId: deviceId ?? this.deviceId,
      conditionType: conditionType ?? this.conditionType,
      conditionSensorId: conditionSensorId ?? this.conditionSensorId,
      conditionSensorName: conditionSensorName ?? this.conditionSensorName,
      conditionValue: conditionValue ?? this.conditionValue,
      actionType: actionType ?? this.actionType,
      actionPin: actionPin ?? this.actionPin,
      enabled: enabled ?? this.enabled,
    );
  }
}

