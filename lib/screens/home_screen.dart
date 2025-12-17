import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/device.dart';
import 'settings_screen.dart';
import 'device_sensors_screen.dart';
import 'all_sensors_screen.dart';

class HomeScreen extends StatefulWidget {
  final ApiService apiService;

  const HomeScreen({super.key, required this.apiService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storageService = StorageService();
  List<Device> _devices = [];
  bool _isLoading = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final url = await _storageService.getBackendUrl();
    if (url != null && url.isNotEmpty) {
      widget.apiService.setBaseUrl(url);
      _loadDevices();
    }
  }

  Future<void> _loadDevices() async {
    if (widget.apiService.baseUrl == null) return;

    setState(() => _isLoading = true);

    try {
      final devices = await widget.apiService.getDevices();
      setState(() => _devices = devices);
    } catch (e) {
      // Игнорируем ошибки в фоновом режиме
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDeviceCard(Device device) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = device.online
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
                builder: (context) => DeviceSensorsScreen(
                  apiService: widget.apiService,
                  device: device,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: device.online
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF0d6efd),
                                  Color(0xFF8a2be2),
                                ],
                              )
                            : null,
                        color: device.online ? null : const Color(0xFF404040),
                        shape: BoxShape.circle,
                        boxShadow: device.online
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
                        Icons.router,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name ?? device.deviceId,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: device.online
                                  ? const Color(0xFF8a2be2).withOpacity(0.2)
                                  : const Color(0xFF2d2d2d),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: device.online
                                    ? const Color(0xFF8a2be2)
                                    : const Color(0xFF404040),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: device.online
                                        ? const Color(0xFF8a2be2)
                                        : const Color(0xFFb0b0b0),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  device.online ? 'Онлайн' : 'Оффлайн',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: device.online
                                        ? const Color(0xFF8a2be2)
                                        : const Color(0xFFb0b0b0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFFb0b0b0),
                      ),
                      onPressed: () => _editDeviceName(device),
                      tooltip: 'Изменить название',
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFFb0b0b0),
                    ),
                  ],
                ),
                  const SizedBox(height: 16),
                  Divider(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF404040).withOpacity(0.5)
                        : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                _buildDeviceInfoRow(
                  Icons.fingerprint,
                  'MAC адрес',
                  device.deviceId,
                ),
                if (device.ipAddress != null) ...[
                  const SizedBox(height: 8),
                  _buildDeviceInfoRow(
                    Icons.language,
                    'IP адрес',
                    device.ipAddress!,
                  ),
                ],
                const SizedBox(height: 8),
                _buildDeviceInfoRow(
                  Icons.sensors,
                  'Датчиков',
                  '${device.sensorCount}',
                ),
                if (device.lastActivity != null) ...[
                  const SizedBox(height: 8),
                  _buildDeviceInfoRow(
                    Icons.access_time,
                    'Последняя активность',
                    _formatLastActivity(device.lastActivity!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceInfoRow(IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark 
        ? const Color(0xFFb0b0b0)
        : Colors.grey.shade600;
    final textColor = Theme.of(context).colorScheme.onSurface;
    
    return Row(
      children: [
        Icon(icon, size: 16, color: secondaryColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: secondaryColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatLastActivity(DateTime lastActivity) {
    final now = DateTime.now();
    final diff = now.difference(lastActivity);
    
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} сек назад';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} мин назад';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ч назад';
    } else {
      return '${diff.inDays} дн назад';
    }
  }

  Future<void> _editDeviceName(Device device) async {
    final controller = TextEditingController(text: device.name ?? '');
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        title: Text(
          'Изменить название',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Название устройства',
            labelStyle: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFb0b0b0)
                  : Colors.grey.shade600,
            ),
            hintText: 'Введите название',
            hintStyle: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF404040)
                  : Colors.grey.shade400,
            ),
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.pop(context, value.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFb0b0b0)
                    : Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, controller.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8a2be2),
            ),
            child: const Text(
              'Сохранить',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result != null && result != device.name) {
      try {
        await widget.apiService.updateDeviceName(device.deviceId, result);
        if (mounted) {
          _loadDevices();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Название обновлено')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      }
    }
  }

  Widget _buildHomeContent() {
    return widget.apiService.baseUrl == null
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
                      'Настройте приложение',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Укажите URL бэкенда для начала работы',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFFb0b0b0)
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsScreen(
                              apiService: widget.apiService,
                            ),
                          ),
                        );
                        _initialize();
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Перейти в настройки'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8a2be2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDevices,
              color: const Color(0xFF8a2be2),
              child: _isLoading && _devices.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8a2be2)),
                      ),
                    )
                  : _devices.isEmpty
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
                                    Icons.router_outlined,
                                    size: 64,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFFb0b0b0)
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Нет устройств',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Подключите ESP8266 устройства.\nОни автоматически появятся здесь после подключения.',
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
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          children: [
                            ..._devices.map((device) => _buildDeviceCard(device)),
                          ],
                        ),
            );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final dividerColor = isDark 
        ? const Color(0xFF404040).withOpacity(0.3)
        : Colors.grey.shade300.withOpacity(0.5);
    
    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: _selectedIndex == 0
          ? AppBar(
              elevation: 0,
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              title: Row(
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
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8a2be2).withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.home, size: 24, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Умный дом',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.settings, color: textColor),
                  tooltip: 'Настройки',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(
                          apiService: widget.apiService,
                        ),
                      ),
                    );
                    _initialize();
                  },
                ),
              ],
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeContent(),
          AllSensorsScreen(apiService: widget.apiService),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
            top: BorderSide(color: dividerColor),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: cardColor,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF8a2be2),
          unselectedItemColor: isDark 
              ? const Color(0xFFb0b0b0)
              : Colors.grey.shade600,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Главная',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sensors_outlined),
              activeIcon: Icon(Icons.sensors),
              label: 'Все датчики',
            ),
          ],
        ),
      ),
    );
  }
}

