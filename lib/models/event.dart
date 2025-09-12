import 'package:reservator/models/ticket.dart';

class Event {
  final String id;
  final String title;
  final List<Ticket> tickets;
  
  Event({
    required this.id,
    required this.title,
    required this.tickets,
  });
  
  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    tickets: (json['tickets'] as List<dynamic>?)
        ?.map((ticketJson) => Ticket.fromJson(ticketJson))
        .toList() ?? [],
  );
}