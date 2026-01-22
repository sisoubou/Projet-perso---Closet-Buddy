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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dateCreation': dateCreation.toIso8601String(),
        'occasions': occasions,
        'top': top.toJson(),
        'bottom': bottom.toJson(),
        'shoes': shoes?.toJson(),
        'accessory': accessory?.toJson(),
      };

  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      id: json['id'],
      name: json['name'],
      dateCreation: DateTime.parse(json['dateCreation']),
      occasions: json['occasions'],
      top: ClothingItem.fromJson(json['top']['id'], json['top']),
      bottom: ClothingItem.fromJson(json['bottom']['id'], json['bottom']),
      shoes: json['shoes'] != null ? ClothingItem.fromJson(json['shoes']['id'], json['shoes']) : null,
      accessory: json['accessory'] != null ? ClothingItem.fromJson(json['accessory']['id'], json['accessory']) : null,
    );
  }
}
