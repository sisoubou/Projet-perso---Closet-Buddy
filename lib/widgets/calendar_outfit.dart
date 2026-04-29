import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/outfit.dart';
import '../theme/app_theme.dart';
import 'network_img.dart';

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
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: LinearProgressIndicator(color: AppColors.primary, backgroundColor: AppColors.divider),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return ListTile(
            title: Text("Tenue introuvable",
                style: GoogleFonts.lato(color: AppColors.textSecondary)),
          );
        }

        final outfitData = snapshot.data!.data() as Map<String, dynamic>;
        final outfit = Outfit.fromJson(outfitData);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceAlt,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.style_outlined, color: AppColors.primary, size: 20),
                ),
                title: Text(outfit.name,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                subtitle: Text("${outfit.items.length} vêtements",
                    style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary, size: 20),
                  onPressed: () async {
                    // NOUVEAU : Pop-up pour le calendrier
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        title: Text('Retirer du planning',
                            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
                        content: Text('Voulez-vous retirer cette tenue de votre calendrier ?',
                            style: GoogleFonts.lato()),
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
                      onDelete();
                    }
                  },
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
                          future: FirebaseFirestore.instance
                              .collection('clothing_items')
                              .doc(itemDocId)
                              .get(),
                          builder: (context, itemSnapshot) {
                            if (!itemSnapshot.hasData || !itemSnapshot.data!.exists) {
                              return const SizedBox(width: 80);
                            }

                            final itemData =
                                itemSnapshot.data!.data() as Map<String, dynamic>;
                            final imageUrl = itemData['imageUrl']?.toString() ?? '';

                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: NetworkImg(
                                    imageUrl,
                                    placeholder: const Icon(Icons.checkroom_outlined,
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}