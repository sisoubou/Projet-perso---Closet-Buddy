import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';
import '../models/clothing_item.dart';

class StatisticsScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes statistiques', 
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.purple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<ClothingItem>>( 
        stream: _firestoreService.getClothingItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Ajoutez des vêtements pour voir les statistiques !', 
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          } 

          final items = snapshot.data!;
          
          // Préparation des données pour les graphiques
          final categoryData = _calculateCategoryStats(items);
          final colorData = _calculateColorStats(items);

          // Logique pour les pièces les plus portées (Top 5)
          final topItems = items.where((item) => item.wearCount > 0).toList();
          topItems.sort((a, b) => b.wearCount.compareTo(a.wearCount));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(items.length),
                const SizedBox(height: 30),
                
                const Text('Répartition par catégorie', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: _buildChartSections(categoryData, useRealColors: false),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                _buildLegend(categoryData, isColor: false),

                const SizedBox(height: 40),

                const Text('Couleurs dominantes', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    PieChartData(
                      sections: _buildChartSections(colorData, useRealColors: true),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                _buildLegend(colorData, isColor: true),

                const SizedBox(height: 40),

                const Text('Tes pièces les plus portées', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                if (topItems.isEmpty) 
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('Aucune pièce n\'a encore été portée. Utilise le calendrier pour voir tes favoris !', 
                      style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic)),
                  )
                else
                  ...topItems.take(5).map((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: item.imageUrl.isNotEmpty 
                          ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover)
                          : null,
                        color: Colors.grey[200],
                      ),
                      child: item.imageUrl.isEmpty ? const Icon(Icons.checkroom) : null,
                    ),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(item.subCategory),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${item.wearCount} fois', 
                        style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                    ),
                  )),
              ],
            ),
          );
        },
      ),
    );
  }

  // ... (Garder vos méthodes existantes : _calculateCategoryStats, _calculateColorStats, etc.)
  Map<String, int> _calculateCategoryStats(List<ClothingItem> items) {
    Map<String, int> stats = {};
    for (var item in items) {
      String cat = item.mainCategory.isEmpty ? "Inconnu" : item.mainCategory;
      stats[cat] = (stats[cat] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> _calculateColorStats(List<ClothingItem> items) {
    Map<String, int> stats = {};
    for (var item in items) {
      if (item.colors.isEmpty) {
        stats["Inconnu"] = (stats["Inconnu"] ?? 0) + 1;
      } else {
        for (var color in item.colors) {
          stats[color] = (stats[color] ?? 0) + 1;
        }
      }
    }
    return stats;
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'rouge': return Colors.red;
      case 'bleu': return Colors.blue;
      case 'vert': return Colors.green;
      case 'jaune': return Colors.yellow;
      case 'noir': return Colors.black;
      case 'blanc': return Colors.white;
      case 'gris': return Colors.grey;
      case 'rose': return Colors.pink;
      case 'violet': return Colors.purple;
      case 'orange': return Colors.orange;
      case 'marron': return Colors.brown;
      case 'beige': return const Color.fromARGB(255, 216, 163, 143);
      default: return Colors.blueGrey;
    }
  }

  Widget _buildSummaryCard(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text('Total de vêtements', style: TextStyle(fontSize: 18, color: Colors.purple)),
          Text('$total', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.purple)),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections(Map<String, int> data, {required bool useRealColors}) {
    final defaultColors = [
      Colors.purple, Colors.purpleAccent, Colors.deepPurple, Colors.indigo, Colors.purple[300]!,
    ];
    
    int index = 0;
    int totalItems = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a + b);

    return data.entries.map((entry) {
      final value = entry.value.toDouble();
      final percentage = (value / totalItems) * 100;
      
      final color = useRealColors ? _getColorFromString(entry.key) : defaultColors[index % defaultColors.length];

      index++;
      return PieChartSectionData(
        color: color,
        value: value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: TextStyle(
          fontSize: 14, 
          fontWeight: FontWeight.bold, 
          color: (useRealColors && entry.key.toLowerCase() == 'blanc') ? Colors.black : Colors.white
        ),
      );
    }).toList();
  }

  Widget _buildLegend(Map<String, int> data, {required bool isColor}) {
    final defaultColors = [Colors.purple, Colors.purpleAccent, Colors.deepPurple, Colors.indigo];
    int index = 0;

    return Wrap(
      spacing: 15,
      runSpacing: 10,
      children: data.keys.map((key) {
        Color iconColor = isColor ? _getColorFromString(key) : defaultColors[index % defaultColors.length];
        index++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14, height: 14, 
              decoration: BoxDecoration(
                color: iconColor, 
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300) 
              ),
            ),
            const SizedBox(width: 6),
            Text('$key (${data[key]})', style: const TextStyle(fontSize: 14)),
          ],
        );
      }).toList(),
    );
  }
}