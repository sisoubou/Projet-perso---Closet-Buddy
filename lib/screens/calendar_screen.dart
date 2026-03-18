import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/firestore_service.dart';
import '../models/calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

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
    if (dayEvents.isEmpty) {
      return const Center(child: Text("Pas de tenue prévue pour ce jour."));
    }
    return ListView.builder(
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final entry = dayEvents[index];
        return ListTile(
          leading: const Icon(Icons.style, color: Colors.purple),
          title: const Text("Tenue planifiée"),
          subtitle: Text("ID Tenue: ${entry.outfitId}"),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _firestoreService.deleteCalendarEntry(entry.id),
          ),
        );
      },
    );
  }
}