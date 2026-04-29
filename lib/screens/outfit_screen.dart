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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Nouvelle collection',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Ex: Tenues de travail'),
          onChanged: (val) => collectionName = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
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

  Future<void> _confirmDeleteOutfit(String outfitId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Supprimer la tenue',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        content: Text('Voulez-vous vraiment supprimer cette tenue définitivement ?',
            style: GoogleFonts.lato(color: AppColors.textPrimary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('outfits').doc(outfitId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tenue supprimée avec succès')));
      }
    }
  }

  void _showAddToCollectionDialog(String outfitId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StreamBuilder<List<OutfitCollection>>(
          stream: _firestoreService.getCollections(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }
            final collections = snapshot.data!;

            if (collections.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "Vous n'avez pas encore de collection. Créez-en une d'abord !",
                  style: GoogleFonts.lato(color: AppColors.textSecondary),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              shrinkWrap: true,
              itemCount: collections.length,
              itemBuilder: (context, i) {
                final collection = collections[i];
                return ListTile(
                  leading: const Icon(Icons.folder_outlined, color: AppColors.primary),
                  title: Text(collection.name, style: GoogleFonts.lato(fontWeight: FontWeight.w500)),
                  onTap: () {
                    _addOutfitToCollection(collection.id, outfitId, collection.name, ctx);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 20,
          automaticallyImplyLeading: false,
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Vos looks',
                  style: GoogleFonts.lato(
                      fontSize: 12, color: AppColors.textSecondary, letterSpacing: 0.5)),
              Text('Mes tenues',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.primary),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => OutfitCreatorScreen(user: widget.user))),
            ),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.lato(fontSize: 14),
                tabs: const [
                  Tab(text: 'Toutes les tenues'),
                  Tab(text: 'Collections'),
                ],
              ),
            ),
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return _emptyState('Aucune tenue créée', Icons.style_outlined);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final rawData = docs[index].data();
            Map<String, dynamic> safeData = {};
            if (rawData is Map) {
              safeData = Map<String, dynamic>.from(
                  rawData.map((key, value) => MapEntry(key.toString(), value)));
            }

            Outfit outfit;
            try {
              outfit = Outfit.fromJson(safeData);
            } catch (e) {
              return const SizedBox();
            }

            final dateStr = DateFormat('dd MMM yyyy').format(outfit.dateCreation);

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
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
                            const SizedBox(height: 2),
                            Text(dateStr,
                                style: GoogleFonts.lato(
                                    fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.create_new_folder_outlined,
                            color: AppColors.primary, size: 22),
                        onPressed: () => _showAddToCollectionDialog(outfit.id),
                        tooltip: 'Ajouter à une collection',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.textSecondary, size: 22),
                        onPressed: () => _confirmDeleteOutfit(docs[index].id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: NetworkImg(
                                    item.imageUrl,
                                    placeholder: const Icon(Icons.checkroom_outlined,
                                        size: 28, color: AppColors.textSecondary),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(item.subCategory,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lato(
                                      fontSize: 10, color: AppColors.textSecondary)),
                            ],
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
  }

  Widget _buildCollectionsTab() {
    return StreamBuilder<List<OutfitCollection>>(
      stream: _firestoreService.getCollections(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        final collections = snapshot.data ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: OutlinedButton.icon(
                onPressed: _createNewCollection,
                icon: const Icon(Icons.create_new_folder_outlined),
                label: const Text('Créer une nouvelle collection'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.divider),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  textStyle: GoogleFonts.lato(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
            Expanded(
              child: collections.isEmpty
                  ? _emptyState('Aucune collection créée', Icons.folder_outlined)
                  : ListView.builder(
                      itemCount: collections.length,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemBuilder: (ctx, i) {
                        final collection = collections[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceAlt,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.folder_outlined,
                                  color: AppColors.primary, size: 22),
                            ),
                            title: Text(collection.name,
                                style: GoogleFonts.playfairDisplay(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: AppColors.textPrimary)),
                            subtitle: Text(
                                '${collection.outfitIds.length} tenue(s)',
                                style: GoogleFonts.lato(
                                    fontSize: 12, color: AppColors.textSecondary)),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 14, color: AppColors.textSecondary),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CollectionDetailScreen(
                                      user: widget.user, collection: collection),
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

  Widget _emptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(text,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Future<void> _addOutfitToCollection(String collectionId, String outfitId, String collectionName, BuildContext ctx) async {
    await _firestoreService.addOutfitToCollection(collectionId, outfitId);
    if (!mounted) return;
    Navigator.pop(ctx);
    if (!mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Tenue ajoutée à $collectionName')));
  }
}