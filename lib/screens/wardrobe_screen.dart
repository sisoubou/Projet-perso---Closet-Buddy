import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../models/user.dart';
import '../models/clothing_item.dart';
import 'add_clothing_screen.dart';
import '../widgets/clothing_card.dart';
import 'edit_clothing_screen.dart';

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
          IconButton(
            tooltip: 'Se déconnecter',
            icon: const Icon(Icons.logout),
            onPressed: _confirmSignOut,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _filterMainCategory,
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
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: _filterSubCategory,
                    items: [
                      DropdownMenuItem(value: _allOption, child: const Text('Tout')),
                      ..._subCategoryOptions.map((sub) => DropdownMenuItem(value: sub, child: Text(sub))),
                    ],
                    onChanged: (_subCategoryOptions.isEmpty) ? null : (val) => setState(() => _filterSubCategory = val ?? _allOption),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: _filterColor,
                    items: [
                      DropdownMenuItem(value: _allOption, child: const Text('Tout')),
                      ..._colorOptions.map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Container(width: 20, height: 20, decoration: BoxDecoration(color: _colorMap[c], border: Border.all(color: Colors.black))),
                            const SizedBox(width: 8),
                            Text(c),
                          ],
                        ),
                      )),
                    ],
                    onChanged: (val) => setState(() => _filterColor = val ?? _allOption),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _filterMainCategory = _allOption;
                      _filterSubCategory = _allOption;
                      _filterColor = _allOption;
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
                  );
                }).toList();

                final filteredItems = items.where((item) {
                  final mainOk = _filterMainCategory == _allOption || item.mainCategory == _filterMainCategory;
                  final subOk = _filterSubCategory == _allOption || item.subCategory == _filterSubCategory;
                  final colorOk = _filterColor == _allOption || item.color == _filterColor;
                  return mainOk && subOk && colorOk;
                }).toList();

                if (filteredItems.isEmpty) {
                  return const Center(child: Text('Aucun vêtement correspondant '));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3 / 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
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
