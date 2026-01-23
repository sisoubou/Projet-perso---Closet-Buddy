class ClothingItem {
  final String id;
  final String userId;
  final String name;
  final String mainCategory;
  final String subCategory;
  final String imageUrl;
  final String color;
  final String occasion;
  final String season;

  ClothingItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.mainCategory,
    required this.subCategory,
    required this.imageUrl,
    this.color = '',
    this.occasion = 'casual',
    this.season = 'Toutes saisons',
  });

  ClothingItem copyWith({
    String? userId,
    String? name,
    String? mainCategory,
    String? subCategory,
    String? imageUrl,
    String? color,
    String? occasion,
    String? season,
  }) {
    return ClothingItem(
      id: id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      mainCategory: mainCategory ?? this.mainCategory,
      subCategory: subCategory ?? this.subCategory,
      imageUrl: imageUrl ?? this.imageUrl,
      color: color ?? this.color,
      occasion: occasion ?? this.occasion,
      season: season ?? this.season,
    );
  }

  ClothingItem modify({
    String? userId,
    String? name,
    String? mainCategory,
    String? subCategory,
    String? imageUrl,
    String? color,
    String? occasion,
    String? season,
  }) {
    return copyWith(
      userId: userId,
      name: name,
      mainCategory: mainCategory,
      subCategory: subCategory,
      imageUrl: imageUrl,
      color: color,
      occasion: occasion,
      season: season,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id, 
        'userId': userId,
        'name': name,
        'mainCategory': mainCategory,
        'subCategory': subCategory,
        'imageUrl': imageUrl,
        'color': color,
        'occasion': occasion,
        'season': season
      };

  factory ClothingItem.fromJson(String id, dynamic json) {
    Map<String, dynamic> safeMap(dynamic data) {
      if (data is Map) {
        return Map<String, dynamic>.from(data.map((key, value) => MapEntry(key.toString(), value)));
      }
      return {};
    }
    
    final data = safeMap(json);
    
    return ClothingItem(
      id: id,
      userId: (data['userId'] ?? '') as String,
      name: (data['name'] ?? 'Sans nom') as String,
      mainCategory: (data['mainCategory'] ?? '') as String,
      subCategory: (data['subCategory'] ?? '') as String,
      imageUrl: (data['imageUrl'] ?? '') as String,
      color: (data['color'] ?? '') as String,
      occasion: (data['occasion'] ?? 'casual') as String,
      season: (data['season'] ?? 'Toutes saisons') as String,
    );
  }
}