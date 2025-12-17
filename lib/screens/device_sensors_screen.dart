import 'package:flutter/material.dart';
import '../models/sensor.dart';
import '../models/device.dart';
import '../models/sensor_data.dart';
import '../services/api_service.dart';
import 'add_sensor_screen.dart';
import 'sensor_data_screen.dart';

class DeviceSensorsScreen extends StatefulWidget {
  final ApiService apiService;
  final Device device;

  const DeviceSensorsScreen({
    super.key,
    required this.apiService,
    required this.device,
  });

  @override
  State<DeviceSensorsScreen> createState() => _DeviceSensorsScreenState();
}

class _DeviceSensorsScreenState extends State<DeviceSensorsScreen> {
  List<Sensor> _sensors = [];
  Map<int, SensorData> _sensorDataMap = {}; // Map sensorId -> SensorData
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final sensors = await widget.apiService.getSensorsByDevice(widget.device.deviceId);
      final sensorDataList = await widget.apiService.getLatestSensorDataByDevice(widget.device.deviceId);
      
      // Создаем Map для быстрого доступа к данным по sensorId
      final Map<int, SensorData> dataMap = {};
      for (var data in sensorDataList) {
        if (data.sensorId != null) {
          dataMap[data.sensorId!] = data;
        }
      }
      
      setState(() {
        _sensors = sensors;
        _sensorDataMap = dataMap;
      });
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

  Future<void> _deleteSensor(Sensor sensor) async {
    if (sensor.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить датчик?'),
        content: Text('Вы уверены, что хотите удалить датчик "${sensor.name ?? sensor.type}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.apiService.deleteSensor(sensor.id!);
        _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: $e')),
          );
        }
      }
    }
  }

  String _getSensorTypeDisplay(String type) {
    switch (type) {
      case 'DHT11':
        return 'DHT11 (Температура/Влажность)';
      case 'HC-SR501':
        return 'HC-SR501 (Датчик движения)';
      default:
        return type;
    }
  }

  Widget _buildSensorCard(Sensor sensor, SensorData? sensorData) {
    final isDHT11 = sensor.type == 'DHT11';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark
        ? const Color(0xFF404040).withOpacity(0.3)
        : Colors.grey.shade300.withOpacity(0.5);
    
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Card(
        elevation: 4,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SensorDataScreen(
                  apiService: widget.apiService,
                  sensor: sensor,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDHT11
                              ? [
                                  const Color(0xFF0d6efd),
                                  const Color(0xFF8a2be2),
                                ]
                              : [
                                  const Color(0xFF8a2be2),
                                  const Color(0xFF0d6efd),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (isDHT11
                                    ? const Color(0xFF0d6efd)
                                    : const Color(0xFF8a2be2))
                                .withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        isDHT11
                            ? Icons.thermostat
                            : Icons.motion_photos_on,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sensor.name ?? sensor.type,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getSensorTypeDisplay(sensor.type),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? const Color(0xFFb0b0b0)
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.pin,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFFb0b0b0)
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Пин: ${sensor.pin}',
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
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFCF6679),
                      ),
                      onPressed: () => _deleteSensor(sensor),
                      tooltip: 'Удалить',
                    ),
                  ],
                ),
                if (sensorData != null) ...[
                  const SizedBox(height: 12),
                  Divider(color: const Color(0xFF404040).withOpacity(0.5)),
                  const SizedBox(height: 12),
                  if (isDHT11) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: _buildDataItem(
                            Icons.wb_sunny,
                            'Температура',
                            sensorData.temperature != null
                                ? '${sensorData.temperature!.toStringAsFixed(1)} °C'
                                : 'Нет данных',
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDataItem(
                            Icons.water_drop,
                            'Влажность',
                            sensorData.humidity != null
                                ? '${sensorData.humidity!.toStringAsFixed(1)} %'
                                : 'Нет данных',
                            const Color(0xFF0d6efd),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Center(
                      child: _buildDataItem(
                        Icons.access_time,
                        'Последнее движение',
                        sensorData.getFormattedLastMotion(),
                        const Color(0xFF8a2be2),
                      ),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 12),
                  Divider(
                    color: isDark
                        ? const Color(0xFF404040).withOpacity(0.5)
                        : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Нет данных',
                      style: TextStyle(
                        fontSize: 14,
                        color: (isDark
                                ? const Color(0xFFb0b0b0)
                                : Colors.grey.shade600)
                            .withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataItem(IconData icon, String label, String value, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark
        ? const Color(0xFFb0b0b0)
        : Colors.grey.shade600;
    
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: secondaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark
        ? const Color(0xFFb0b0b0)
        : Colors.grey.shade600;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.device.name ?? 'Датчики устройства',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              widget.device.deviceId,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: secondaryColor,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _loadData,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8a2be2)),
              ),
            )
          : _sensors.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF2d2d2d)
                                        : Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF404040)
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.sensors_off,
                                    size: 64,
                                    color: isDark
                                        ? const Color(0xFFb0b0b0)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                        const SizedBox(height: 24),
                                Text(
                                  'Нет датчиков',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Добавьте датчик, нажав на кнопку ниже',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: isDark
                                        ? const Color(0xFFb0b0b0)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF8a2be2),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _sensors.length,
                    itemBuilder: (context, index) {
                      final sensor = _sensors[index];
                      final sensorData = sensor.id != null ? _sensorDataMap[sensor.id] : null;
                      return _buildSensorCard(sensor, sensorData);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddSensorScreen(
                apiService: widget.apiService,
                initialDeviceId: widget.device.deviceId, // Передаем ID текущего устройства
              ),
            ),
          );

          if (result == true) {
            _loadData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Добавить датчик'),
      ),
    );
  }
}

