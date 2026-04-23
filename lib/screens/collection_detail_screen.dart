import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/outfit.dart';
import '../models/collection.dart';
import '../services/firestore_service.dart';

class CollectionDetailScreen extends StatelessWidget {
  final User user;
  final OutfitCollection collection;

  const CollectionDetailScreen({super.key, required this.user, required this.collection});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text(collection.name),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('collections').doc(collection.id).snapshots(),
        builder: (context, colSnapshot) {
          if (!colSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = colSnapshot.data!.data() as Map<String, dynamic>;
          final List<String> currentOutfitIds = List<String>.from(data['outfitIds'] ?? []);

          if (currentOutfitIds.isEmpty) {
            return const Center(child: Text("Cette collection est vide. Ajoutez des tenues depuis l'onglet précédent !"));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('outfits')
                .where('userId', isEqualTo: user.id)
                .snapshots(),
            builder: (context, outfitSnapshot) {
              if (!outfitSnapshot.hasData) return const Center(child: CircularProgressIndicator());

              final docs = outfitSnapshot.data!.docs.where((doc) => currentOutfitIds.contains(doc.id)).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final outfitData = docs[index].data() as Map<String, dynamic>;
                  final outfit = Outfit.fromJson(outfitData);
                  final dateStr = DateFormat('dd/MM/yyyy').format(outfit.dateCreation);

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      title: Text(outfit.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Créée le $dateStr\n${outfit.items.length} articles"),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () => firestoreService.removeOutfitFromCollection(collection.id, outfit.id),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}