import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/outfit.dart';
import '../models/clothing_item.dart';

class CalendarOutfit extends StatelessWidget {
  final String outfitId;
  final VoidCallback onDelete;

  const CalendarOutfit({super.key, required this.outfitId, required this.onDelete});
  

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('outfits').doc(outfitId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(),
          );
        }
        
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const ListTile(title: Text("Tenue introuvable"));
        }

        final outfitData = snapshot.data!.data() as Map<String, dynamic>;
        final outfit = Outfit.fromJson(outfitData);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ExpansionTile(
            leading: const Icon(Icons.style, color: Colors.purple),
            title: Text(outfit.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${outfit.items.length} vêtements"),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
            children: [
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: outfit.items.length,
                  itemBuilder: (context, index) {
                    final item = outfit.items[index];
                    
                    final String itemDocId = item.id;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('clothing_items').doc(itemDocId).get(),
                      builder: (context, itemSnapshot) {
                        if (!itemSnapshot.hasData || !itemSnapshot.data!.exists) {
                          return const SizedBox(width: 80);
                        }
                        
                        final itemData = itemSnapshot.data!.data() as Map<String, dynamic>;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: itemData['imageUrl'] != null && itemData['imageUrl'].toString().isNotEmpty
                              ? Image.network(
                                  itemData['imageUrl'],
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => 
                                    const Icon(Icons.broken_image, size: 70),
                                )
                              : Container(
                                  width: 70, 
                                  height: 70, 
                                  color: Colors.grey[200], 
                                  child: const Icon(Icons.checkroom)
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}