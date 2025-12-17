import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/scenario.dart';
import '../models/device.dart';
import 'add_scenario_screen.dart';

class ScenariosScreen extends StatefulWidget {
  final ApiService apiService;

  const ScenariosScreen({super.key, required this.apiService});

  @override
  State<ScenariosScreen> createState() => _ScenariosScreenState();
}

class _ScenariosScreenState extends State<ScenariosScreen> {
  List<Scenario> _scenarios = [];
  List<Device> _devices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final scenarios = await widget.apiService.getScenarios();
      final devices = await widget.apiService.getDevices();
      setState(() {
        _scenarios = scenarios;
        _devices = devices;
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

  String _getDeviceName(String deviceId) {
    final device = _devices.firstWhere(
      (d) => d.deviceId == deviceId,
      orElse: () => Device(
        deviceId: deviceId,
        deviceType: '',
        online: false,
        sensorCount: 0,
      ),
    );
    return device.name ?? deviceId;
  }

  String _getConditionDisplay(Scenario scenario) {
    switch (scenario.conditionType) {
      case 'MOTION_DETECTED':
        return 'Обнаружено движение';
      case 'TEMPERATURE_ABOVE':
        return 'Температура > ${scenario.conditionValue?.toStringAsFixed(1)}°C';
      case 'TEMPERATURE_BELOW':
        return 'Температура < ${scenario.conditionValue?.toStringAsFixed(1)}°C';
      case 'HUMIDITY_ABOVE':
        return 'Влажность > ${scenario.conditionValue?.toStringAsFixed(1)}%';
      case 'HUMIDITY_BELOW':
        return 'Влажность < ${scenario.conditionValue?.toStringAsFixed(1)}%';
      default:
        return scenario.conditionType;
    }
  }

  String _getActionDisplay(Scenario scenario) {
    switch (scenario.actionType) {
      case 'TURN_ON_LED':
        return 'Включить светодиод (GPIO${scenario.actionPin})';
      case 'TURN_OFF_LED':
        return 'Выключить светодиод (GPIO${scenario.actionPin})';
      default:
        return scenario.actionType;
    }
  }

  Future<void> _toggleScenario(Scenario scenario) async {
    if (scenario.id == null) return;

    try {
      await widget.apiService.toggleScenario(scenario.id!);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _deleteScenario(Scenario scenario) async {
    if (scenario.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        title: Text(
          'Удалить сценарий?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Вы уверены, что хотите удалить сценарий "${scenario.name}"?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFb0b0b0)
                    : Colors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.apiService.deleteScenario(scenario.id!);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Сценарии',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8a2be2)),
              ),
            )
          : _scenarios.isEmpty
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
                            Icons.auto_awesome_outlined,
                            size: 64,
                            color: isDark
                                ? const Color(0xFFb0b0b0)
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Нет сценариев',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Создайте сценарий для автоматизации',
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
                    padding: const EdgeInsets.all(16),
                    itemCount: _scenarios.length,
                    itemBuilder: (context, index) {
                      final scenario = _scenarios[index];
                      return _buildScenarioCard(scenario);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddScenarioScreen(
                apiService: widget.apiService,
              ),
            ),
          );

          if (result == true) {
            _loadData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Добавить сценарий'),
      ),
    );
  }

  Widget _buildScenarioCard(Scenario scenario) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = scenario.enabled
        ? const Color(0xFF8a2be2).withOpacity(0.3)
        : (isDark
            ? const Color(0xFF404040).withOpacity(0.3)
            : Colors.grey.shade300.withOpacity(0.5));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      scenario.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Switch(
                    value: scenario.enabled,
                    onChanged: (value) => _toggleScenario(scenario),
                    activeColor: const Color(0xFF8a2be2),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.devices,
                    size: 16,
                    color: isDark
                        ? const Color(0xFFb0b0b0)
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getDeviceName(scenario.deviceId),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFb0b0b0)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.rule,
                    size: 16,
                    color: isDark
                        ? const Color(0xFFb0b0b0)
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Если: ${_getConditionDisplay(scenario)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.play_arrow,
                    size: 16,
                    color: const Color(0xFF8a2be2),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'То: ${_getActionDisplay(scenario)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8a2be2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddScenarioScreen(
                            apiService: widget.apiService,
                            scenario: scenario,
                          ),
                        ),
                      );

                      if (result == true) {
                        _loadData();
                      }
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Редактировать'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF8a2be2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _deleteScenario(scenario),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Удалить'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

