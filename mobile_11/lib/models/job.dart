class Job {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final String loginPhoto;
  final String? logoutPhoto;
  final String deviceId;
  final bool isActive;
  final List<String> locationIds;

  Job({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.loginPhoto,
    this.logoutPhoto,
    required this.deviceId,
    required this.isActive,
    required this.locationIds,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['_id'] ?? json['id'],
      userId: json['userId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      loginPhoto: json['loginPhoto'],
      logoutPhoto: json['logoutPhoto'],
      deviceId: json['deviceId'],
      isActive: json['isActive'] ?? true,
      locationIds: List<String>.from(json['locations'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'loginPhoto': loginPhoto,
      'logoutPhoto': logoutPhoto,
      'deviceId': deviceId,
      'isActive': isActive,
      'locations': locationIds,
    };
  }
}
