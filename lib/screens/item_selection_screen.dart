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
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              childAspectRatio: 0.75,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10
            ),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final item = ClothingItem.fromJson(docs[i].id, data);
              
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