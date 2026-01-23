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

  factory Outfit.fromJson(dynamic json) {
    if (json is! Map) {
      throw Exception("Format de données invalide pour la tenue");
    }
    
    Map<String, dynamic> safeMap(dynamic v) {
      if (v is Map) {
        return Map<String, dynamic>.from(v.map((key, value) => MapEntry(key.toString(), value)));
      }
      return {};
    }
    
    final data = safeMap(json);

    String safeId(dynamic v) => (v is Map && v['id'] != null) ? v['id'].toString() : 'unknown';

    return Outfit(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Sans nom',
      dateCreation: data['dateCreation'] != null 
          ? DateTime.parse(data['dateCreation']) 
          : DateTime.now(),
      occasions: data['occasions']?.toString(),
      
      top: ClothingItem.fromJson(
        safeId(data['top']), 
        safeMap(data['top'])
      ),
      
      bottom: ClothingItem.fromJson(
        safeId(data['bottom']), 
        safeMap(data['bottom'])
      ),
      
      shoes: data['shoes'] != null 
          ? ClothingItem.fromJson(safeId(data['shoes']), safeMap(data['shoes']))
          : null,
          
      accessory: data['accessory'] != null 
          ? ClothingItem.fromJson(safeId(data['accessory']), safeMap(data['accessory']))
          : null,
    );
  }
}