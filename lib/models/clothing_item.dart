class ClothingItem {
  final String id;
  final String name;
  final String category; 
  final String imageUrl; 
  final String color;
  final String occasion;

  ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    this.color = '',
    this.occasion = 'casual',
  });

  ClothingItem copyWith({
    String? name,
    String? category,
    String? imageUrl,
    String? color,
    String? occasion,
  }) {
    return ClothingItem(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      color: color ?? this.color,
      occasion: occasion ?? this.occasion,
    );
  }

  ClothingItem modify({
    String? name,
    String? category,
    String? imageUrl,
    String? color,
    String? occasion,
  }) {
    return copyWith(
      name: name,
      category: category,
      imageUrl: imageUrl,
      color: color,
      occasion: occasion,
    );
  }


}
