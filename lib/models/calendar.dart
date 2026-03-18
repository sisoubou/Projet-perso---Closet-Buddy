class Calendar {
  final String id;
  final String userId;
  final DateTime date;
  final String outfitId;
  

  Calendar({
    required this.id,
    required this.userId,
    required this.date,
    required this.outfitId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'date': date.toIso8601String(),
        'outfitId': outfitId,
      };

  factory Calendar.fromJson(dynamic json) {
    if (json is! Map) {
      throw Exception("Format invalide");
    }
    return Calendar(
      id: json['id'] ?? 'unknown',
      userId: json['userId'] ?? 'unknown',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      outfitId: json['outfitId'] ?? 'unknown',
    );
  }
}