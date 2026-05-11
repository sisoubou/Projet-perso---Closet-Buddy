import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_app_check/firebase_app_check.dart';

import '../models/user.dart';
import '../models/clothing_item.dart';
import '../theme/app_theme.dart';

class AddClothingScreen extends StatefulWidget {
  final User user;
  final Function(ClothingItem) onAdd;

  const AddClothingScreen({super.key, required this.user, required this.onAdd});

  @override
  AddClothingScreenState createState() => AddClothingScreenState();
}

class AddClothingScreenState extends State<AddClothingScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _mainCategory = '';
  String _subCategory = '';
  final List<String> _selectedColors = [];
  String _selectedSeason = 'Toutes saisons';
  final List<String> _selectedOccasions = [];
  File? _imageFile;
  List<String> _subCategoryOptions = [];
  bool _isSaving = false;

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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final fb_auth.User? currentUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aucun utilisateur n'est connecté.")),
      );
      return;
    }

    setState(() => _isSaving = true);
    String imageUrl = '';

    try {
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('users')
            .child(currentUser.uid)
            .child('wardrobe')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        final localSize = await _imageFile!.length();
        if (localSize == 0) throw Exception('Fichier local vide');

        final metadata = SettableMetadata(contentType: 'image/jpeg');
        final TaskSnapshot snapshot = await storageRef.putFile(_imageFile!, metadata);
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      final newItem = ClothingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUser.uid,
        name: _name,
        mainCategory: _mainCategory,
        subCategory: _subCategory,
        imageUrl: imageUrl,
        colors: _selectedColors,
        occasions: _selectedOccasions,
        season: _selectedSeason,
      );

      await FirebaseFirestore.instance.collection('clothing_items').doc(newItem.id).set({
        "id": newItem.id,
        "name": newItem.name,
        "mainCategory": newItem.mainCategory,
        "subCategory": newItem.subCategory,
        "imageUrl": newItem.imageUrl,
        "colors": newItem.colors,
        "userId": currentUser.uid,
        "occasions": newItem.occasions,
        "season": newItem.season,
        "wearCount": 0,
        "isArchived": false,
        "isFavorite": false,
      });

      widget.onAdd(newItem);
      if (!mounted) return;
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nouveau vêtement',
            style: GoogleFonts.playfairDisplay(
                fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  _ImagePickerCard(imageFile: _imageFile, onTap: _pickImage),
                  const SizedBox(height: 24),
                  _section(
                    title: 'Informations',
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Nom du vêtement'),
                          validator: (v) => v == null || v.isEmpty ? 'Nom requis' : null,
                          onSaved: (v) => _name = v!,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _mainCategory.isEmpty ? null : _mainCategory,
                          decoration: const InputDecoration(labelText: 'Catégorie principale'),
                          items: _mainCategories.map((cat) {
                            return DropdownMenuItem(value: cat, child: Text(cat));
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _mainCategory = val ?? '';
                              _subCategoryOptions = _subCategoriesMap[_mainCategory] ?? [];
                              _subCategory = '';
                            });
                          },
                          validator: (v) => v == null || v.isEmpty ? 'Choisissez une catégorie' : null,
                        ),
                        if (_subCategoryOptions.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _subCategory.isEmpty ? null : _subCategory,
                            decoration: const InputDecoration(labelText: 'Sous-catégorie'),
                            items: _subCategoryOptions.map((sub) {
                              return DropdownMenuItem(value: sub, child: Text(sub));
                            }).toList(),
                            onChanged: (val) => setState(() => _subCategory = val ?? ''),
                            validator: (v) => v == null || v.isEmpty ? 'Choisissez une sous-catégorie' : null,
                          ),
                        ],
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedSeason,
                          decoration: const InputDecoration(labelText: 'Saison'),
                          items: _seasonOptions.map((season) {
                            return DropdownMenuItem(value: season, child: Text(season));
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedSeason = val ?? 'Toutes saisons'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _section(
                    title: 'Couleurs',
                    subtitle: _selectedColors.isEmpty ? 'Sélectionnez une ou plusieurs couleurs' : null,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: _colorOptions.map((colorName) {
                        return _ColorChip(
                          label: colorName,
                          color: _colorMap[colorName]!,
                          selected: _selectedColors.contains(colorName),
                          onTap: () {
                            setState(() {
                              if (_selectedColors.contains(colorName)) {
                                _selectedColors.remove(colorName);
                              } else {
                                _selectedColors.add(colorName);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _section(
                    title: 'Occasions',
                    subtitle: _selectedOccasions.isEmpty ? 'Quand porterez-vous ce vêtement ?' : null,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: _occasionMap.entries.map((entry) {
                        return _TagChip(
                          label: entry.value,
                          selected: _selectedOccasions.contains(entry.key),
                          onTap: () {
                            setState(() {
                              if (_selectedOccasions.contains(entry.key)) {
                                _selectedOccasions.remove(entry.key);
                              } else {
                                _selectedOccasions.add(entry.key);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _isSaving
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: ElevatedButton(
                  onPressed: _saveForm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                  ),
                  child: const Text('Ajouter à ma garde-robe'),
                ),
              ),
            ),
    );
  }

  Widget _section({required String title, String? subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: GoogleFonts.lato(fontSize: 12, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final File? imageFile;
  final VoidCallback onTap;

  const _ImagePickerCard({required this.imageFile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.divider,
            width: imageFile == null ? 1.5 : 0,
            style: imageFile == null ? BorderStyle.solid : BorderStyle.none,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: imageFile != null
              ? Stack(
                  children: [
                    Positioned.fill(child: Image.file(imageFile!, fit: BoxFit.cover)),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text('Changer',
                                style: GoogleFonts.lato(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text('Ajouter une photo',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Appuyez pour choisir depuis votre galerie',
                        style: GoogleFonts.lato(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 0.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TagChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(label,
            style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.textPrimary)),
      ),
    );
  }
}
