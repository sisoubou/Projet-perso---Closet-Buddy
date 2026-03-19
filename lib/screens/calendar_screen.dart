import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'outfit_creator_screen.dart';
import '../services/firestore_service.dart';
import '../models/calendar.dart';
import '../models/outfit.dart';
import '../models/user.dart';
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
        title: const Text('Mon calendrier',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.purple,
        elevation: 0,
      ),
      body: StreamBuilder<List<Calendar>>(
        stream: _firestoreService.getCalendarEntries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
              TableCalendar(
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
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(color: Colors.purpleAccent, shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
                  markerDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const Divider(),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                selected.isBefore(today)
                    ? "Vous n'avez pas rentré de tenue à cette date."
                    : "Vous n'avez pas prévu de tenue à cette date.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showAddOptions(context, selected),
              icon: const Icon(Icons.add),
              label: const Text("Ajouter une tenue"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.history, color: Colors.purple),
            title: const Text("Choisir une tenue existante"),
            onTap: () {
              Navigator.pop(ctx);
              _showExistingOutfitsPicker(context, date);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline, color: Colors.purple),
            title: const Text("Créer une nouvelle tenue"),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => OutfitCreatorScreen(user: widget.user)));
            },
          ),
        ],
      ),
    );
  }

  void _showExistingOutfitsPicker(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            const Text("Mes Tenues", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('outfits')
                    .where('userId', isEqualTo: widget.user.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) return const Center(child: Text("Aucune tenue enregistrée"));

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final outfit = Outfit.fromJson(docs[i].data() as Map<String, dynamic>);
                      return ListTile(
                        leading: const Icon(Icons.style, color: Colors.purple),
                        title: Text(outfit.name),
                        subtitle: Text("${outfit.items.length} articles"),
                        onTap: () async {
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

                          if (!mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Tenue ajoutée au calendrier !")),
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
      ),
    );
  }
}