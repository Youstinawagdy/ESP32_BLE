class Reading {
  final String deviceId;
  final double temperature;
  final DateTime timestamp;

  Reading({
    required this.deviceId,
    required this.temperature,
    required this.timestamp,
  });

  factory Reading.fromJson(Map<String, dynamic> json) {
    return Reading(
      deviceId: json['deviceId'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'temperature': temperature,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
