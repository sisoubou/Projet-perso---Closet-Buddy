import 'clothing_item.dart';

class Outfit {
  final String id;
  final String name;
  final DateTime dateCreation;
  final String? occasions;
  final ClothingItem top;
  final ClothingItem bottom;
  final ClothingItem? shoes;
  final ClothingItem? accessory;

  Outfit({
    required this.id,
    required this.name,
    required this.dateCreation,
    required this.top,
    required this.bottom,
    this.occasions,
    this.shoes,
    this.accessory,
  });

  Outfit copyWith({
    String? name,
    ClothingItem? top,
    ClothingItem? bottom,
    ClothingItem? shoes,
    ClothingItem? accessory,
    String? occasions,
  }) {
    return Outfit(
      id: id,
      name: name ?? this.name,
      top: top ?? this.top,
      bottom: bottom ?? this.bottom,
      shoes: shoes ?? this.shoes,
      accessory: accessory ?? this.accessory,
      dateCreation: dateCreation,
      occasions: occasions ?? this.occasions,
    );
  }

  Outfit modify({
    String? name,
    ClothingItem? top,
    ClothingItem? bottom,
    ClothingItem? shoes,
    ClothingItem? accessory,
    String? occasions,
  }) {
    return copyWith(
      name: name,
      top: top,
      bottom: bottom,
      shoes: shoes,
      accessory: accessory,
      occasions: occasions,
    );
  }
}
