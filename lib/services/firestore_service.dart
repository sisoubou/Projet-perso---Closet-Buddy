import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/clothing_item.dart';

class FirestoreService {
  final CollectionReference clothingCollection =
      FirebaseFirestore.instance.collection('clothing_items');

  Future<void> addClothingItem(ClothingItem item, String userId)async{
    await clothingCollection.add({
      'id': item.id,
      'name': item.name,
      'mainCategory': item.mainCategory,
      'subCategory': item.subCategory,
      'color': item.color,
      'season': item.season,
      'occasion': item.occasion,
      'imageUrl': item.imageUrl,
      'userId': userId,
    });
  }

  Future<void> updateClothingItem(ClothingItem item) async {
    final snapshot = await clothingCollection.where('id', isEqualTo: item.id).get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({
        'name': item.name,
        'mainCategory': item.mainCategory,
        'subCategory': item.subCategory,
        'color': item.color,
        'season': item.season,
        'occasion': item.occasion,
        'imageUrl': item.imageUrl,
      });
    }
  }

  Future<void> deleteClothing(String id) async {
    final snapshot = await clothingCollection.where('id', isEqualTo: id).get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
    }
  }
}