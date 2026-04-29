import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/outfit.dart';
import '../models/collection.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/network_img.dart';

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
          if (!colSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          
          final data = colSnapshot.data!.data() as Map<String, dynamic>;
          final List<String> currentOutfitIds = List<String>.from(data['outfitIds'] ?? []);

          if (currentOutfitIds.isEmpty) {
            return Center(
              child: Text(
                "Ce dossier est vide.",
                style: GoogleFonts.lato(color: AppColors.textSecondary, fontSize: 16),
              ),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('outfits')
                .where('userId', isEqualTo: user.id)
                .snapshots(),
            builder: (context, outfitSnapshot) {
              if (!outfitSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

              final docs = outfitSnapshot.data!.docs.where((doc) => currentOutfitIds.contains(doc.id)).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final outfitData = docs[index].data() as Map<String, dynamic>;
                  final outfit = Outfit.fromJson(outfitData);
                  final dateStr = DateFormat('dd MMM yyyy').format(outfit.dateCreation);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(outfit.name,
                                      style: GoogleFonts.playfairDisplay(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary)),
                                  Text("Ajoutée le $dateStr",
                                      style: GoogleFonts.lato(
                                          fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 22),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppColors.surface,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    title: Text('Retirer du dossier',
                                        style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
                                    content: const Text('Voulez-vous retirer cette tenue de cette collection ?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Retirer', style: TextStyle(color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  firestoreService.removeOutfitFromCollection(collection.id, outfit.id);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // --- APERÇU VISUEL DES VÊTEMENTS ---
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: outfit.items.length,
                            itemBuilder: (ctx, i) {
                              final item = outfit.items[i];
                              return Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 60,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: NetworkImg(
                                    item.imageUrl,
                                    placeholder: Container(
                                      color: AppColors.surfaceAlt,
                                      child: const Icon(Icons.checkroom, size: 20, color: AppColors.textSecondary),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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