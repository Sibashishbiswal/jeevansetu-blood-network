class AuditLog {
  final String id;
  final String title;
  final String details;
  final DateTime timestamp;
  final String type; // 'created', 'accepted', 'transit', 'arrival', 'fulfilled', 'cancelled'
  final String? ticketId;

  AuditLog({
    required this.id,
    required this.title,
    required this.details,
    required this.timestamp,
    required this.type,
    this.ticketId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'details': details,
    'timestamp': timestamp.toIso8601String(),
    'type': type,
    'ticketId': ticketId,
  };

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
    id: json['id'] as String,
    title: json['title'] as String,
    details: json['details'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    type: json['type'] as String,
    ticketId: json['ticketId'] as String?,
  );
}
