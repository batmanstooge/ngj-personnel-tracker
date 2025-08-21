class Location {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? placeName;
  final String? address;
  final double? accuracy;
  final bool isStationary;

  Location({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.placeName,
    this.address,
    this.accuracy,
    this.isStationary = false,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['_id'] ?? json['id'],
      userId: json['userId'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      placeName: json['placeName'],
      address: json['address'],
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      isStationary: json['isStationary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'placeName': placeName,
      'address': address,
      'accuracy': accuracy,
    };
  }
}