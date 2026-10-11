class RiderApplication {
  final String id;
  final String userId;
  final String userName;
  final String vehicleType;
  final String photoUrl;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;

  RiderApplication({
    required this.id,
    required this.userId,
    required this.userName,
    required this.vehicleType,
    required this.photoUrl,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
  });

  factory RiderApplication.fromJson(Map<String, dynamic> json) {
    return RiderApplication(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Unknown',
      vehicleType: json['vehicleType'] ?? 'motorcycle',
      photoUrl: json['photoUrl'] ?? '',
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejectionReason'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class Rider {
  final String id;
  final String userId;
  final String userName;
  final String vehicleType;
  final bool isOnline;
  final double rating;
  final int totalDeliveries;
  final int totalEarnings;

  Rider({
    required this.id,
    required this.userId,
    required this.userName,
    required this.vehicleType,
    required this.isOnline,
    required this.rating,
    required this.totalDeliveries,
    required this.totalEarnings,
  });

  factory Rider.fromJson(Map<String, dynamic> json) {
    return Rider(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Unknown',
      vehicleType: json['vehicleType'] ?? 'motorcycle',
      isOnline: json['isOnline'] ?? false,
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalDeliveries: json['totalDeliveries'] ?? 0,
      totalEarnings: json['totalEarnings'] ?? 0,
    );
  }
}
