import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/outfit.dart';
import 'outfit_creator_screen.dart';

class OutfitScreen extends StatelessWidget {
  final User user;
  const OutfitScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Mes tenues', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.black, size: 30),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OutfitCreatorScreen(user: user))),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('outfits')
            .where('userId', isEqualTo: user.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('Aucune tenue créée'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final rawData = docs[index].data(); 
              Map<String, dynamic> safeData = {};
              if (rawData is Map) {
                safeData = Map<String, dynamic>.from(rawData.map((key, value) => MapEntry(key.toString(), value)));
              }
              
              Outfit outfit;
              try {
                 outfit = Outfit.fromJson(safeData);
              } catch (e) {
                 return const SizedBox();
              }
              
              final dateStr = DateFormat('dd/MM/yyyy').format(outfit.dateCreation);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(outfit.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => FirebaseFirestore.instance.collection('outfits').doc(docs[index].id).delete(),
                          ),
                        ],
                      ),
                      Text("Créée le $dateStr", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const Divider(height: 20),
                      
                      // NOUVEL AFFICHAGE : LISTE HORIZONTALE DES ITEMS
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: outfit.items.length,
                          itemBuilder: (ctx, i) {
                            final item = outfit.items[i];
                            return Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 70,
                              child: Column(
                                children: [
                                  Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey[200],
                                      image: item.imageUrl.isNotEmpty 
                                          ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover)
                                          : null,
                                    ),
                                    child: item.imageUrl.isEmpty ? const Icon(Icons.checkroom, size: 30) : null,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(item.subCategory, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}