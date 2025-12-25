import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'temperature_screen.dart';

class DeviceDetailScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  bool _isConnecting = false;
  bool _isConnected = false;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _connectionSubscription =
        widget.device.connectionState.listen((state) {
      if (!mounted) return;
      setState(() {
        _isConnected = state == BluetoothConnectionState.connected;
      });
    });
  }

  Future<void> _connect() async {
    setState(() => _isConnecting = true);

    try {
      await widget.device.connect(
        timeout: const Duration(seconds: 10),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connected successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      await widget.device.disconnect();
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disconnected'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.device.platformName.isNotEmpty
              ? widget.device.platformName
              : 'Device Details',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      _isConnected ? Colors.green : Colors.grey,
                  child: const Icon(Icons.bluetooth, color: Colors.white),
                ),
                title: Text(
                  widget.device.platformName.isNotEmpty
                      ? widget.device.platformName
                      : 'Unknown Device',
                ),
                subtitle: Text(widget.device.remoteId.toString()),
                trailing: Text(
                  _isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color:
                        _isConnected ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConnecting
                    ? null
                    : (_isConnected ? _disconnect : _connect),
                child: _isConnecting
                    ? const CircularProgressIndicator()
                    : Text(
                        _isConnected ? 'Disconnect' : 'Connect',
                      ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.thermostat),
                label: const Text('Open Temperature Monitor'),
                onPressed: _isConnected
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TemperatureScreen(
                              device: widget.device,
                            ),
                          ),
                        );
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
