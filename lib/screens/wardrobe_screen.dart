import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../models/user.dart';
import '../models/clothing_item.dart';
import 'add_clothing_screen.dart';
import '../widgets/clothing_card.dart';
import 'edit_clothing_screen.dart';
import 'outfit_screen.dart';
import 'outfit_creator_screen.dart';

class WardrobeScreen extends StatefulWidget {
  final User user;
  const WardrobeScreen({super.key, required this.user});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final String _allOption = 'Tout';
  String _filterMainCategory = 'Tout';
  String _filterSubCategory = 'Tout';
  String _filterColor = 'Tout';
  String _filterOccasion = 'Tout';
  List<String> _subCategoryOptions = [];

  final List<String> _mainCategories = ['Haut', 'Bas', 'Chaussures', 'Accessoires'];
  final Map<String, List<String>> _subCategoriesMap = {
    'Haut': ['T-shirt', 'Pull', 'Chemise', 'Veste'],
    'Bas': ['Jean', 'Jupe', 'Pantalon', 'Short'],
    'Chaussures': ['Baskets', 'Bottes', 'Sandales', 'Talons'],
    'Accessoires': ['Ceinture', 'Sac', 'Chapeau'],
  };

  final List<String> _colorOptions = ['Rouge', 'Bleu', 'Vert', 'Noir', 'Blanc', 'Jaune'];
  final Map<String, Color> _colorMap = {
    'Rouge': Colors.red,
    'Bleu': Colors.blue,
    'Vert': Colors.green,
    'Noir': Colors.black,
    'Blanc': Colors.white,
    'Jaune': Colors.yellow,
  };

  final List<String> _occasionOptions = ['casual', 'formal', 'sport', 'party'];
  final Map<String, String> _occasionDisplayMap = {
    'casual': 'Décontracté',
    'formal': 'Formel',
    'sport': 'Sportif',
    'party': 'Fête',
  };

  void _addNewItem(ClothingItem item) {
    setState(() {});
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Déconnexion')),
        ],
      ),
    );
    if (confirmed == true) {
      await _signOut();
    }
  }

  Future<void> _signOut() async {
    try {
      await fb_auth.FirebaseAuth.instance.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la déconnexion : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Garde-robe de ${widget.user.name}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'create_outfit':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OutfitCreatorScreen(user: widget.user),
                    ),
                  );
                  break;
                case 'view_outfits':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OutfitScreen(user: widget.user),
                    ),
                  );
                  break;
                case 'logout':
                  _confirmSignOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create_outfit',
                child: Row(
                  children: [
                    Icon(Icons.add, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Créer une tenue'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'view_outfits',
                child: Row(
                  children: [
                    Icon(Icons.style, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Mes tenues'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Se déconnecter'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.22,
                  child: DropdownButton<String>(
                    value: _filterMainCategory,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: _allOption, child: const Text('Tout')),
                      ..._mainCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _filterMainCategory = val ?? _allOption;
                        if (_filterMainCategory == _allOption) {
                          _subCategoryOptions = [];
                          _filterSubCategory = _allOption;
                        } else {
                          _subCategoryOptions = _subCategoriesMap[_filterMainCategory] ?? [];
                          _filterSubCategory = _allOption;
                        }
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.22,
                  child: DropdownButton<String>(
                    value: _filterSubCategory,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: _allOption, child: const Text('Tout')),
                      ..._subCategoryOptions.map((sub) => DropdownMenuItem(value: sub, child: Text(sub))),
                    ],
                    onChanged: (_subCategoryOptions.isEmpty) ? null : (val) => setState(() => _filterSubCategory = val ?? _allOption),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.22,
                  child: DropdownButton<String>(
                    value: _filterColor,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: _allOption, child: const Text('Tout')),
                      ..._colorOptions.map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Container(width: 20, height: 20, decoration: BoxDecoration(color: _colorMap[c], border: Border.all(color: Colors.black))),
                            const SizedBox(width: 8),
                            Expanded(child: Text(c, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      )),
                    ],
                    onChanged: (val) => setState(() => _filterColor = val ?? _allOption),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.22,
                  child: DropdownButton<String>(
                    value: _filterOccasion,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: _allOption, child: const Text('Tout')),
                      ..._occasionOptions.map((occ) => DropdownMenuItem(value: occ, child: Text(_occasionDisplayMap[occ] ?? occ))),
                    ],
                    onChanged: (val) => setState(() => _filterOccasion = val ?? _allOption),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _filterMainCategory = _allOption;
                      _filterSubCategory = _allOption;
                      _filterColor = _allOption;
                      _filterOccasion = _allOption;
                      _subCategoryOptions = [];
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réinitialiser'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clothing_items')
                  .where('userId', isEqualTo: widget.user.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                final items = docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return ClothingItem(
                    id: d.id,
                    userId: data['userId'] ?? '',
                    name: data['name'] ?? '',
                    mainCategory: data['mainCategory'] ?? '',
                    subCategory: data['subCategory'] ?? '',
                    imageUrl: data['imageUrl'] ?? '',
                    color: data['color'] ?? '',
                    occasion: data['occasion'] ?? 'casual',
                    season: data['season'] ?? 'Toutes saisons',
                  );
                }).toList();

                final filteredItems = items.where((item) {
                  final mainOk = _filterMainCategory == _allOption || item.mainCategory == _filterMainCategory;
                  final subOk = _filterSubCategory == _allOption || item.subCategory == _filterSubCategory;
                  final colorOk = _filterColor == _allOption || item.color == _filterColor;
                  final occasionOk = _filterOccasion == _allOption || item.occasion == _filterOccasion;
                  return mainOk && subOk && colorOk && occasionOk;
                }).toList();

                if (filteredItems.isEmpty) {
                  return const Center(child: Text('Aucun vêtement correspondant '));
                }

                return MasonryGridView.count(
                  padding: const EdgeInsets.all(16),
                  crossAxisCount: 2,  
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16, 
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                  
                    return ClothingCard(
                      item: filteredItems[index],
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                            builder: (_) => EditClothingScreen(
                                user: widget.user,
                                clothingItem: filteredItems[index],
                                onUpdate: (_) => setState(() {}),
                                onDelete: (id) => setState(() {}),
                            ),
                            ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddClothingScreen(
              user: widget.user,
              onAdd: _addNewItem,
            ),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
