class Sensor {
  final int? id;
  final String deviceId;
  final int pin;
  final String type;
  final String? name;

  Sensor({
    this.id,
    required this.deviceId,
    required this.pin,
    required this.type,
    this.name,
  });

  factory Sensor.fromJson(Map<String, dynamic> json) {
    return Sensor(
      id: json['id'],
      deviceId: json['deviceId'],
      pin: json['pin'],
      type: json['type'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'deviceId': deviceId,
      'pin': pin,
      'type': type,
      if (name != null) 'name': name,
    };
  }
}

