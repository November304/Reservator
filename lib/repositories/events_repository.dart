import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:reservator/models/event.dart';

import '../services/graphql_service.dart';

class EventsRepository {
  static final instance = EventsRepository._();
  EventsRepository._();
  
  final _graphql = GraphQLService.instance;

  Future<List<Event>> getEvents() async {
    const query = """
      query {
        eventsByDay {
          nodes {
            happening {
              id
              title
              tickets {
                id
                fullName
                minimumPrice
                open
                opensAt
                openToContributors
                placesLeft
                capacity
              }
            }
          }
        }
      }""";
    final result = await _graphql.client.value.query(
      QueryOptions(document: gql(query))
    );
    if(result.hasException) throw Exception(result.exception);

    final response = EventsByDayResponse.fromJson(result.data!);
    return response.events;
  }
}

//Classe intermediaires pour recup les events depuis le json
class EventNode {
  final List<Event> happening;

  EventNode({required this.happening});

  factory EventNode.fromJson(Map<String, dynamic> json) => EventNode(
    happening: (json['happening'] as List<dynamic>)
        .map((eventJson) => Event.fromJson(eventJson))
        .toList(),
  );
}

class EventsByDayResponse {
  final List<EventNode> nodes;

  EventsByDayResponse({required this.nodes});

  factory EventsByDayResponse.fromJson(Map<String, dynamic> json) => EventsByDayResponse(
    nodes: (json['eventsByDay']['nodes'] as List<dynamic>)
        .map((nodeJson) => EventNode.fromJson(nodeJson))
        .toList(),
  );

  List<Event> get events => nodes
      .expand((node) => node.happening)
      .toList();
}