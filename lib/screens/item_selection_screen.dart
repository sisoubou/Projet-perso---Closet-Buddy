import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/clothing_item.dart';
import '../widgets/clothing_card.dart';

class ItemSelectionScreen extends StatelessWidget {
  final String userId;
  final String category;

  const ItemSelectionScreen({
    super.key,
    required this.userId,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Choisir : $category')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clothing_items')
            .where('userId', isEqualTo: userId)
            .where('mainCategory', isEqualTo: category)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("Aucun vêtement dans cette catégorie"));

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              childAspectRatio: 0.7,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16
            ),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final rawData = docs[i].data();
              
              Map<String, dynamic> safeData = {};
              if (rawData is Map) {
                safeData = Map<String, dynamic>.from(
                  rawData.map((key, value) => MapEntry(key.toString(), value))
                );
              }

              final item = ClothingItem.fromJson(docs[i].id, safeData);
              
              return ClothingCard(
                item: item,
                onTap: () {
                  Navigator.pop(context, item);
                },
              );
            },
          );
        },
      ),
    );
  }
}