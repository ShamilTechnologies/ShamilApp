class OperatingHours {
  final String startTime;
  final String endTime;
  final bool isAvailable;

  OperatingHours({
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
  });

  factory OperatingHours.fromMap(Map<String, dynamic> map) {
    return OperatingHours(
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      isAvailable: map['isAvailable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
    };
  }
}
