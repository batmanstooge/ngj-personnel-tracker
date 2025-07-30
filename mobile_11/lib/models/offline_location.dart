class OfflineLocation {
  final int? id;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? placeName;
  final String? address;
  final double? accuracy;
  final bool isSynced;

  OfflineLocation({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.placeName,
    this.address,
    this.accuracy,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'placeName': placeName,
      'address': address,
      'accuracy': accuracy,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory OfflineLocation.fromMap(Map<String, dynamic> map) {
    return OfflineLocation(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      placeName: map['placeName'],
      address: map['address'],
      accuracy: map['accuracy'],
      isSynced: map['isSynced'] == 1,
    );
  }
}