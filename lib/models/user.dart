import 'clothing_item.dart';
import 'outfit.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final List<ClothingItem> wardrobe;
  final List<Outfit> outfits;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.wardrobe = const [],
    this.outfits = const[],
  });

  void addClothing(ClothingItem item) {
    wardrobe.add(item);
  }

  void createOutfit({
    required String outfitId,
    required String name,
    required ClothingItem top,
    required ClothingItem bottom,
    ClothingItem? shoes,
    ClothingItem? accessory,
    String occasions = 'casual',
  }) {
    final newOutfit = Outfit(
      id: outfitId,
      name: name,
      top: top,
      bottom: bottom,
      shoes: shoes,
      accessory: accessory,
      dateCreation: DateTime.now(),
      occasions: occasions,
    );
    outfits.add(newOutfit);
  }

  void saveOutfit(Outfit outfit) {
    final index = outfits.indexWhere((o) => o.id == outfit.id);
    if (index != -1) {
      outfits[index] = outfit;
    } else {
      outfits.add(outfit);
    }
  }

  void updateClothing(ClothingItem updatedItem) {
    final index = wardrobe.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      wardrobe[index] = updatedItem;
    }
  }

  void deleteClothing(String itemId) {
    wardrobe.removeWhere((item) => item.id == itemId);
  } 

  void deleteOutfit(String outfitId) {
    outfits.removeWhere((outfit) => outfit.id == outfitId);
  }
}
