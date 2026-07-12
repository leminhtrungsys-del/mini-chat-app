class ChatModel {
  final String id;
  final List<String> members; // [phoneA, phoneB]
  final String lastMessagePreview;
  final DateTime lastUpdated;

  ChatModel({
    required this.id,
    required this.members,
    required this.lastMessagePreview,
    required this.lastUpdated,
  });

  factory ChatModel.fromMap(String id, Map<String, dynamic> map) => ChatModel(
        id: id,
        members: List<String>.from(map['members'] ?? []),
        lastMessagePreview: map['lastMessagePreview'] ?? '',
        lastUpdated: DateTime.tryParse(map['lastUpdated'] ?? '') ?? DateTime.now(),
      );

  String otherMember(String myPhone) =>
      members.firstWhere((m) => m != myPhone, orElse: () => '');
}
