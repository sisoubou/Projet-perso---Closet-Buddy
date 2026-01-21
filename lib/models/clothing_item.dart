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
        'userId': userId,
        'name': name,
        'mainCategory': mainCategory,
        'subCategory': subCategory,
        'imageUrl': imageUrl,
        'color': color,
        'occasion': occasion,
        'season': season
      };

      
factory ClothingItem.fromJson(String id, Map<String, dynamic> json) {
    return ClothingItem(
      id: id,
      userId: json['userId'] as String,
      name: json['name'] as String,
      mainCategory: json['mainCategory'] as String,
      subCategory: json['subCategory'] as String,
      imageUrl: json['imageUrl'] as String,
      color: (json['color'] ?? '') as String,
      occasion: (json['occasion'] ?? 'casual') as String,
      season: (json['season'] ?? 'Toutes saisons') as String,
    );
  }
}
