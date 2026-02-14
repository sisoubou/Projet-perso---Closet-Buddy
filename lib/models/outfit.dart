import 'clothing_item.dart';

class Outfit {
  final String id;
  final String name;
  final DateTime dateCreation;
  final String? occasions;
  final List<ClothingItem> items;

  Outfit({
    required this.id,
    required this.name,
    required this.dateCreation,
    required this.items,
    this.occasions,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dateCreation': dateCreation.toIso8601String(),
        'occasions': occasions,
        'items': items.map((item) => item.toJson()).toList(),
      };

  factory Outfit.fromJson(dynamic json) {
    if (json is! Map) {
      throw Exception("Format invalide");
    }
    
    Map<String, dynamic> safeMap(dynamic v) {
      if (v is Map) return Map<String, dynamic>.from(v.map((k, v) => MapEntry(k.toString(), v)));
      return {};
    }
    
    final data = safeMap(json);
    List<ClothingItem> itemsList = [];   

    if (data['items'] is List) {
      itemsList = (data['items'] as List).map((i) {
        String id = (i is Map && i['id'] != null) ? i['id'] : 'unknown'; 
        return ClothingItem.fromJson(id, i);
      }).toList();
    }
    else {
      String safeId(dynamic v) => (v is Map && v['id'] != null) ? v['id'].toString() : 'unknown';
      if (data['top'] != null) {
        itemsList.add(ClothingItem.fromJson(safeId(data['top']), safeMap(data['top'])));
      }
      if (data['bottom'] != null) {
        itemsList.add(ClothingItem.fromJson(safeId(data['bottom']), safeMap(data['bottom'])));
      }
      if (data['shoes'] != null) {
        itemsList.add(ClothingItem.fromJson(safeId(data['shoes']), safeMap(data['shoes'])));
      }
      if (data['accessory'] != null) {
        itemsList.add(ClothingItem.fromJson(safeId(data['accessory']), safeMap(data['accessory'])));
      }
    }

    return Outfit(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Sans nom',
      dateCreation: data['dateCreation'] != null 
          ? DateTime.parse(data['dateCreation']) 
          : DateTime.now(),
      occasions: data['occasions']?.toString(),
      items: itemsList,
    );
  }
}