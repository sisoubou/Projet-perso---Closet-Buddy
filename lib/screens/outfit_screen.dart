import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/outfit.dart';
import 'outfit_creator_screen.dart';

class OutfitScreen extends StatelessWidget {
  final User user;

  const OutfitScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes tenues'),
        actions: [
          IconButton(
            tooltip: 'Créer une tenue',
            icon: const Icon(Icons.add),
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
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OutfitCreatorScreen(user: user),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Créer ma première tenue'),
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
              
              Map<String, dynamic> safeMap(dynamic data) {
                if (data is Map) {
                  return Map<String, dynamic>.from(data.map((key, value) => MapEntry(key.toString(), value)));
                }
                return {};
              }
              
              final data = safeMap(rawData);
              
              Outfit? outfit;
              try {
                 outfit = Outfit.fromJson(data);
              } catch (e) {
                 print("Erreur de lecture tenue: $e");
              }

              final outfitName = outfit?.name ?? data['name'] ?? 'Tenue sans nom';
              final outfitDate = outfit?.dateCreation ?? DateTime.now();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(outfitName),
                  subtitle: Text('Créée le ${outfitDate.toString().split(' ')[0]}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Supprimer la tenue'),
                          content: const Text('Voulez-vous supprimer cette tenue ?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Supprimer'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('outfits')
                            .doc(docs[index].id)
                            .delete();

                        if(context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tenue supprimée')),
                            );
                        }
                      }
                    },
                  ),
                  onTap: () {
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OutfitCreatorScreen(user: user),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}