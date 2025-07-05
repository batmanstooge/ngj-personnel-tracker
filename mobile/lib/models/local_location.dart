// Data model for local storage
class LocalLocation {
  final int? id; // Primary key, auto-incremented by SQLite
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocalLocation({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  // Convert a LocalLocation object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(), // Store as ISO string
    };
  }

  // Convert a Map object into a LocalLocation object
  factory LocalLocation.fromMap(Map<String, dynamic> map) {
    return LocalLocation(
      id: map['id'] as int?,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}