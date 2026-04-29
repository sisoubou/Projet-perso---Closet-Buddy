import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../models/clothing_item.dart';
import '../theme/app_theme.dart';
import '../widgets/network_img.dart';

class StatisticsScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  StatisticsScreen({super.key});

  static const _chartPalette = [
    AppColors.primary,
    AppColors.primarySoft,
    AppColors.accent,
    Color(0xFFB89070),
    Color(0xFFD8B894),
    Color(0xFF6B5440),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Aperçu',
                style: GoogleFonts.lato(
                    fontSize: 12, color: AppColors.textSecondary, letterSpacing: 0.5)),
            Text('Mes statistiques',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
      body: StreamBuilder<List<ClothingItem>>(
        stream: _firestoreService.getClothingItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.insights_outlined,
                        size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text('Ajoutez des vêtements pour voir vos statistiques',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          }

          final items = snapshot.data!;
          final categoryData = _calculateCategoryStats(items);
          final colorData = _calculateColorStats(items);

          final topItems = items.where((item) => item.wearCount > 0).toList();
          topItems.sort((a, b) => b.wearCount.compareTo(a.wearCount));

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(items.length),
                const SizedBox(height: 28),
                _sectionTitle('Répartition par catégorie'),
                const SizedBox(height: 16),
                _buildChartCard(categoryData, useRealColors: false),
                const SizedBox(height: 28),
                _sectionTitle('Couleurs dominantes'),
                const SizedBox(height: 16),
                _buildChartCard(colorData, useRealColors: true),
                const SizedBox(height: 28),
                _sectionTitle('Pièces les plus portées'),
                const SizedBox(height: 12),
                if (topItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      "Aucune pièce n'a encore été portée. Utilisez le calendrier pour voir vos favoris.",
                      style: GoogleFonts.lato(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ...topItems.take(5).map((item) => _buildTopItem(item)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.playfairDisplay(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    );
  }

  Widget _buildSummaryCard(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total de vêtements',
              style: GoogleFonts.lato(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.85),
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$total',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 48, fontWeight: FontWeight.w600, color: Colors.white, height: 1)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('pièces',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.85))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(Map<String, int> data, {required bool useRealColors}) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _buildChartSections(data, useRealColors: useRealColors),
                centerSpaceRadius: 50,
                sectionsSpace: 3,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(data, isColor: useRealColors),
        ],
      ),
    );
  }

  Widget _buildTopItem(ClothingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 52,
              height: 52,
              child: NetworkImg(
                item.imageUrl,
                placeholder: const Icon(Icons.checkroom_outlined,
                    color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(item.subCategory,
                    style: GoogleFonts.lato(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${item.wearCount}× porté',
                style: GoogleFonts.lato(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
        ],
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
      case 'rouge':
        return Colors.red;
      case 'bleu':
        return Colors.blue;
      case 'vert':
        return Colors.green;
      case 'jaune':
        return Colors.yellow;
      case 'noir':
        return Colors.black;
      case 'blanc':
        return Colors.white;
      case 'gris':
        return Colors.grey;
      case 'rose':
        return Colors.pink;
      case 'violet':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'marron':
        return Colors.brown;
      case 'beige':
        return const Color.fromARGB(255, 216, 163, 143);
      default:
        return AppColors.primarySoft;
    }
  }

  List<PieChartSectionData> _buildChartSections(Map<String, int> data, {required bool useRealColors}) {
    int index = 0;
    int totalItems = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a + b);

    return data.entries.map((entry) {
      final value = entry.value.toDouble();
      final percentage = (value / totalItems) * 100;

      final color = useRealColors
          ? _getColorFromString(entry.key)
          : _chartPalette[index % _chartPalette.length];

      index++;
      return PieChartSectionData(
        color: color,
        value: value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: GoogleFonts.lato(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: (useRealColors && entry.key.toLowerCase() == 'blanc')
              ? AppColors.textPrimary
              : Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(Map<String, int> data, {required bool isColor}) {
    int index = 0;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: data.keys.map((key) {
        Color iconColor = isColor
            ? _getColorFromString(key)
            : _chartPalette[index % _chartPalette.length];
        index++;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
              ),
            ),
            const SizedBox(width: 6),
            Text('$key (${data[key]})',
                style: GoogleFonts.lato(
                    fontSize: 12, color: AppColors.textPrimary)),
          ],
        );
      }).toList(),
    );
  }
}
