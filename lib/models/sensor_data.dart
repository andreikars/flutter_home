class SensorData {
  final int? id;
  final int? sensorId;
  final String? sensorName;
  final String? sensorType;
  final int? timestamp;
  final double? temperature;
  final double? humidity;
  final int? lastMotionTime;
  final bool? motionDetected;
  final DateTime? createdAt;

  SensorData({
    this.id,
    this.sensorId,
    this.sensorName,
    this.sensorType,
    this.timestamp,
    this.temperature,
    this.humidity,
    this.lastMotionTime,
    this.motionDetected,
    this.createdAt,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      id: json['id'],
      sensorId: json['sensorId'],
      sensorName: json['sensorName'],
      sensorType: json['sensorType'],
      timestamp: json['timestamp'],
      temperature: json['temperature']?.toDouble(),
      humidity: json['humidity']?.toDouble(),
      lastMotionTime: json['lastMotionTime'],
      motionDetected: json['motionDetected'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  String getFormattedLastMotion() {
    // Используем lastMotionTime, который теперь содержит правильное время в миллисекундах
    if (lastMotionTime == null || lastMotionTime == 0) return 'Нет данных';
    
    final motionTime = DateTime.fromMillisecondsSinceEpoch(lastMotionTime!);
    final now = DateTime.now();
    final diff = now.difference(motionTime);
    
    if (diff.isNegative) return 'Нет данных'; // Если время в будущем
    
    final seconds = diff.inSeconds;
    if (seconds < 60) return '$seconds сек назад';
    if (seconds < 3600) return '${seconds ~/ 60} мин назад';
    return '${diff.inHours} ч назад';
  }
}

