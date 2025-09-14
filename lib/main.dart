import 'package:flutter/material.dart';
import 'package:reservator/repositories/events_repository.dart';
import 'package:reservator/services/graphql_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await GraphQLService.instance.init();
  await _testEventRepo();
  
  runApp(const MyApp());

}

Future<void> _testEventRepo() async {
  try {
    print('🔄 Test du repository...');
    
    final events = await EventsRepository.instance.getEvents();
    
    print('✅ Récupéré ${events.length} événements');
    
    for (final event in events) {
      print('📅 Event: ${event.title} (${event.tickets.length} tickets)');
      
      for (final ticket in event.tickets) {
        print('  🎫 ${ticket.fullName} - ${ticket.minimumPrice}€ - Open: ${ticket.open}');
      }
    }
    
  } catch (e) {
    print('❌ Erreur: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
