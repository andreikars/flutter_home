import 'package:flutter/material.dart';
import '../models/sensor.dart';
import '../models/sensor_data.dart';
import '../models/device.dart';
import '../services/api_service.dart';
import 'sensor_data_screen.dart';

class AllSensorsScreen extends StatefulWidget {
  final ApiService apiService;

  const AllSensorsScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<AllSensorsScreen> createState() => _AllSensorsScreenState();
}

class _AllSensorsScreenState extends State<AllSensorsScreen> {
  List<Sensor> _sensors = [];
  Map<int, SensorData> _sensorDataMap = {}; // Map sensorId -> SensorData
  Map<String, Device> _devicesMap = {}; // Map deviceId -> Device
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.apiService.baseUrl == null) return;

    setState(() => _isLoading = true);

    try {
      // Загружаем все датчики
      final sensors = await widget.apiService.getSensors();
      
      // Загружаем последние данные для всех датчиков
      final sensorDataList = await widget.apiService.getLatestSensorDataForAll();
      
      // Загружаем все устройства для отображения названий
      final devices = await widget.apiService.getDevices();
      final Map<String, Device> devicesMap = {};
      for (var device in devices) {
        devicesMap[device.deviceId] = device;
      }
      
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
        _devicesMap = devicesMap;
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

  String _getDeviceName(String deviceId) {
    final device = _devicesMap[deviceId];
    return device?.name ?? deviceId;
  }

  Widget _buildSensorCard(Sensor sensor, SensorData? sensorData) {
    final isDHT11 = sensor.type == 'DHT11';
    final deviceName = _getDeviceName(sensor.deviceId);
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
                                Icons.router,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFFb0b0b0)
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  deviceName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? const Color(0xFFb0b0b0)
                                        : Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
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
                  ],
                ),
                if (sensorData != null) ...[
                  const SizedBox(height: 12),
                  Divider(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF404040).withOpacity(0.5)
                        : Colors.grey.shade300,
                  ),
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Все датчики',
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
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: widget.apiService.baseUrl == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF0d6efd),
                            Color(0xFF8a2be2),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8a2be2).withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.settings,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Настройте подключение',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Укажите URL бэкенда в настройках',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
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
              child: _isLoading && _sensors.isEmpty
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
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFF2d2d2d)
                                        : Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? const Color(0xFF404040)
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.sensors_off,
                                    size: 64,
                                    color: Theme.of(context).brightness == Brightness.dark
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
                                  'Добавьте датчики через устройства',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFFb0b0b0)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _sensors.length,
                          itemBuilder: (context, index) {
                            final sensor = _sensors[index];
                            final sensorData = sensor.id != null
                                ? _sensorDataMap[sensor.id]
                                : null;
                            return _buildSensorCard(sensor, sensorData);
                          },
                        ),
            ),
    );
  }
}

