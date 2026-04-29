import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../services/weather_service.dart';
import '../models/user.dart';
import '../models/clothing_item.dart';
import '../theme/app_theme.dart';
import 'add_clothing_screen.dart';
import '../widgets/clothing_card.dart';
import 'edit_clothing_screen.dart';
import '../services/firestore_service.dart';

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

  bool _showArchives = false;
  bool _onlyShowFavorites = false;

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la déconnexion : $e')));
    }
  }

  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;
  String? _weatherError;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final data = await WeatherService().getCurrentWeather();
      if (mounted) {
        setState(() {
          _weatherData = data;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weatherError = e.toString();
          _isLoadingWeather = false;
        });
      }
      debugPrint("Erreur météo : $e");
    }
  }

  Widget _buildWeatherHeader() {
    if (_isLoadingWeather) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: LinearProgressIndicator(color: AppColors.primary, backgroundColor: AppColors.divider),
      );
    }
    if (_weatherError != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'Météo indisponible',
          style: GoogleFonts.lato(color: AppColors.textSecondary, fontSize: 12),
        ),
      );
    }
    if (_weatherData == null) return const SizedBox.shrink();

    final temp = _weatherData!['main']['temp'];
    final description = _weatherData!['weather'][0]['description'];
    final city = _weatherData!['name'];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_outlined, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${temp.toStringAsFixed(0)}°',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$city · ${description.toString()}',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [_allOption, ..._mainCategories];
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _filterMainCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 24),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _filterMainCategory = cat;
                  if (cat == _allOption) {
                    _subCategoryOptions = [];
                    _filterSubCategory = _allOption;
                  } else {
                    _subCategoryOptions = _subCategoriesMap[cat] ?? [];
                    _filterSubCategory = _allOption;
                  }
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cat,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2,
                    width: isSelected ? 20 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSecondaryFilters() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          GestureDetector(
            onTap: () => setState(() => _onlyShowFavorites = !_onlyShowFavorites),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _onlyShowFavorites ? Colors.red.withOpacity(0.1) : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _onlyShowFavorites ? Colors.red : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _onlyShowFavorites ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: _onlyShowFavorites ? Colors.red : AppColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Favoris',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: _onlyShowFavorites ? FontWeight.w600 : FontWeight.w500,
                      color: _onlyShowFavorites ? Colors.red : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _FilterChipDropdown<String>(
            label: _filterColor == _allOption ? 'Couleur' : _filterColor,
            active: _filterColor != _allOption,
            items: [_allOption, ..._colorOptions],
            onSelected: (val) => setState(() => _filterColor = val),
            itemLabel: (color) => color,
            itemLeading: (color) {
              if (color == _allOption) return null;
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _colorMap[color] ?? Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _FilterChipDropdown<String>(
            label: _filterOccasion == _allOption ? 'Occasion' : (_occasionDisplayMap[_filterOccasion] ?? _filterOccasion),
            active: _filterOccasion != _allOption,
            items: [_allOption, ..._occasionOptions],
            onSelected: (val) => setState(() => _filterOccasion = val),
            itemLabel: (occ) => _occasionDisplayMap[occ] ?? occ,
          ), 
          if (_subCategoryOptions.isNotEmpty) ...[
            const SizedBox(width: 8),
            _FilterChipDropdown<String>(
              label: _filterSubCategory == _allOption ? 'Sous-catégorie' : _filterSubCategory,
              active: _filterSubCategory != _allOption,
              items: [_allOption, ..._subCategoryOptions],
              onSelected: (val) => setState(() => _filterSubCategory = val),
              itemLabel: (sub) => sub,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'Aucun vêtement trouvé',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _showArchives ? 'Archives' : 'Bonjour,',
              style: GoogleFonts.lato(
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              _showArchives ? 'Mes pièces rangées' : widget.user.name,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(_showArchives ? Icons.checkroom_outlined : Icons.archive_outlined),
            onPressed: () => setState(() => _showArchives = !_showArchives),
            tooltip: _showArchives ? 'Retour à la garde-robe' : 'Voir les archives',
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: _confirmSignOut,
            tooltip: 'Se déconnecter',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clothing_items')
            .where('userId', isEqualTo: widget.user.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final docs = snapshot.data!.docs;
          final allItems = docs.map((d) => ClothingItem.fromJson(d.id, d.data())).toList();

          final filteredItems = allItems.where((item) {
            final archiveCondition = _showArchives ? item.isArchived : !item.isArchived;
            final mainOk = _filterMainCategory == _allOption || item.mainCategory == _filterMainCategory;
            final subOk = _filterSubCategory == _allOption || item.subCategory == _filterSubCategory;
            final colorOk = _filterColor == _allOption || item.colors.contains(_filterColor);
            final occasionOk = _filterOccasion == _allOption || item.occasions.contains(_filterOccasion);
            
            final favoriteOk = !_onlyShowFavorites || item.isFavorite;

            return archiveCondition && mainOk && subOk && colorOk && occasionOk && favoriteOk;
          }).toList();

          return Column(
            children: [
              if (!_showArchives) _buildWeatherHeader(),
              _buildCategoryTabs(),
              const SizedBox(height: 8),
              _buildSecondaryFilters(),
              const SizedBox(height: 12),
              Expanded(
                child: filteredItems.isEmpty
                    ? _buildEmpty()
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3 / 4,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return ClothingCard(
                            item: item,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditClothingScreen(
                                    user: widget.user,
                                    clothingItem: item,
                                    onUpdate: (_) => setState(() {}),
                                    onDelete: (_) => setState(() {}),
                                  ),
                                ),
                              );
                            },
                            onFavoriteTap: () {
                              FirestoreService().toggleFavorite(item.id, item.isFavorite);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddClothingScreen(user: widget.user, onAdd: _addNewItem),
          ),
        ),
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          'Ajouter',
          style: GoogleFonts.lato(fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
      ),
    );
  }
}

class _FilterChipDropdown<T> extends StatelessWidget {
  final String label;
  final bool active;
  final List<T> items;
  final ValueChanged<T> onSelected;
  final String Function(T) itemLabel;
  final Widget? Function(T)? itemLeading;

  const _FilterChipDropdown({
    required this.label,
    required this.active,
    required this.items,
    required this.onSelected,
    required this.itemLabel,
    this.itemLeading,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      color: AppColors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => items.map((item) {
        final leading = itemLeading?.call(item);
        return PopupMenuItem<T>(
          value: item,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading, const SizedBox(width: 10)],
              Text(itemLabel(item), style: GoogleFonts.lato(fontSize: 14, color: AppColors.textPrimary)),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}