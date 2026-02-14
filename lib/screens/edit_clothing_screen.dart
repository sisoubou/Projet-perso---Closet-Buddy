import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'dart:io';

import '../models/user.dart';
import '../models/clothing_item.dart';
import '../services/firestore_service.dart';

class EditClothingScreen extends StatefulWidget {
  final User user;
  final ClothingItem clothingItem;
  final Function(ClothingItem) onUpdate;
  final Function(String)? onDelete;

  const EditClothingScreen({
    super.key,
    required this.user,
    required this.clothingItem,
    required this.onUpdate,
    this.onDelete,
  });

  @override
  EditClothingScreenState createState() => EditClothingScreenState();
}

class EditClothingScreenState extends State<EditClothingScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late String _mainCategory;
  late String _subCategory;
  late List<String> _selectedColors;
  late List<String> _selectedOccasions;
  late String _season;
  File? _imageFile;

  List<String> _subCategoryOptions = [];
  final List<String> _mainCategories = ['Hauts', 'Manteaux', 'Bas', 'Robes & Combinaisons', 'Chaussures', 'Accessoires'];
  final Map<String, List<String>> _subCategoriesMap = {
    'Hauts': ['Tops', 'T-shirts', 'Pulls', 'Chemises', 'Sweats', 'Tops de sport'],
    'Manteaux': ['Manteaux', 'Vestes', 'Blousons'],
    'Bas': ['Jeans', 'Jupes', 'Pantalons', 'Shorts', 'Leggings', 'Joggings'],
    'Robes & Combinaisons': ['Robes mini', 'Robes longue', 'Combinaisons'],
    'Chaussures': ['Baskets', 'Bottes', 'Chaussures Plates', 'Talons'],
    'Accessoires': ['Ceintures', 'Sacs', 'Chapeaux', 'Bijoux', 'Accessoires Cheveux', 'Echarpes', 'Gants', 'Lunettes de soleil', 'Chaussettes & Collants'],
  };
  final List<String> _colorOptions = ['Rouge', 'Bleu', 'Vert', 'Noir', 'Blanc', 'Jaune', 'Violet', 'Orange', 'Rose', 'Gris', 'Marron', 'Beige'];
  final Map<String, Color> _colorMap = {
    'Rouge': Colors.red,
    'Bleu': Colors.blue,
    'Vert': Colors.green,
    'Noir': Colors.black,
    'Blanc': Colors.white,
    'Jaune': Colors.yellow,
    'Violet': Colors.purple,
    'Orange': Colors.orange,
    'Rose': Colors.pink,
    'Gris': Colors.grey,
    'Marron': Colors.brown,
    'Beige': const Color.fromARGB(255, 216, 163, 143),
  };
  final Map<String, String> _occasionMap = {
    'casual': 'Décontracté',
    'formal': 'Formel',
    'sport': 'Sportif',
    'party': 'Fête',
  };

  final List<String> _seasonOptions = ['Toutes saisons', 'Hiver', 'Printemps', 'Eté', 'Automne'];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _name = widget.clothingItem.name;
    _mainCategory = widget.clothingItem.mainCategory;
    _subCategory = widget.clothingItem.subCategory;
    _subCategoryOptions = _subCategoriesMap[_mainCategory] ?? [];
    _selectedColors = widget.clothingItem.colors;
    _selectedOccasions = widget.clothingItem.occasions;
    _season = widget.clothingItem.season;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    String imageUrl = widget.clothingItem.imageUrl;

    if (_imageFile != null) {
      final fb_auth.User? currentUser = fb_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(currentUser.uid)
          .child('wardrobe')
          .child('${widget.clothingItem.id}_edited.jpg');

      try {
        final TaskSnapshot snapshot = await storageRef.putFile(_imageFile!);
        imageUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur upload image')));
        return;
      }
    }

    final updatedItem = widget.clothingItem.copyWith(
      name: _name,
      mainCategory: _mainCategory,
      subCategory: _subCategory,
      colors: _selectedColors,
      occasions: _selectedOccasions,
      season: _season,
      imageUrl: imageUrl,
    );

    await FirestoreService().updateClothingItem(updatedItem);

    widget.onUpdate(updatedItem);
    Navigator.pop(context);
  }

  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le vêtement'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce vêtement ?'),
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
      setState(() => _isSaving = true);

      try {
        await FirestoreService().deleteClothing(widget.clothingItem.id, widget.user.id);

        widget.onDelete?.call(widget.clothingItem.id);

        if (!mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier un vêtement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteItem,
          ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                      onSaved: (value) => _name = value!,
                    ),

                    DropdownButtonFormField<String>(
                      value: _mainCategory.isEmpty ? null : _mainCategory,
                      decoration: const InputDecoration(labelText: 'Catégorie principale'),
                      items: _mainCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _mainCategory = val ?? '';
                          _subCategoryOptions = _subCategoriesMap[_mainCategory] ?? [];
                          _subCategory = '';
                        });
                      },
                    ),

                    if (_subCategoryOptions.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: _subCategory.isEmpty ? null : _subCategory,
                        decoration: const InputDecoration(labelText: 'Sous-catégorie'),
                        items: _subCategoryOptions.map((sub) => DropdownMenuItem(value: sub, child: Text(sub))).toList(),
                        onChanged: (val) => setState(() => _subCategory = val ?? ''),
                      ),
                    
                    const SizedBox(height: 16),
                    Text('Couleurs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: _colorOptions.map((colorName) {
                        final isSelected = _selectedColors.contains(colorName);
                        return FilterChip(
                          label: Text(colorName),
                          selected: isSelected,
                          selectedColor: _colorMap[colorName]!.withOpacity(0.5),
                          checkmarkColor: Colors.black,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) _selectedColors.add(colorName);
                              else _selectedColors.remove(colorName);
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.black : Colors.grey.shade300)),
                          avatar: CircleAvatar(backgroundColor: _colorMap[colorName], radius: 10),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),
                    const Text('Occasions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 8,
                      children: _occasionMap.entries.map((entry) {
                        final isSelected = _selectedOccasions.contains(entry.key);
                        return FilterChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) _selectedOccasions.add(entry.key);
                              else _selectedOccasions.remove(entry.key);
                            });
                          },
                        );
                      }).toList(),
                    ),

                    DropdownButtonFormField<String>(
                      value: _season,
                      decoration: const InputDecoration(labelText: 'Saison'),
                      items: _seasonOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) => setState(() => _season = val ?? 'Toutes saisons'),
                    ),

                    const SizedBox(height: 20),
                    // Affichage Image (Similaire à avant)
                    _imageFile != null
                        ? Image.file(_imageFile!, height: 200, fit: BoxFit.cover)
                        : widget.clothingItem.imageUrl.isNotEmpty
                            ? Image.network(widget.clothingItem.imageUrl, height: 200, fit: BoxFit.cover)
                            : Container(height: 150, color: Colors.grey.shade200, alignment: Alignment.center, child: const Text('Aucune image')),

                    TextButton.icon(icon: const Icon(Icons.photo), label: const Text('Changer l\'image'), onPressed: _pickImage),
                    const SizedBox(height: 20),
                    ElevatedButton(onPressed: _saveForm, child: const Text('Sauvegarder les modifications')),
                  ],
                ),
              ),
            ),
    );
  }
}
