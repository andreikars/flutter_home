import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/scenario.dart';
import '../models/device.dart';
import '../models/sensor.dart';

class AddScenarioScreen extends StatefulWidget {
  final ApiService apiService;
  final Scenario? scenario;

  const AddScenarioScreen({
    super.key,
    required this.apiService,
    this.scenario,
  });

  @override
  State<AddScenarioScreen> createState() => _AddScenarioScreenState();
}

class _AddScenarioScreenState extends State<AddScenarioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _conditionValueController = TextEditingController();

  String? _selectedDeviceId;
  String? _selectedConditionSensorId;
  String _selectedConditionType = 'MOTION_DETECTED';
  String _selectedActionType = 'TURN_ON_LED';
  String? _selectedActionPin;
  bool _enabled = true;
  bool _isLoading = false;
  bool _isLoadingDevices = true;
  bool _isLoadingSensors = false;

  List<Device> _devices = [];
  List<Sensor> _sensors = [];

  final List<String> _conditionTypes = [
    'MOTION_DETECTED',
    'TEMPERATURE_ABOVE',
    'TEMPERATURE_BELOW',
    'HUMIDITY_ABOVE',
    'HUMIDITY_BELOW',
  ];

  final List<String> _actionTypes = [
    'TURN_ON_LED',
    'TURN_OFF_LED',
  ];

  // Доступные GPIO пины для ESP8266
  static const List<Map<String, String>> _availablePins = [
    {'value': '2', 'label': 'GPIO 2 (D4) - Рекомендуется (встроенный LED на многих платах)'},
    {'value': '4', 'label': 'GPIO 4 (D2)'},
    {'value': '5', 'label': 'GPIO 5 (D1)'},
    {'value': '12', 'label': 'GPIO 12 (D6)'},
    {'value': '13', 'label': 'GPIO 13 (D7)'},
    {'value': '14', 'label': 'GPIO 14 (D5)'},
    {'value': '0', 'label': 'GPIO 0 (D3) - Не рекомендуется'},
    {'value': '15', 'label': 'GPIO 15 (D8) - Не рекомендуется'},
    {'value': '16', 'label': 'GPIO 16 (D0) - Без PWM'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDevices();
    if (widget.scenario != null) {
      _loadScenarioData();
    }
  }

  void _loadScenarioData() {
    final scenario = widget.scenario!;
    _nameController.text = scenario.name;
    _selectedDeviceId = scenario.deviceId;
    _selectedConditionType = scenario.conditionType;
    _selectedConditionSensorId = scenario.conditionSensorId.toString();
    if (scenario.conditionValue != null) {
      _conditionValueController.text = scenario.conditionValue!.toStringAsFixed(1);
    }
    _selectedActionType = scenario.actionType;
    _selectedActionPin = scenario.actionPin.toString();
    _enabled = scenario.enabled;
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
        if (_selectedDeviceId != null) {
          _loadSensors();
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

  Future<void> _loadSensors() async {
    if (_selectedDeviceId == null) return;

    setState(() => _isLoadingSensors = true);

    try {
      final sensors = await widget.apiService.getSensorsByDevice(_selectedDeviceId!);
      setState(() {
        _sensors = sensors;
        if (sensors.isNotEmpty && _selectedConditionSensorId == null) {
          _selectedConditionSensorId = sensors.first.id.toString();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки датчиков: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingSensors = false);
      }
    }
  }

  String _getConditionTypeDisplay(String type) {
    switch (type) {
      case 'MOTION_DETECTED':
        return 'Обнаружено движение';
      case 'TEMPERATURE_ABOVE':
        return 'Температура выше';
      case 'TEMPERATURE_BELOW':
        return 'Температура ниже';
      case 'HUMIDITY_ABOVE':
        return 'Влажность выше';
      case 'HUMIDITY_BELOW':
        return 'Влажность ниже';
      default:
        return type;
    }
  }

  String _getActionTypeDisplay(String type) {
    switch (type) {
      case 'TURN_ON_LED':
        return 'Включить светодиод';
      case 'TURN_OFF_LED':
        return 'Выключить светодиод';
      default:
        return type;
    }
  }

  Future<void> _saveScenario() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDeviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите устройство')),
      );
      return;
    }

    if (_selectedConditionSensorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите датчик для условия')),
      );
      return;
    }

    double? conditionValue;
    if (_selectedConditionType != 'MOTION_DETECTED') {
      if (_conditionValueController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Введите значение для условия')),
        );
        return;
      }
      conditionValue = double.tryParse(_conditionValueController.text);
      if (conditionValue == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Неверное значение условия')),
        );
        return;
      }
    }

    if (_selectedActionPin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите GPIO пин для действия')),
      );
      return;
    }

    final actionPin = int.tryParse(_selectedActionPin!);
    if (actionPin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Неверный пин для действия')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final scenario = Scenario(
        id: widget.scenario?.id,
        name: _nameController.text.trim(),
        deviceId: _selectedDeviceId!,
        conditionType: _selectedConditionType,
        conditionSensorId: int.parse(_selectedConditionSensorId!),
        conditionValue: conditionValue,
        actionType: _selectedActionType,
        actionPin: actionPin,
        enabled: _enabled,
      );

      if (widget.scenario == null) {
        await widget.apiService.createScenario(scenario);
      } else {
        await widget.apiService.updateScenario(scenario);
      }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          widget.scenario == null ? 'Добавить сценарий' : 'Редактировать сценарий',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                color: Theme.of(context).cardColor,
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF0d6efd),
                                  Color(0xFF8a2be2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Параметры сценария',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Название сценария',
                          prefixIcon: const Icon(Icons.label_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите название';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _isLoadingDevices
                          ? const Center(child: CircularProgressIndicator())
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
                                final deviceName = device.name ?? device.deviceId;
                                return DropdownMenuItem(
                                  value: device.deviceId,
                                  child: Text(deviceName),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDeviceId = value;
                                  _selectedConditionSensorId = null;
                                });
                                _loadSensors();
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
                        value: _selectedConditionType,
                        decoration: InputDecoration(
                          labelText: 'Тип условия',
                          prefixIcon: const Icon(Icons.rule),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        items: _conditionTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getConditionTypeDisplay(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedConditionType = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      _isLoadingSensors
                          ? const Center(child: CircularProgressIndicator())
                          : _sensors.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.orange.shade900.withOpacity(0.3)
                                        : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.orange.shade700
                                          : Colors.orange.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: isDark
                                            ? Colors.orange.shade400
                                            : Colors.orange.shade700,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Нет датчиков на устройстве',
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.orange.shade400
                                                : Colors.orange.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : DropdownButtonFormField<String>(
                                  value: _selectedConditionSensorId,
                                  decoration: InputDecoration(
                                    labelText: 'Датчик для условия',
                                    prefixIcon: const Icon(Icons.sensors),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                  ),
                                  items: _sensors.map((sensor) {
                                    final sensorName = sensor.name ?? sensor.type;
                                    return DropdownMenuItem(
                                      value: sensor.id.toString(),
                                      child: Text('$sensorName (${sensor.type})'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedConditionSensorId = value);
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Выберите датчик';
                                    }
                                    return null;
                                  },
                                ),
                      if (_selectedConditionType != 'MOTION_DETECTED') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _conditionValueController,
                          decoration: InputDecoration(
                            labelText: _selectedConditionType.contains('TEMPERATURE')
                                ? 'Значение температуры (°C)'
                                : 'Значение влажности (%)',
                            prefixIcon: const Icon(Icons.numbers),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (_selectedConditionType != 'MOTION_DETECTED') {
                              if (value == null || value.isEmpty) {
                                return 'Введите значение';
                              }
                              final num = double.tryParse(value);
                              if (num == null) {
                                return 'Неверное значение';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedActionType,
                        decoration: InputDecoration(
                          labelText: 'Действие',
                          prefixIcon: const Icon(Icons.play_arrow),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        items: _actionTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getActionTypeDisplay(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedActionType = value!);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedActionPin,
                        decoration: InputDecoration(
                          labelText: 'GPIO пин для действия',
                          prefixIcon: const Icon(Icons.pin),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                        ),
                        items: _availablePins.map<DropdownMenuItem<String>>((pin) {
                          final value = pin['value'] ?? '';
                          final label = pin['label'] ?? value;
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedActionPin = value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Выберите GPIO пин';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text(
                          'Включен',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        value: _enabled,
                        onChanged: (value) {
                          setState(() => _enabled = value);
                        },
                        activeColor: const Color(0xFF8a2be2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveScenario,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8a2be2),
                  foregroundColor: Colors.white,
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
    _conditionValueController.dispose();
    super.dispose();
  }
}

