import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_service.dart';
import '../models/clothing_item.dart';

class StatisticsScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

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
          final categoryData = _calculateCategoryStats(items);

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
                      sections: _buildChartSections(categoryData),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLegend(categoryData),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<String, int> _calculateCategoryStats(List<ClothingItem> items) {
    Map<String, int> stats = {};
    for (var item in items) {
      String cat = item.mainCategory.isEmpty ? "Inconnu" : item.mainCategory;
      stats[cat] = (stats[cat] ?? 0) + 1;
    }
    return stats;
  }

  Widget _buildSummaryCard(int total){
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        children:[
          const Text('Total de vêtements', style: TextStyle(fontSize: 18, color: Colors.purple)),
          Text('$total', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.purple)),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildChartSections(Map<String, int> data) {
    final colors = [
      Colors.purple, 
      Colors.purpleAccent, 
      Colors.deepPurple, 
      Colors.deepPurpleAccent,
      Colors.indigo,
      Colors.purple[300],
    ];
    
    int index = 0;
    int totalItems = data.values.reduce((a, b) => a + b);

    return data.entries.map((entry) {
      final value = entry.value.toDouble();
      final percentage = (value / totalItems) * 100;
      
      final section = PieChartSectionData(
        color: colors[index % colors.length],
        value: value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      );
      index++;
      return section;
    }).toList();
  }

  Widget _buildLegend(Map<String, int> data) {
    final colors = [Colors.purple, Colors.purpleAccent, Colors.deepPurple, Colors.deepPurpleAccent, Colors.indigo];
    int index = 0;

    return Wrap(
      spacing: 15,
      runSpacing: 10,
      children: data.keys.map((cat) {
        Color iconColor = colors[index % colors.length];
        index++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14, 
              height: 14, 
              decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('$cat (${data[cat]})', style: const TextStyle(fontSize: 14)),
          ],
        );
      }).toList(),
    );
  }
}