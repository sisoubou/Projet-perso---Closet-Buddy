class ClothingItem {
  final String id;
  final String userId;
  final String name;
  final String category; 
  final String imageUrl; 
  final String color;
  final String occasion;

  ClothingItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.imageUrl,
    this.color = '',
    this.occasion = 'casual',
  });

  ClothingItem copyWith({
    String? userId,
    String? name,
    String? category,
    String? imageUrl,
    String? color,
    String? occasion,
  }) {
    return ClothingItem(
      id: id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      color: color ?? this.color,
      occasion: occasion ?? this.occasion,
    );
  }

  ClothingItem modify({
    String? userId,
    String? name,
    String? category,
    String? imageUrl,
    String? color,
    String? occasion,
  }) {
    return copyWith(
      userId: userId,
      name: name,
      category: category,
      imageUrl: imageUrl,
      color: color,
      occasion: occasion,
    );
  }

  
Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'category': category,
        'imageUrl': imageUrl,
        'color': color,
        'occasion': occasion,
      };

      
factory ClothingItem.fromJson(String id, Map<String, dynamic> json) {
    return ClothingItem(
      id: id,
      userId: json['userId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String,
      color: (json['color'] ?? '') as String,
      occasion: (json['occasion'] ?? 'casual') as String,
    );
  }
}
