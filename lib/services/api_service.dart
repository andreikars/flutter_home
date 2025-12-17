import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor.dart';
import '../models/sensor_data.dart';
import '../models/device.dart';
import '../models/scenario.dart';

class ApiService {
  String? _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  String? get baseUrl => _baseUrl;

  Future<List<Sensor>> getSensors() async {
    if (_baseUrl == null) throw Exception('Base URL не установлен');
    
    final response = await http.get(
      Uri.parse('$_baseUrl/api/sensors'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Sensor.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка загрузки датчиков: ${response.statusCode}');
    }
  }

  Future<List<Sensor>> getSensorsByDevice(String deviceId) async {
    if (_baseUrl == null) throw Exception('Base URL не установлен');
    
    final response = await http.get(
      Uri.parse('$_baseUrl/api/sensors/device/$deviceId'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Sensor.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка загрузки датчиков: ${response.statusCode}');
    }
  }

  Future<Sensor> createSensor(Sensor sensor) async {
    if (_baseUrl == null) throw Exception('Base URL не установлен');
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/sensors'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'deviceId': sensor.deviceId,
        'pin': sensor.pin,
        'type': sensor.type,
        'name': sensor.name,
      }),
    );

    if (response.statusCode == 200) {
      return Sensor.fromJson(json.decode(response.body));
    } else {
      throw Exception('Ошибка создания датчика: ${response.statusCode}');
    }
  }

  Future<void> deleteSensor(int sensorId) async {
    if (_baseUrl == null) throw Exception('Base URL не установлен');
    
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/sensors/$sensorId'),
    );

    if (response.statusCode != 204) {
      throw Exception('Ошибка удаления датчика: ${response.statusCode}');
    }
  }

  Future<List<SensorData>> getLatestSensorDataForAll() async {
    if (_baseUrl == null) throw Exception('Base URL не установлен');
    
    final response = await http.get(
      Uri.parse('$_baseUrl/api/sensors/data/latest'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => SensorData.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка загрузки данных: ${response.statusCode}');
    }
  }

  Future<List<SensorData>> getSensorDataBySensor(int sensorId) async {
    if (_baseUrl == null) throw Exception('Base URL не установлен');
    
    final response = await http.get(
      Uri.parse('$_baseUrl/api/sensors/data/sensor/$sensorId'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => SensorData.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка загрузки данных: ${response.statusCode}');
    }
  }

  Future<List<Device>> getDevices() async {
    if (_baseUrl == null) throw Exception('Base URL не установлен');
    
    final response = await http.get(
      Uri.parse('$_baseUrl/api/devices'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Device.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка загрузки устройств: ${response.statusCode}');
    }
  }

  Future<List<SensorData>> getLatestSensorDataByDevice(String deviceId) async {
    if (_baseUrl == null) throw Exception('Base URL не установлен');
    
    final response = await http.get(
      Uri.parse('$_baseUrl/api/sensors/data/device/$deviceId/latest'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => SensorData.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка загрузки данных: ${response.statusCode}');
    }
  }

  Future<void> updateDeviceName(String deviceId, String name) async {
    if (_baseUrl == null) throw Exception('Base URL не установлен');
    
    final response = await http.put(
      Uri.parse('$_baseUrl/api/devices/$deviceId/name'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name}),
    );

    if (response.statusCode != 200) {
      throw Exception('Ошибка обновления названия: ${response.statusCode}');
    }
  }

  // Методы для работы со сценариями
  Future<List<Scenario>> getScenarios() async {
    if (_baseUrl == null) throw Exception('Base URL не установлен');
    
    final response = await http.get(
      Uri.parse('$_baseUrl/api/scenarios'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Scenario.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка загрузки сценариев: ${response.statusCode}');
    }
  }

  Future<List<Scenario>> getScenariosByDevice(String deviceId) async {
    if (_baseUrl == null) throw Exception('Base URL не установлен');
    
    final response = await http.get(
      Uri.parse('$_baseUrl/api/scenarios/device/$deviceId'),
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Scenario.fromJson(json)).toList();
    } else {
      throw Exception('Ошибка загрузки сценариев: ${response.statusCode}');
    }
  }

  Future<Scenario> createScenario(Scenario scenario) async {
    if (_baseUrl == null) throw Exception('Base URL не установлен');
    
    final response = await http.post(
      Uri.parse('$_baseUrl/api/scenarios'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(scenario.toJson()),
    );

    if (response.statusCode == 200) {
      return Scenario.fromJson(json.decode(response.body));
    } else {
      throw Exception('Ошибка создания сценария: ${response.statusCode}');
    }
  }

  Future<Scenario> updateScenario(Scenario scenario) async {
    if (_baseUrl == null) throw Exception('Base URL не установлен');
    if (scenario.id == null) throw Exception('ID сценария не указан');
    
    final response = await http.put(
      Uri.parse('$_baseUrl/api/scenarios/${scenario.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(scenario.toJson()),
    );

    if (response.statusCode == 200) {
      return Scenario.fromJson(json.decode(response.body));
    } else {
      throw Exception('Ошибка обновления сценария: ${response.statusCode}');
    }
  }

  Future<void> deleteScenario(int scenarioId) async {
    if (_baseUrl == null) throw Exception('Base URL не установлен');
    
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/scenarios/$scenarioId'),
    );

    if (response.statusCode != 204) {
      throw Exception('Ошибка удаления сценария: ${response.statusCode}');
    }
  }

  Future<Scenario> toggleScenario(int scenarioId) async {
    if (_baseUrl == null) throw Exception('Base URL не установлен');
    
    final response = await http.put(
      Uri.parse('$_baseUrl/api/scenarios/$scenarioId/toggle'),
    );

    if (response.statusCode == 200) {
      return Scenario.fromJson(json.decode(response.body));
    } else {
      throw Exception('Ошибка переключения сценария: ${response.statusCode}');
    }
  }
}

