import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/outfit.dart';
import '../models/clothing_item.dart';
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
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            tooltip: 'Créer une tenue',
            icon: const Icon(Icons.add_circle, color: Colors.black, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OutfitCreatorScreen(user: user),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('outfits')
            .where('userId', isEqualTo: user.id)
            .orderBy('dateCreation', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.style_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucune tenue créée',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OutfitCreatorScreen(user: user),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Créer ma première tenue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                outfit.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Créée le $dateStr",
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _deleteOutfit(context, docs[index].id),
                          ),
                        ],
                      ),
                      
                      const Divider(height: 20),

                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildClothingItem(outfit.top, "Haut"),
                            _buildPlusSign(),
                            _buildClothingItem(outfit.bottom, "Bas"),
                            
                            if (outfit.shoes != null) ...[
                              _buildPlusSign(),
                              _buildClothingItem(outfit.shoes!, "Chaussures"),
                            ],
                            
                            if (outfit.accessory != null) ...[
                              _buildPlusSign(),
                              _buildClothingItem(outfit.accessory!, "Accessoire"),
                            ],
                          ],
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

  Widget _buildClothingItem(ClothingItem item, String label) {
    return Column(
      children: [
        Container(
          width: 70, 
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            image: item.imageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(item.imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: item.imageUrl.isEmpty 
              ? Icon(Icons.checkroom, color: Colors.grey[400]) 
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[700], fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPlusSign() {
    return Container(
      height: 70,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(Icons.add, size: 16, color: Colors.grey[400]),
    );
  }

  Future<void> _deleteOutfit(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous supprimer cette tenue ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('outfits').doc(docId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tenue supprimée')),
        );
      }
    }
  }
}