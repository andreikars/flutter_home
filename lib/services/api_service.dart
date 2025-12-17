import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor.dart';
import '../models/sensor_data.dart';
import '../models/device.dart';

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
}

