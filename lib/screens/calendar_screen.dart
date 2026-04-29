import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'outfit_creator_screen.dart';
import '../services/firestore_service.dart';
import '../models/calendar.dart';
import '../models/outfit.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import '../widgets/calendar_outfit.dart';

class CalendarScreen extends StatefulWidget {
  final User user;
  const CalendarScreen({super.key, required this.user});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

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
            Text('Planning',
                style: GoogleFonts.lato(
                    fontSize: 12, color: AppColors.textSecondary, letterSpacing: 0.5)),
            Text('Mon calendrier',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
      body: StreamBuilder<List<Calendar>>(
        stream: _firestoreService.getCalendarEntries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final calendarEntries = snapshot.data ?? [];

          Map<DateTime, List<Calendar>> events = {};
          for (var entry in calendarEntries) {
            final date = _normalizeDate(entry.date);
            if (events[date] == null) events[date] = [];
            events[date]!.add(entry);
          }

          return Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                padding: const EdgeInsets.all(12),
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
                child: TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  locale: 'fr_FR',
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: (day) {
                    return events[_normalizeDate(day)] ?? [];
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: GoogleFonts.lato(
                        color: AppColors.primary, fontWeight: FontWeight.w600),
                    selectedTextStyle: GoogleFonts.lato(
                        color: Colors.white, fontWeight: FontWeight.w600),
                    defaultTextStyle: GoogleFonts.lato(color: AppColors.textPrimary),
                    weekendTextStyle: GoogleFonts.lato(color: AppColors.textSecondary),
                    outsideTextStyle:
                        GoogleFonts.lato(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: GoogleFonts.lato(
                        color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
                    weekendStyle: GoogleFonts.lato(
                        color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.primary),
                    rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.primary),
                  ),
                ),
              ),
              Expanded(
                child: _buildEventList(events[_normalizeDate(_selectedDay ?? _focusedDay)] ?? []),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEventList(List<Calendar> dayEvents) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = _normalizeDate(_selectedDay ?? _focusedDay);

    if (dayEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                selected.isBefore(today)
                    ? "Pas de tenue ce jour-là"
                    : "Aucune tenue prévue",
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showAddOptions(context, selected),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Ajouter une tenue"),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final entry = dayEvents[index];
        return CalendarOutfit(
          outfitId: entry.outfitId,
          onDelete: () => _firestoreService.deleteCalendarEntry(entry.id),
        );
      },
    );
  }

  void _showAddOptions(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.history, color: AppColors.primary),
              title: Text("Choisir une tenue existante",
                  style: GoogleFonts.lato(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                _showExistingOutfitsPicker(context, date);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              title: Text("Créer une nouvelle tenue",
                  style: GoogleFonts.lato(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => OutfitCreatorScreen(user: widget.user)));
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showExistingOutfitsPicker(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text("Mes Tenues",
                style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('outfits')
                    .where('userId', isEqualTo: widget.user.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary));
                  }
                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return Center(
                      child: Text("Aucune tenue enregistrée",
                          style: GoogleFonts.lato(color: AppColors.textSecondary)),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final outfit = Outfit.fromJson(docs[i].data() as Map<String, dynamic>);
                      return ListTile(
                        leading: const Icon(Icons.style_outlined, color: AppColors.primary),
                        title: Text(outfit.name,
                            style: GoogleFonts.lato(fontWeight: FontWeight.w500)),
                        subtitle: Text("${outfit.items.length} articles",
                            style: GoogleFonts.lato(color: AppColors.textSecondary)),
                        onTap: () {
                          _addOutfitToCalendar(outfit, date, ctx);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addOutfitToCalendar(Outfit outfit, DateTime date, BuildContext ctx) async {
    final normalizedDate = _normalizeDate(date);
    final newEntry = Calendar(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: widget.user.id,
      date: normalizedDate,
      outfitId: outfit.id,
    );

    await FirebaseFirestore.instance
        .collection('calendar')
        .doc(newEntry.id)
        .set(newEntry.toJson());

    final List<String> itemIds = outfit.items.map((item) => item.id).toList();
    await _firestoreService.incrementWearCount(itemIds);

    if (!mounted) return;
    Navigator.pop(ctx);
    if (!mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text("Tenue ajoutée au calendrier !")),
    );
  }
}
