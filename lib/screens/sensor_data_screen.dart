import 'package:flutter/material.dart';
import '../models/sensor.dart';
import '../models/sensor_data.dart';
import '../services/api_service.dart';

class SensorDataScreen extends StatefulWidget {
  final ApiService apiService;
  final Sensor sensor;

  const SensorDataScreen({
    super.key,
    required this.apiService,
    required this.sensor,
  });

  @override
  State<SensorDataScreen> createState() => _SensorDataScreenState();
}

class _SensorDataScreenState extends State<SensorDataScreen> {
  List<SensorData> _sensorData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      if (widget.sensor.id != null) {
        final data = await widget.apiService.getSensorDataBySensor(
          widget.sensor.id!,
        );
        setState(() => _sensorData = data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDataCard(SensorData data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark
        ? const Color(0xFF404040).withOpacity(0.3)
        : Colors.grey.shade300.withOpacity(0.5);
    
    if (widget.sensor.type == 'DHT11') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 4,
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0d6efd).withOpacity(0.1),
                  const Color(0xFF8a2be2).withOpacity(0.1),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0d6efd),
                              Color(0xFF8a2be2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8a2be2).withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.thermostat,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.sensor.name ?? 'DHT11',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.wb_sunny,
                          'Температура',
                          data.temperature != null
                              ? '${data.temperature!.toStringAsFixed(1)} °C'
                              : 'Нет данных',
                          Colors.orange,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 60,
                        color: isDark
                            ? const Color(0xFF404040).withOpacity(0.5)
                            : Colors.grey.shade300,
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.water_drop,
                          'Влажность',
                          data.humidity != null
                              ? '${data.humidity!.toStringAsFixed(1)} %'
                              : 'Нет данных',
                          const Color(0xFF0d6efd),
                        ),
                      ),
                    ],
                  ),
                  if (data.createdAt != null) ...[
                    const SizedBox(height: 16),
                    Divider(
                      color: isDark
                          ? const Color(0xFF404040).withOpacity(0.5)
                          : Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: isDark
                              ? const Color(0xFFb0b0b0)
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Обновлено: ${_formatDateTime(data.createdAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFFb0b0b0)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    } else if (widget.sensor.type == 'HC-SR501') {
      final hasMotion = data.lastMotionTime != null && data.lastMotionTime! > 0;
      final motionBorderColor = hasMotion
          ? const Color(0xFF8a2be2).withOpacity(0.3)
          : (isDark
              ? const Color(0xFF404040).withOpacity(0.3)
              : Colors.grey.shade300.withOpacity(0.5));
      
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Card(
          elevation: 4,
          color: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: motionBorderColor,
              width: 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: hasMotion
                    ? [
                        const Color(0xFF8a2be2).withOpacity(0.1),
                        const Color(0xFF0d6efd).withOpacity(0.1),
                      ]
                    : [
                        const Color(0xFF2d2d2d).withOpacity(0.5),
                        const Color(0xFF1e1e1e).withOpacity(0.5),
                      ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: hasMotion
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF8a2be2),
                                    Color(0xFF0d6efd),
                                  ],
                                )
                              : null,
                          color: hasMotion ? null : const Color(0xFF404040),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: hasMotion
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF8a2be2).withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: const Icon(
                          Icons.motion_photos_on,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.sensor.name ?? 'HC-SR501',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: _buildInfoItem(
                      Icons.access_time,
                      'Последнее движение',
                      data.getFormattedLastMotion(),
                      hasMotion ? const Color(0xFF8a2be2) : const Color(0xFFb0b0b0),
                    ),
                  ),
                  if (data.motionDetected != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: data.motionDetected!
                            ? const Color(0xFF8a2be2).withOpacity(0.2)
                            : (isDark
                                ? const Color(0xFF2d2d2d)
                                : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: data.motionDetected!
                              ? const Color(0xFF8a2be2)
                              : (isDark
                                  ? const Color(0xFF404040)
                                  : Colors.grey.shade300),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            data.motionDetected!
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: data.motionDetected!
                                ? const Color(0xFF8a2be2)
                                : (isDark
                                    ? const Color(0xFFb0b0b0)
                                    : Colors.grey.shade600),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            data.motionDetected!
                                ? 'Движение обнаружено'
                                : 'Движения нет',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: data.motionDetected!
                                  ? const Color(0xFF8a2be2)
                                  : (isDark
                                      ? const Color(0xFFb0b0b0)
                                      : Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (data.createdAt != null) ...[
                    const SizedBox(height: 16),
                    Divider(
                      color: isDark
                          ? const Color(0xFF404040).withOpacity(0.5)
                          : Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: isDark
                              ? const Color(0xFFb0b0b0)
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Обновлено: ${_formatDateTime(data.createdAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFFb0b0b0)
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark
        ? const Color(0xFFb0b0b0)
        : Colors.grey.shade600;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(icon, size: 36, color: color),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: secondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} '
        '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          widget.sensor.name ?? widget.sensor.type,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading && _sensorData.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8a2be2)),
              ),
            )
          : _sensorData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sensors_off,
                        size: 64,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFb0b0b0)
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет данных',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Данные появятся, когда устройство начнет отправлять их',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFb0b0b0)
                              : Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF8a2be2),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (_sensorData.isNotEmpty) _buildDataCard(_sensorData.first),
                      if (_sensorData.length > 1) ...[
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.history,
                                color: Color(0xFF8a2be2),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'История данных',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._sensorData.skip(1).map((data) => _buildDataCard(data)),
                      ],
                    ],
                  ),
                ),
    );
  }
}

