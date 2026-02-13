import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:intl/date_symbol_data_local.dart';

import '../services/weather_service.dart';
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
      print("Erreur météo : $e");
    }
  }

  Widget _buildSuggestionCard(List<ClothingItem> allItems) {
    if (_isLoadingWeather) {
      return const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(child: LinearProgressIndicator()),
      );
    }
    if (_weatherError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        color: Colors.red[50],
        child: Text('Météo indisponible (Activez le GPS) : $_weatherError', style: const TextStyle(color: Colors.red)),
      );
    }
    if (_weatherData == null) {
      return const SizedBox.shrink();
    }

    final temp = _weatherData!['main']['temp'];
    final description = _weatherData!['weather'][0]['description'];
    final city = _weatherData!['name'];

    List<String> targetSeasons = ['Toutes saisons'];
    if (temp < 12) {
      targetSeasons.add('Hiver');
    } else if (temp < 22) {
      targetSeasons.addAll(['Printemps', 'Automne']);
    } else {
      targetSeasons.add('Été');
      targetSeasons.add('Ete');
    }

    final tops = allItems.where((item) => item.mainCategory == 'Haut' && targetSeasons.contains(item.season)).toList();
    final bottoms = allItems.where((item) => item.mainCategory == 'Bas' && targetSeasons.contains(item.season)).toList();
    final shoes = allItems.where((item) => item.mainCategory == 'Chaussures' && targetSeasons.contains(item.season)).toList();
  
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$city · ${temp.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const Icon(Icons.cloud, color: Colors.blueGrey),
            ],
          ),
          Text(description.toString().toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          
          if (tops.isEmpty && bottoms.isEmpty)
             const Text("Aucun vêtement trouvé pour cette météo.", style: TextStyle(fontStyle: FontStyle.italic)),

          if (tops.isNotEmpty) ...[
            const Text('Hauts conseillés :', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 120, 
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: tops.length,
                itemBuilder: (context, index) => SizedBox(
                  width: 100,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClothingCard(item: tops[index], onTap: () {}),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          
          if (bottoms.isNotEmpty) ...[
            const Text('Bas conseillés :', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: bottoms.length,
                itemBuilder: (context, index) => SizedBox(
                  width: 100,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClothingCard(item: bottoms[index], onTap: () {}),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
                  Navigator.push(context, MaterialPageRoute(builder: (_) => OutfitCreatorScreen(user: widget.user)));
                  break;
                case 'view_outfits':
                  Navigator.push(context, MaterialPageRoute(builder: (_) => OutfitScreen(user: widget.user)));
                  break;
                case 'logout':
                  _confirmSignOut();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'create_outfit', child: Row(children: [Icon(Icons.add), SizedBox(width: 8), Text('Créer une tenue')])),
              const PopupMenuItem(value: 'view_outfits', child: Row(children: [Icon(Icons.style), SizedBox(width: 8), Text('Mes tenues')])),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout), SizedBox(width: 8), Text('Se déconnecter')])),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clothing_items')
            .where('userId', isEqualTo: widget.user.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          
          final allItems = docs.map((d) {
             return ClothingItem.fromJson(d.id, d.data()); 
          }).toList();

          final filteredItems = allItems.where((item) {
             final mainOk = _filterMainCategory == _allOption || item.mainCategory == _filterMainCategory;
             final subOk = _filterSubCategory == _allOption || item.subCategory == _filterSubCategory;
             final colorOk = _filterColor == _allOption || item.color == _filterColor;
             final occasionOk = _filterOccasion == _allOption || item.occasion == _filterOccasion;
             return mainOk && subOk && colorOk && occasionOk;
          }).toList();

          return Column(
            children: [
              _buildSuggestionCard(allItems), 

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                      DropdownButton<String>(
                        value: _filterMainCategory,
                        items: [DropdownMenuItem(value: _allOption, child: const Text('Tout')), ..._mainCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))],
                        onChanged: (val) => setState(() { _filterMainCategory = val ?? _allOption; if (_filterMainCategory == _allOption) { _subCategoryOptions = []; _filterSubCategory = _allOption; } else { _subCategoryOptions = _subCategoriesMap[_filterMainCategory] ?? []; _filterSubCategory = _allOption; } })
                      ),
                      const SizedBox(width: 10),
                      
                      DropdownButton<String>(
                        value: _filterSubCategory,
                        items: [DropdownMenuItem(value: _allOption, child: const Text('Tout')), ..._subCategoryOptions.map((sub) => DropdownMenuItem(value: sub, child: Text(sub)))],
                        onChanged: (_subCategoryOptions.isEmpty) ? null : (val) => setState(() => _filterSubCategory = val ?? _allOption),
                      ),
                      const SizedBox(width: 10),

                      DropdownButton<String>(
                        value: _filterColor,
                        items: [DropdownMenuItem(value: _allOption, child: const Text('Coul.')), ..._colorOptions.map((c) => DropdownMenuItem(value: c, child: Row(children: [Container(width: 15, height: 15, color: _colorMap[c]), const SizedBox(width: 5), Text(c)])))],
                        onChanged: (val) => setState(() => _filterColor = val ?? _allOption),
                      ),
                      const SizedBox(width: 10),

                      DropdownButton<String>(
                        value: _filterOccasion,
                        items: [DropdownMenuItem(value: _allOption, child: const Text('Occas.')), ..._occasionOptions.map((occ) => DropdownMenuItem(value: occ, child: Text(_occasionDisplayMap[occ] ?? occ)))],
                        onChanged: (val) => setState(() => _filterOccasion = val ?? _allOption),
                      ),
                      const SizedBox(width: 10),

                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => setState(() {
                          _filterMainCategory = _allOption;
                          _filterSubCategory = _allOption;
                          _filterColor = _allOption;
                          _filterOccasion = _allOption;
                          _subCategoryOptions = [];
                        })
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Expanded(
                child: filteredItems.isEmpty 
                    ? const Center(child: Text("Aucun vêtement trouvé"))
                    : GridView.builder(
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
                               Navigator.push(context, MaterialPageRoute(builder: (_) => EditClothingScreen(user: widget.user, clothingItem: filteredItems[index], onUpdate: (_) => setState((){}), onDelete: (_)=>setState((){}))));
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddClothingScreen(user: widget.user, onAdd: _addNewItem),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
