/// Mensaje / Notificación del sistema
class MessageModel {
  final String id;
  final String? senderId;
  final String? subject;
  final String? content;
  final bool isRead;
  final String? category; // 'Waitlist', 'Payment', 'General'
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    this.senderId,
    this.subject,
    this.content,
    this.isRead = false,
    this.category,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      senderId: json['sender_id'] as String?,
      subject: json['subject'] as String?,
      content: json['content'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'subject': subject,
      'content': content,
      'is_read': isRead,
      'category': category,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
