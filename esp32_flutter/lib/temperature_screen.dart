import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'services/api_service.dart';
import 'models/reading.dart';

class TemperatureScreen extends StatefulWidget {
  final BluetoothDevice device;

  const TemperatureScreen({super.key, required this.device});

  @override
  State<TemperatureScreen> createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _isSyncing = false;
  double? _currentTemperature;
  Reading? _lastSyncedReading;
  BluetoothCharacteristic? _temperatureCharacteristic;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;
  static const String serviceUuid = '12345678-1234-1234-1234-1234567890ab';
  static const String characteristicUuid = 'abcd1234-5678-1234-5678-abcdef123456';

  @override
  void initState() {
    super.initState();
    _setupConnectionListener();
    _connect();
  }

  void _setupConnectionListener() {
    _connectionSubscription = widget.device.connectionState.listen((state) {
      if (mounted) {
        setState(() {
          _isConnected = state == BluetoothConnectionState.connected;
          if (!_isConnected) {
            _temperatureCharacteristic = null;
          }
        });
      }
    });
  }

  Future<void> _connect() async {
    setState(() => _isConnecting = true);

    try {
      await widget.device.connect(timeout: const Duration(seconds: 15));
      await _discoverServices();
      await _subscribeToTemperature();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected to sensor'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _discoverServices() async {
  final services = await widget.device.discoverServices();
for (var service in services) {
  for (var char in service.characteristics) {
    if (char.uuid.toString().toLowerCase() == characteristicUuid.toLowerCase()) {
      _temperatureCharacteristic = char;
      break;
    }
  }
  if (_temperatureCharacteristic != null) break;
}

    if (mounted) setState(() {});
  }

  Future<void> _subscribeToTemperature() async {
    if (_temperatureCharacteristic == null) return;

    try {
      if (_temperatureCharacteristic!.properties.notify) {
        await _temperatureCharacteristic!.setNotifyValue(true);
        _notificationSubscription = _temperatureCharacteristic!.onValueReceived.listen((value) {
          _handleTemperatureData(value);
        });
      }

      if (_temperatureCharacteristic!.properties.read) {
        final value = await _temperatureCharacteristic!.read();
        _handleTemperatureData(value);
      }
    } catch (e) {
      print('Error subscribing to temperature: $e');
    }
  }

  void _handleTemperatureData(List<int> data) {
    if (data.isEmpty) return;
    double temperature;
    try {
      final tempString = String.fromCharCodes(data).trim();
      temperature = double.parse(tempString);
      if (mounted) {
        setState(() {
          _currentTemperature = temperature;
        });
      }
    } catch (e) {
      print('Error parsing temperature: $e');
      if (data.length >= 2) {
        final bytes = Uint8List.fromList(data);
        final byteData = ByteData.sublistView(bytes);
        temperature = byteData.getInt16(0, Endian.little) / 100.0;
        if (mounted) {
          setState(() {
            _currentTemperature = temperature;
          });
        }
      }
    }
  }

  Future<void> _readTemperature() async {
    if (_temperatureCharacteristic == null) return;

    try {
      final value = await _temperatureCharacteristic!.read();
      _handleTemperatureData(value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _syncToBackend() async {
    if (_currentTemperature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No temperature reading to sync'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSyncing = true);

    try {
      final reading = await ApiService.sendReading(
        deviceId: widget.device.remoteId.toString(),
        temperature: _currentTemperature!,
      );

      if (reading != null && mounted) {
        setState(() {
          _lastSyncedReading = reading;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synced to backend successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to sync - check backend connection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  Future<void> _fetchLatestFromBackend() async {
    final reading = await ApiService.getLatestReading(
      widget.device.remoteId.toString(),
    );

    if (reading != null && mounted) {
      setState(() {
        _lastSyncedReading = reading;
      });
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _notificationSubscription?.cancel();
    widget.device.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Temperature Sensor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isConnected ? _readTemperature : null,
            tooltip: 'Read Temperature',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _isConnected ? Colors.green : Colors.grey,
                  child: Icon(
                    _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  widget.device.platformName.isNotEmpty
                      ? widget.device.platformName
                      : 'BLE Sensor',
                ),
                subtitle: Text(
                  _isConnecting
                      ? 'Connecting...'
                      : (_isConnected ? 'Connected' : 'Disconnected'),
                ),
                trailing: _isConnecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(
                      Icons.thermostat,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentTemperature != null
                          ? '${_currentTemperature!.toStringAsFixed(1)}°C'
                          : '--.-°C',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentTemperature != null
                          ? 'Live Reading'
                          : 'Waiting for data...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_isConnected && !_isSyncing) ? _syncToBackend : null,
                icon: _isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isSyncing ? 'Syncing...' : 'Sync to Backend'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _fetchLatestFromBackend,
                icon: const Icon(Icons.cloud_download),
                label: const Text('Fetch Latest from Backend'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_lastSyncedReading != null)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cloud_done, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'Last Synced Reading',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildInfoRow('Device ID', _lastSyncedReading!.deviceId),
                      _buildInfoRow(
                        'Temperature',
                        '${_lastSyncedReading!.temperature.toStringAsFixed(1)}°C',
                      ),
                      _buildInfoRow(
                        'Timestamp',
                        _formatTimestamp(_lastSyncedReading!.timestamp),
                      ),
                    ],
                  ),
                ),
              ),
           ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
