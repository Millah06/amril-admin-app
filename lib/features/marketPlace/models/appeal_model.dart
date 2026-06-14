/// An appealed order returned by GET /admin/order/appeals.
/// Contains the order + its escrow details.
class AppealOrder {
  const AppealOrder({
    required this.id,
    required this.userId,
    required this.vendorId,
    required this.vendorName,
    required this.vendorLogo,
    required this.totalAmount,
    required this.status,
    required this.escrowStatus,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.escrow,
    this.deliveryArea = '',
    this.deliveryLga = '',
    this.deliveryState = '',
  });

  final String id;
  final String userId;
  final String vendorId;
  final String vendorName;
  final String vendorLogo;
  final double totalAmount;
  final String status;
  final String escrowStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<AppealOrderItem> items;
  final AppealEscrow? escrow;
  final String deliveryArea;
  final String deliveryLga;
  final String deliveryState;

  /// How long the appeal has been open
  String get openDuration {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  factory AppealOrder.fromJson(Map<String, dynamic> json) {
    final escrowJson = json['escrow'] as Map<String, dynamic>?;
    final itemsList = json['items'] as List<dynamic>? ?? [];

    return AppealOrder(
      id: json['id'] as String,
      userId: json['userId'] as String,
      vendorId: json['vendorId'] as String,
      vendorName: json['vendorName'] as String? ?? '',
      vendorLogo: json['vendorLogo'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'] as String,
      escrowStatus: json['escrowStatus'] as String? ?? 'held',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      items: itemsList
          .map((e) => AppealOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      escrow: escrowJson != null ? AppealEscrow.fromJson(escrowJson) : null,
      deliveryArea: json['deliveryArea'] as String? ?? '',
      deliveryLga: json['deliveryLga'] as String? ?? '',
      deliveryState: json['deliveryState'] as String? ?? '',
    );
  }
}

class AppealOrderItem {
  const AppealOrderItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  final String name;
  final double price;
  final int quantity;

  factory AppealOrderItem.fromJson(Map<String, dynamic> json) => AppealOrderItem(
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    quantity: (json['quantity'] as num).toInt(),
  );
}

class AppealEscrow {
  const AppealEscrow({
    required this.id,
    required this.amountHeld,
    required this.commission,
    required this.releaseStatus,
    required this.autoReleaseAt,
    this.appealReason,
  });

  final String id;
  final double amountHeld;
  final double commission;
  final String releaseStatus;
  final DateTime autoReleaseAt;
  final String? appealReason;

  factory AppealEscrow.fromJson(Map<String, dynamic> json) => AppealEscrow(
    id: json['id'] as String,
    amountHeld: (json['amountHeld'] as num).toDouble(),
    commission: (json['commission'] as num).toDouble(),
    releaseStatus: json['releaseStatus'] as String,
    autoReleaseAt: DateTime.parse(json['autoReleaseAt'] as String),
    appealReason: json['appealReason'] as String?,
  );
}

/// A single chat message from Firestore orderChats/{orderId}/messages
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.isAdmin,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final bool isAdmin;
  final DateTime createdAt;

  /// Whether this message was sent by the marketplace admin
  bool get isFromAdmin => isAdmin || senderId == 'admin';

  factory ChatMessage.fromFirestore(String docId, Map<String, dynamic> data) {
    // Firestore timestamps come as Timestamp objects
    DateTime ts;
    final raw = data['createdAt'];
    if (raw == null) {
      ts = DateTime.now();
    } else if (raw is DateTime) {
      ts = raw;
    } else {
      // Firestore Timestamp has .toDate()
      try {
        ts = (raw as dynamic).toDate() as DateTime;
      } catch (_) {
        ts = DateTime.now();
      }
    }

    return ChatMessage(
      id: docId,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'User',
      message: data['message'] as String? ?? '',
      isAdmin: data['isAdmin'] as bool? ?? false,
      createdAt: ts,
    );
  }
}