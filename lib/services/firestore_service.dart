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
    await clothingCollection.doc(item.id).update({
      'name': item.name,
      'mainCategory': item.mainCategory,
      'subCategory': item.subCategory,
      'color': item.color,
      'season': item.season,
      'occasion': item.occasion,
      'imageUrl': item.imageUrl,
    });
  }

  Future<void> deleteClothing(String docId, String userId) async {
    final docRef = clothingCollection.doc(docId);
    
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        if (data['userId'] == userId) {
            await docRef.delete();
        } else {
            throw Exception('Unauthorized deletion attempt.');
        }
    }
  }

  final CollectionReference outfitCollection =
      FirebaseFirestore.instance.collection('outfits');
  
  Future<void> saveOutfit(dynamic outfit, String userId) async {
    await outfitCollection.doc(outfit.id).set({
      ...outfit.toJson(),
      'userId': userId, 
    });
  }
}