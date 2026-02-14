class ClothingItem {
  final String id;
  final String userId;
  final String name;
  final String mainCategory;
  final String subCategory;
  final String imageUrl;
  final List<String> colors;
  final List<String> occasions;
  final String season;

  ClothingItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.mainCategory,
    required this.subCategory,
    required this.imageUrl,
    this.colors = const [],
    this.occasions = const ['casual'],
    this.season = 'Toutes saisons',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'mainCategory': mainCategory,
        'subCategory': subCategory,
        'imageUrl': imageUrl,
        'colors': colors,
        'occasions': occasions,
        'season': season,
      };

  factory ClothingItem.fromJson(String id, dynamic json) {
    Map<String, dynamic> safeMap(dynamic data) {
      if (data is Map) {
        return Map<String, dynamic>.from(data.map((key, value) => MapEntry(key.toString(), value)));
      }
      return {};
    }
    
    final data = safeMap(json);

    List<String> parseList(dynamic value, String oldSingleKey) {
      if (value is List) {
        return List<String>.from(value);
      }
      if (data[oldSingleKey] is String && data[oldSingleKey].isNotEmpty) {
        return [data[oldSingleKey]];
      }
      return [];
    }
    
    return ClothingItem(
      id: id,
      userId: (data['userId'] ?? '') as String,
      name: (data['name'] ?? 'Sans nom') as String,
      mainCategory: (data['mainCategory'] ?? '') as String,
      subCategory: (data['subCategory'] ?? '') as String,
      imageUrl: (data['imageUrl'] ?? '') as String,
      colors: parseList(data['colors'], 'color'),
      occasions: parseList(data['occasions'], 'occasion'),
      season: (data['season'] ?? 'Toutes saisons') as String,
    );
  }

  ClothingItem copyWith({
    String? userId,
    String? name,
    String? mainCategory,
    String? subCategory,
    String? imageUrl,
    List<String>? colors,
    List<String>? occasions,
    String? season,
  }) {
    return ClothingItem(
      id: id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      mainCategory: mainCategory ?? this.mainCategory,
      subCategory: subCategory ?? this.subCategory,
      imageUrl: imageUrl ?? this.imageUrl,
      colors: colors ?? this.colors,
      occasions: occasions ?? this.occasions,
      season: season ?? this.season,
    );
  }
}