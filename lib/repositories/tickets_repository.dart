import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:reservator/services/graphql_service.dart';

class TicketsRepository {
  static final instance = TicketsRepository._();
  TicketsRepository._();
  
  final _graphql = GraphQLService.instance;

  Future<String> reserveTicket(String ticketId, String eventUrl) async
  {
    const query = """
      mutation BookTicket(\$bookingUrl: String!, \$ticket: LocalID!) {
        bookEvent(bookingUrl: \$bookingUrl, ticket: \$ticket) {
            ... on MutationBookEventSuccess {
                data {
                    authorName
                }
            }
            ... on Error {
                message 
            }
        }
      }
    """;

    final result = await _graphql.client.value.mutate(
      MutationOptions(
        document: gql(query),
        variables: {'bookingUrl':eventUrl,'ticket':ticketId}
      )
    );

    if (result.hasException) {
      throw Exception('GraphQL Error: ${result.exception.toString()}');
    }

    final data = result.data?['bookEvent'];
    if (data?['message'] != null) {
      return "${data["message"]}";
    } else if (data?['data'] != null) {
      return "success";
    }
    
    throw Exception('Unexpected response format');
  }
}