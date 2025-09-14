import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reservator/models/event.dart';
import 'package:reservator/models/reservation.dart';
import 'package:reservator/models/ticket.dart';
import 'package:reservator/repositories/events_repository.dart';
import 'package:reservator/repositories/tickets_repository.dart';
import 'package:reservator/services/graphql_service.dart';
import 'package:intl/intl.dart';
import 'package:reservator/services/reservation_service.dart';

void main() async {
  runApp(MyApp());

}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    EventsPage(),
    ReservationPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Événements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Réservations',
          ),
        ],
      ),
    );
  }
}

class EventsPage extends StatefulWidget {
  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<Event> events = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadEvents();
  }

  Future<void> _initializeAndLoadEvents() async {
    try {
      await GraphQLService.instance.init();
      
      final fetchedEvents = await EventsRepository.instance.getEvents();
      
      setState(() {
        events = fetchedEvents;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _refreshEvents() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    await _initializeAndLoadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Événements'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshEvents,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshEvents,
              child: Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun événement trouvé',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshEvents,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return EventCard(event: events[index]);
        },
      ),
    );
  }
}

class ReservationPage extends StatefulWidget {
  @override
  _ReservationPageState createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

  @override
  void initState() {
    super.initState();
    _initializeServices();
    ReservationService.instance.addListener(_onReservationChanged);
  }

  Future<void> _initializeServices() async {
    await ReservationService.instance.init();
  }

  @override
  void dispose() {
    ReservationService.instance.removeListener(_onReservationChanged);
    super.dispose();
  }

  void _onReservationChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _scheduleResa(Reservation res, BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final now = DateTime.now();
      final bookingTime = res.bookingTime;
      final refreshTokenTime = bookingTime.subtract(Duration(seconds: 2));

      if(bookingTime.isBefore(now))
      {
        await GraphQLService.instance.init();
        String result = await TicketsRepository.instance.reserveTicket(res.ticketId, res.bookingUrl);
        if(!mounted) return;
        if(result == "success")
        {
          messenger.showSnackBar(SnackBar(content: Text("Reservation réussie")));
        }
        else 
        {
          messenger.showSnackBar(SnackBar(content: Text("Erreur : $result")));
        }
        return;
      }

      if (refreshTokenTime.isAfter(now)) {
        final delayUntilTokenRefresh = refreshTokenTime.difference(now);
        Timer(delayUntilTokenRefresh, () async {
          try {
            await GraphQLService.instance.init();
            print("Tokens refreshed at ${DateTime.now()}");
          } catch (e) {
            print("Failed to refresh tokens: $e");
          }
        });
      } else {
        await GraphQLService.instance.init();
        print("Tokens refreshed immediately");
      }

      final delayUntilBooking = bookingTime.difference(now);

      Timer(delayUntilBooking, () async {
        if (!mounted) return;
        
        try {
          String result = await TicketsRepository.instance.reserveTicket(
            res.ticketId, 
            res.bookingUrl
          );
          
          if (!mounted) return;
          
          if (result == "success") {
            messenger.showSnackBar(SnackBar(
              content: Text("Réservation réussie")
            ));
          } else {
            messenger.showSnackBar(SnackBar(
              content: Text("Erreur : $result")
            ));
          }
        } catch (e) {
          if (!mounted) return;
          messenger.showSnackBar(SnackBar(
            content: Text("Erreur lors de la réservation : $e")
          ));
        }
      });

    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text("Erreur lors de la programmation : $e")
      ));
    }
      
  }

  @override
  Widget build(BuildContext context) {
    final reservations = ReservationService.instance.reservations;
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Réservations'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: reservations.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Aucune réservation', style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text('Réservez des événements depuis la page principale', style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final reservation = reservations[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.event, color: Colors.white),
                        ),
                        title: Text(reservation.eventTitle),
                        subtitle: Text("${reservation.ticketName} ouvre le ${dateFormat.format(reservation.bookingTime)}"),
                        trailing: IconButton(
                          icon: Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => ReservationService.instance.removeReservation(reservation),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _scheduleResa(reservation,context);
                          },
                          icon: Icon(Icons.schedule),
                          label: Text('Schedule'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 36),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.confirmation_number, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  '${event.tickets.length} ticket(s) disponible(s)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            
            if (event.tickets.isNotEmpty) ...[
              SizedBox(height: 12),
              ...event.tickets.map((ticket) => TicketTile(ticket: ticket, onReserve: () {_makeReservation(ticket,event.id,event.title);})),
            ],
          ],
        ),
      ),
    );
  }

  void _makeReservation(Ticket ticket, String eventId, String eventTitle)
  {
    final reservationService = ReservationService.instance;

    final String bookingUrl = "https://churros.inpt.fr/events/${eventId.substring(2)}";

    if(reservationService.isEventReserved(ticket.id, bookingUrl))
    {
      _showSnackBar("Vous avez déjà reservé cet événement");
      return;
    }

    if(ticket.opensAt == null)
    {
      _showSnackBar("Cet événement n'a pas de temps d'ouverture");
      return;
    }

    final resa = Reservation(
      ticketId: ticket.id,
      bookingUrl: bookingUrl,
      eventTitle: eventTitle,
      state: "created",
      ticketName: ticket.fullName,
      bookingTime: ticket.opensAt!.add(const Duration(milliseconds: 1))   
    );

    reservationService.addReservation(resa);
    _showSnackBar("Réservation confirmée pour ${ticket.fullName} du ${eventTitle}");
  }

  void _showSnackBar(String message) {
    final _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
    final ScaffoldMessengerState? _scaffold = _scaffoldKey.currentState;
    _scaffold?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class TicketTile extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback? onReserve; // Add callback parameter
  
  const TicketTile({
    Key? key, 
    required this.ticket,
    this.onReserve,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
   
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${ticket.fullName} (${ticket.isUnlimited ? 'Infini' : '${ticket.placesLeft}/${ticket.capacity}'})",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
         
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _buildStatusChip(
                ticket.open ? 'Ouvert' : 'Fermé',
                ticket.open ? Colors.green : Colors.red,
                ticket.open ? Icons.check_circle : Icons.cancel,
              ),
             
              if (ticket.minimumPrice != null)
                _buildInfoChip(
                  '${ticket.minimumPrice!.toStringAsFixed(2)} €',
                  Colors.blue,
                  Icons.euro,
                ),
             
              if (ticket.openToContributors)
                _buildStatusChip(
                  'Contributeurs',
                  Colors.purple,
                  Icons.people,
                ),
            ],
          ),
         
          if (ticket.opensAt != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  'Ouvre le ${dateFormat.format(ticket.opensAt!)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
          
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onReserve,
              icon: Icon(Icons.event_seat, size: 18),
              label: Text('Réserver une place'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[600],
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        label,
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildInfoChip(String label, Color color, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}