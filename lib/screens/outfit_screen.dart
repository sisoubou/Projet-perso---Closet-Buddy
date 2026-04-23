import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/outfit.dart';
import '../models/collection.dart';
import '../services/firestore_service.dart';
import 'outfit_creator_screen.dart';
import 'collection_detail_screen.dart';

class OutfitScreen extends StatefulWidget {
  final User user;
  const OutfitScreen({super.key, required this.user});

  @override
  State<OutfitScreen> createState() => _OutfitScreenState();
}

class _OutfitScreenState extends State<OutfitScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _createNewCollection() {
    String collectionName = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle Collection'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Ex: Tenues de Travail'),
          onChanged: (val) => collectionName = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (collectionName.trim().isEmpty) return;
              final newCol = OutfitCollection(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                userId: widget.user.id,
                name: collectionName.trim(),
                description: '',
              );
              await _firestoreService.createCollection(newCol);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showAddToCollectionDialog(String outfitId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StreamBuilder<List<OutfitCollection>>(
          stream: _firestoreService.getCollections(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final collections = snapshot.data!;
            
            if (collections.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Vous n'avez pas encore de collection. Créez-en une d'abord !"),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: collections.length,
              itemBuilder: (context, i) {
                final collection = collections[i];
                return ListTile(
                  leading: const Icon(Icons.folder, color: Colors.purple),
                  title: Text(collection.name),
                  onTap: () async {
                    await _firestoreService.addOutfitToCollection(collection.id, outfitId);
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tenue ajoutée à ${collection.name}'))
                      );
                    }
                  },
                );
              },
            );
          },
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          title: const Text('Mes tenues', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.black, size: 30),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OutfitCreatorScreen(user: widget.user))),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.purple,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.purple,
            tabs: [
              Tab(text: 'Toutes les tenues'),
              Tab(text: 'Mes Collections'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAllOutfitsTab(),
            _buildCollectionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAllOutfitsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('outfits')
          .where('userId', isEqualTo: widget.user.id)
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
                        Expanded(child: Text(outfit.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                        IconButton(
                          icon: const Icon(Icons.create_new_folder_outlined, color: Colors.purple),
                          onPressed: () => _showAddToCollectionDialog(outfit.id),
                          tooltip: 'Ajouter à une collection',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => FirebaseFirestore.instance.collection('outfits').doc(docs[index].id).delete(),
                        ),
                      ],
                    ),
                    Text("Créée le $dateStr", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const Divider(height: 20),
                    
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
    );
  }

  Widget _buildCollectionsTab() {
    return StreamBuilder<List<OutfitCollection>>(
      stream: _firestoreService.getCollections(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final collections = snapshot.data ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _createNewCollection,
                icon: const Icon(Icons.create_new_folder),
                label: const Text('Créer une nouvelle collection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[50],
                  foregroundColor: Colors.purple,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
            Expanded(
              child: collections.isEmpty
                  ? const Center(child: Text('Aucune collection créée', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: collections.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (ctx, i) {
                        final collection = collections[i];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.folder, color: Colors.purple, size: 40),
                            title: Text(collection.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${collection.outfitIds.length} tenue(s) à l\'intérieur'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CollectionDetailScreen(
                                    user: widget.user, 
                                    collection: collection
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}