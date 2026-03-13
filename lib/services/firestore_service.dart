import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/clothing_item.dart';
import '../models/outfit.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseAuth auth = FirebaseAuth.instance;

  final CollectionReference clothingCollection =
      FirebaseFirestore.instance.collection('clothing_items');

  Future<void> addClothingItem(ClothingItem item, String userId) async {
    await clothingCollection.add({
      'id': item.id,
      'name': item.name,
      'mainCategory': item.mainCategory,
      'subCategory': item.subCategory,
      'colors': item.colors,
      'season': item.season,
      'occasions': item.occasions,
      'imageUrl': item.imageUrl,
      'userId': userId,
    });
  }

  Future<void> updateClothingItem(ClothingItem item) async {
    await clothingCollection.doc(item.id).update({
      'name': item.name,
      'mainCategory': item.mainCategory,
      'subCategory': item.subCategory,
      'colors': item.colors,
      'season': item.season,
      'occasions': item.occasions,
      'imageUrl': item.imageUrl,
    });
  }

  Future<void> deleteClothing(String docId, String userId) async {
    final docRef = clothingCollection.doc(docId);
    
    final docSnapshot = await docRef.get();
    if (docSnapshot.exists) {
        final rawData = docSnapshot.data();
        final data = (rawData is Map) ? rawData : {};
        
        if (data['userId'] == userId) {
            await docRef.delete();
        } else {
            throw Exception('Unauthorized deletion attempt.');
        }
    }
  }

  Map<String, int> getCategoryDistribution(List<ClothingItem> items) {
    Map<String, int> stats = {};
    for (var item in items) {
      stats[item.mainCategory] = (stats[item.mainCategory] ?? 0) + 1;
    }
    return stats;
  }

  Stream<List<ClothingItem>> getClothingItems() {
    final user = auth.currentUser;

    if (user == null) {
      return Stream.error('Utilisateur non authentifié');
    }
    
    return clothingCollection
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ClothingItem.fromJson(doc.id, doc.data() as Map<String, dynamic>);
          })
          .toList();
    });
  }

  final CollectionReference outfitCollection =
      FirebaseFirestore.instance.collection('outfits');
  
  Future<void> saveOutfit(Outfit outfit, String userId) async {
    await outfitCollection.doc(outfit.id).set({
      ...outfit.toJson(),
      'userId': userId, 
    });
  }
}