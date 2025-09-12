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
              }
            }
          }
        }
      }""";
    final result = await _graphql.client.value.query(
      QueryOptions(document: gql(query))
    );
    print(result);
    return [];
  }
}