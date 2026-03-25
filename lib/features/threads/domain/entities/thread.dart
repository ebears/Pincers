class Thread {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? sessionId;

  const Thread({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.sessionId,
  });
}
