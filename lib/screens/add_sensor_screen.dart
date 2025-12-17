import 'package:flutter/material.dart';
import '../models/sensor.dart';
import '../models/device.dart';
import '../services/api_service.dart';

class AddSensorScreen extends StatefulWidget {
  final ApiService apiService;

  const AddSensorScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<AddSensorScreen> createState() => _AddSensorScreenState();
}

class _AddSensorScreenState extends State<AddSensorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedDeviceId;
  String? _selectedPin;
  String _selectedType = 'DHT11';
  bool _isLoading = false;
  bool _isLoadingDevices = true;
  List<Device> _devices = [];

  final List<String> _sensorTypes = ['DHT11', 'HC-SR501'];
  
  // Маппинг пинов ESP8266: D1-D8 -> GPIO
  final Map<String, int> _pinMapping = {
    'D1': 5,
    'D2': 4,
    'D3': 0,
    'D4': 2,
    'D5': 14,
    'D6': 12,
    'D7': 13,
    'D8': 15,
  };
  
  List<String> get _availablePins => _pinMapping.keys.toList();

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoadingDevices = true);

    try {
      final devices = await widget.apiService.getDevices();
      setState(() {
        _devices = devices;
        if (devices.isNotEmpty && _selectedDeviceId == null) {
          _selectedDeviceId = devices.first.deviceId;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки устройств: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDevices = false);
      }
    }
  }

  Future<void> _saveSensor() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDeviceId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выберите устройство')),
        );
      }
      return;
    }

    if (_selectedPin == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выберите пин')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pin = _pinMapping[_selectedPin]!;
      
      final sensor = Sensor(
        deviceId: _selectedDeviceId!,
        pin: pin,
        type: _selectedType,
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
      );

      await widget.apiService.createSensor(sensor);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить датчик'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.sensors,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Параметры датчика',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Тип датчика',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        items: _sensorTypes.map((type) {
                          String displayName;
                          IconData icon;
                          switch (type) {
                            case 'DHT11':
                              displayName = 'DHT11 (Температура/Влажность)';
                              icon = Icons.thermostat;
                              break;
                            case 'HC-SR501':
                              displayName = 'HC-SR501 (Датчик движения)';
                              icon = Icons.motion_photos_on;
                              break;
                            default:
                              displayName = type;
                              icon = Icons.sensors;
                          }
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 20),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    displayName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _isLoadingDevices
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _devices.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Нет зарегистрированных устройств. Устройство автоматически зарегистрируется при первом подключении.',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : DropdownButtonFormField<String>(
                                  value: _selectedDeviceId,
                                  decoration: InputDecoration(
                                    labelText: 'Устройство',
                                    prefixIcon: const Icon(Icons.devices),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                  ),
                                  items: _devices.map((device) {
                                    return DropdownMenuItem(
                                      value: device.deviceId,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.router,
                                            size: 20,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 12),
                                          Flexible(
                                            child: Text(
                                              '${device.deviceId} (${device.deviceType})',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedDeviceId = value);
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Выберите устройство';
                                    }
                                    return null;
                                  },
                                ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedPin,
                        decoration: InputDecoration(
                          labelText: 'Пин',
                          prefixIcon: const Icon(Icons.pin),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        items: _availablePins.map((pin) {
                          final gpio = _pinMapping[pin]!;
                          return DropdownMenuItem(
                            value: pin,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.memory,
                                  size: 18,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    '$pin (GPIO$gpio)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedPin = value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Выберите пин';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Название (необязательно)',
                          hintText: 'Датчик в гостиной',
                          prefixIcon: const Icon(Icons.label_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isLoading ? null : _saveSensor,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Сохранение...' : 'Сохранить'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

