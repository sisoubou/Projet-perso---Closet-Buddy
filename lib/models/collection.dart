class OutfitCollection {
  final String id;
  final String userId;
  final String name;
  final String description;
  final List<String> outfitIds;

  OutfitCollection({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    this.outfitIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'description': description,
        'outfitIds': outfitIds,
      };

  factory OutfitCollection.fromJson(String id, dynamic json) {
    Map<String, dynamic> safeMap(dynamic data) {
      if (data is Map) {
        return Map<String, dynamic>.from(data.map((key, value) => MapEntry(key.toString(), value)));
      }
      return {};
    }
    
    final data = safeMap(json);

    return OutfitCollection(
      id: id,
      userId: (data['userId'] ?? '') as String,
      name: (data['name'] ?? 'Nouvelle Collection') as String,
      description: (data['description'] ?? '') as String,
      outfitIds: data['outfitIds'] is List 
          ? List<String>.from(data['outfitIds']) 
          : [],
    );
  }
}